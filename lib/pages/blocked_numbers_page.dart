import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safecall/components/my_add_blocked_number.dart';
import 'package:safecall/components/my_add_blocked_prefix.dart';
import 'package:safecall/pages/block_reason_page.dart';
import '../components/my_gradient_silver_app_bar.dart';
import '../components/my_number_card.dart';
import '../components/my_prefix_card.dart';
import '../components/my_segmented_controll.dart';
import '../helper/numbers_format.dart';
import '../services/database/database_provider.dart';

class BlockedNumbersPage extends StatefulWidget {
  const BlockedNumbersPage({super.key});

  @override
  State<BlockedNumbersPage> createState() => _BlockedNumbersPageState();
}

class _BlockedNumbersPageState extends State<BlockedNumbersPage>
    with TickerProviderStateMixin {
  int selectedSegment = 0;
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // display blocked user data at the start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlockedData();
    });
  }

  // Loading the user blocked data
  void _loadBlockedData() {
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    dbProvider.loadBlockedNumbers();
    dbProvider.loadBlockedPrefixes();
    dbProvider.loadUserReports();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _prefixController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          const MyGradientSliverAppBar(
            title: 'Numéros Bloqués',
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                MySegmentedControl(
                  segments: const ['Mes Bloqués', 'Ajouter'],
                  selectedIndex: selectedSegment,
                  onSegmentChanged: (index) {
                    setState(() {
                      selectedSegment = index;
                    });
                  },
                ),
                const SizedBox(height: 20),
                selectedSegment == 0
                    ? _buildBlockedNumbersList()
                    : _buildAddNumberSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedNumbersList() {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        if (dbProvider.isLoading) {
          return SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF002C73), Color(0xFFFF06EA)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chargement...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final blockedItems = dbProvider.getBlockedItemsWithReasons();
        final blockedPrefixes = dbProvider.blockedPrefixes;

        if (blockedItems.isEmpty && blockedPrefixes.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            if (blockedItems.isNotEmpty) _buildNumbersSection(blockedItems),
            if (blockedPrefixes.isNotEmpty)
              _buildPrefixesSection(blockedPrefixes),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF002C73).withOpacity(0.1),
                    const Color(0xFFFF06EA).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 60,
                color: Color(0xFF667EEA),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun numéro bloqué',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Commencez par ajouter des numéros\nou préfixes à bloquer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => setState(() => selectedSegment = 1),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Ajouter maintenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumbersSection(List<Map<String, dynamic>> blockedItems) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF002C73), Color(0xFFFF06EA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_disabled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Numéros Bloqués (${blockedItems.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: blockedItems.length,
            itemBuilder: (context, index) => MyNumberCard(
              item: blockedItems[index],
              onDelete: () => _showDeleteConfirmation(blockedItems[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefixesSection(List<Map<String, dynamic>> blockedPrefixes) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Préfixes Bloqués (${blockedPrefixes.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: blockedPrefixes.length,
            itemBuilder: (context, index) => MyPrefixCard(
              prefix: blockedPrefixes[index],
              onDelete: () =>
                  _showDeletePrefixConfirmation(blockedPrefixes[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNumberSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          MyAddBlockedNumber(
            controller: _numberController,
            onPressed: _blockNumber,
          ),
          const SizedBox(height: 24),
          MyAddBlockedPrefix(
            controller: _prefixController,
            onPressed: _blockPrefix,
          ),
        ],
      ),
    );
  }


  void _blockNumber() {
    final raw = _numberController.text.trim();

    final number = _numberController.text.trim();

    // Verify if number is empty
    if (number.isEmpty) {
      _showSnackBar('Veuillez entrer un numéro', isError: true);
      return;
    }

    // Verify id the number is a french number
    if (!isValidFrenchMobile(number)) {
      _showSnackBar('Format de numéro invalide. Veuillez entrer un numéro mobile français valide (ex: 06 12 34 56 78)', isError: true);
      return;
    }

    final normalizedNumber = normalizeToInternationalFormat(number);


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlockReasonPage(
          number: number,
          onReasonSelected: (reason) {
            _addBlockedNumber(normalizedNumber, reason);
          },
        ),
      ),
    );
  }

  void _blockPrefix() async {
    final prefix = _prefixController.text.trim();
    if (prefix.isEmpty) {
      _showSnackBar('Veuillez entrer un préfixe', isError: true);
      return;
    }

    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final success = await dbProvider.addBlockedPrefix(prefix);

    if (success) {
      _prefixController.clear();
      _showSnackBar('Préfixe bloqué avec succès');
      setState(() => selectedSegment = 0);
    } else {
      _showSnackBar('Erreur lors du blocage du préfixe', isError: true);
    }
  }

  void _addBlockedNumber(String number, String reason) async {
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final success = await dbProvider.addBlockedNumber(number, reason);

    if (success) {
      _numberController.clear();
      _showSnackBar('Numéro bloqué avec succès');
      setState(() => selectedSegment = 0);
    } else {
      _showSnackBar('Erreur lors du blocage du numéro', isError: true);
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Confirmer la suppression',
            style: TextStyle(color: Color(0xFF2C3E50)),
          ),
          content: Text(
            'Voulez-vous vraiment débloquer ${item['value']} ?',
            style: const TextStyle(color: Color(0xFF2C3E50)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Color(0xFF7F8C8D)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBlockedItem(item);
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Color(0xFFE74C3C)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePrefixConfirmation(Map<String, dynamic> prefix) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirmer la suppression',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Voulez-vous vraiment débloquer le préfixe ${prefix['prefix']} ?',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBlockedPrefix(prefix);
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteBlockedItem(Map<String, dynamic> item) async {
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final success = await dbProvider.removeBlockedNumber(item['id']);

    if (success) {
      _showSnackBar('Numéro débloqué');
    } else {
      _showSnackBar('Erreur lors de la suppression', isError: true);
    }
  }

  void _deleteBlockedPrefix(Map<String, dynamic> prefix) async {
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final success = await dbProvider.removeBlockedPrefix(prefix['id']);

    if (success) {
      _showSnackBar('Préfixe débloqué');
    } else {
      _showSnackBar('Erreur lors de la suppression', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
