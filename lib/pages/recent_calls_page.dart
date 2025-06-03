import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../components/my_gradient_silver_app_bar.dart';
import '../components/my_search_bar.dart';
import '../components/my_segmented_controll.dart';
import '../services/database/database_provider.dart';


class RecentCallsPage extends StatefulWidget {
  const RecentCallsPage({super.key});

  @override
  State<RecentCallsPage> createState() => _RecentCallsPageState();
}

class _RecentCallsPageState extends State<RecentCallsPage> {
  // Fix: Use the correct channel name that matches MainActivity.kt
  static const platform = MethodChannel('com.example.safecall/call_logs');
  static const permissionChannel = MethodChannel('com.example.safecall/permissions');

  List<Map<String, dynamic>> _callLogs = [];
  List<Map<String, dynamic>> _filteredCallLogs = [];
  bool _isLoading = true;
  int _selectedSegmentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String? _errorMessage;

  final List<String> _filterSegments = ['Tous', 'Manqués'];

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) => _loadCallLogs());
    _searchController.addListener(_filterCalls);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final hasPermissions = await permissionChannel.invokeMethod('checkPermissions');
      print('Permissions accordées: $hasPermissions');

      if (!hasPermissions) {
        print('Demande des permissions...');
        final granted = await permissionChannel.invokeMethod('requestPermissions');

        if (!granted) {
          setState(() {
            _errorMessage = 'Permissions nécessaires pour afficher les appels';
          });
          _showError('Veuillez accorder les permissions dans les paramètres');
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification des permissions: $e');
      setState(() {
        _errorMessage = 'Erreur de permissions: $e';
      });
    }
  }

  Future<void> _loadCallLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Tentative de chargement des appels récents...');

      final result = await platform.invokeMethod('getRecentCalls', {'limit': 100});

      print('Résultat reçu: $result');
      print('Type du résultat: ${result.runtimeType}');

      if (result != null) {
        List<Map<String, dynamic>> calls = [];

        if (result is List) {
          for (var item in result) {
            if (item is Map) {
              Map<String, dynamic> callData = {};
              item.forEach((key, value) {
                callData[key.toString()] = value;
              });
              calls.add(callData);
            }
          }
        }

        print('Nombre d\'appels traités: ${calls.length}');

        setState(() {
          _callLogs = calls;
          _filterCalls();
        });
      } else {
        print('Aucun résultat reçu');
        setState(() {
          _callLogs = [];
          _filteredCallLogs = [];
          _errorMessage = 'Aucun appel trouvé';
        });
      }
    } catch (e) {
      print('Erreur lors du chargement: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement des appels: $e';
      });
      _showError('Erreur lors du chargement des appels: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCalls() {
    setState(() {
      _filteredCallLogs = _callLogs.where((call) {
        // Filtre par type d'appel selon le segment sélectionné
        bool matchesFilter = true;
        if (_selectedSegmentIndex == 1) { // Manqués
          final callType = _getIntValue(call['type']);
          matchesFilter = callType == 3; // MISSED_TYPE
        }

        // Filtre par recherche
        bool matchesSearch = true;
        if (_searchController.text.isNotEmpty) {
          final searchTerm = _searchController.text.toLowerCase();
          final number = _getStringValue(call['number']).toLowerCase();
          final name = _getStringValue(call['name']).toLowerCase();
          matchesSearch = number.contains(searchTerm) || name.contains(searchTerm);
        }

        return matchesFilter && matchesSearch;
      }).toList();
    });

    print('Appels filtrés: ${_filteredCallLogs.length}');
  }

  // Méthodes utilitaires pour la conversion sécurisée des types
  String _getStringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  int _getIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int _getLongValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _deleteCallLog(int index) async {
    final callLog = _filteredCallLogs[index];
    final callId = _getLongValue(callLog['id']);

    try {
      final success = await platform.invokeMethod('deleteCallLogEntry', {'callId': callId});
      if (success == true) {
        await _loadCallLogs();
        _showSuccess('Appel supprimé');
      } else {
        _showError('Impossible de supprimer l\'appel');
      }
    } catch (e) {
      _showError('Erreur lors de la suppression: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkAndRequestCallLogPermissions() async {
    try {
      final hasBasicPermissions = await permissionChannel.invokeMethod('checkPermissions');

      if (!hasBasicPermissions) {
        final granted = await permissionChannel.invokeMethod('requestPermissions');
        if (!granted) {
          _showError('Permissions de base requises');
          return;
        }
      }

      await _loadCallLogs();
    } catch (e) {
      print('Erreur permissions CallLog: $e');
      _showError('Erreur d\'accès aux logs d\'appels: $e');
    }
  }

  String _getCallTypeIcon(int callType) {
    switch (callType) {
      case 1: // INCOMING_TYPE
        return '📞';
      case 2: // OUTGOING_TYPE
        return '📱';
      case 3: // MISSED_TYPE
        return '📵';
      default:
        return '📞';
    }
  }

  Color _getCallTypeColor(int callType) {
    switch (callType) {
      case 1: // INCOMING_TYPE
        return Colors.blue;
      case 2: // OUTGOING_TYPE
        return Colors.green;
      case 3: // MISSED_TYPE
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCallTypeText(int callType) {
    switch (callType) {
      case 1: // INCOMING_TYPE
        return 'Entrant';
      case 2: // OUTGOING_TYPE
        return 'Sortant';
      case 3: // MISSED_TYPE
        return 'Manqué';
      default:
        return 'Inconnu';
    }
  }

  String _formatDuration(int durationSeconds) {
    if (durationSeconds == 0) return '';

    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;

    if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'Date inconnue';

    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} min';
      } else if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return weekdays[date.weekday - 1];
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      print('Erreur de formatage de date: $e');
      return 'Date invalide';
    }
  }

  String? _getSpamReason(String phoneNumber) {
    try {
      final provider = Provider.of<DatabaseProvider>(context, listen: false);
      final blockedItems = provider.getBlockedItemsWithReasons();

      for (final item in blockedItems) {
        if (item['value'] == phoneNumber || phoneNumber.contains(item['value'])) {
          return item['reason'];
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification spam: $e');
    }
    return null;
  }

  Widget _buildCallLogItem(Map<String, dynamic> call) {
    final callType = _getIntValue(call['type']);
    final number = _getStringValue(call['number']);
    final name = _getStringValue(call['name']);
    final date = _formatDate(_getLongValue(call['date']));
    final duration = _formatDuration(_getIntValue(call['duration']));
    final spamReason = _getSpamReason(number);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getCallTypeColor(callType),
          child: Text(
            _getCallTypeIcon(callType),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          name.isNotEmpty ? name : number,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _getCallTypeText(callType),
                  style: TextStyle(
                    color: _getCallTypeColor(callType),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(' • '),
                Text(date),
              ],
            ),
            if (duration.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Durée: $duration',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (spamReason != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '⚠️ $spamReason',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Supprimer l\'appel'),
                content: const Text('Voulez-vous vraiment supprimer cet appel ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              _deleteCallLog(_filteredCallLogs.indexOf(call));
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_disabled,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedSegmentIndex == 1 ? 'Aucun appel manqué' : 'Aucun appel récent',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _loadCallLogs,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _checkAndRequestCallLogPermissions,
                icon: const Icon(Icons.security),
                label: const Text('Vérifier permissions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          const MyGradientSliverAppBar(title: 'Appels Récents'),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                MySegmentedControl(
                  segments: _filterSegments,
                  selectedIndex: _selectedSegmentIndex,
                  onSegmentChanged: (index) {
                    setState(() {
                      _selectedSegmentIndex = index;
                      _filterCalls();
                    });
                  },
                ),
                const SizedBox(height: 16),
                MySearchBar(controller: _searchController),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SliverFillRemaining(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _filteredCallLogs.isEmpty
                ? _buildEmptyState()
                : _filteredCallLogs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _filteredCallLogs.length,
              itemBuilder: (context, index) {
                final call = _filteredCallLogs[index];
                return _buildCallLogItem(call);
              },
            ),
          ),
        ],
      ),
    );
  }
}