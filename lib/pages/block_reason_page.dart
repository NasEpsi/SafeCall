import 'package:flutter/material.dart';

// Page for selecting block reason
class BlockReasonPage extends StatefulWidget {
  final String number;
  final Function(String) onReasonSelected;

  const BlockReasonPage({
    super.key,
    required this.number,
    required this.onReasonSelected,
  });

  @override
  State<BlockReasonPage> createState() => _BlockReasonPageState();
}

class _BlockReasonPageState extends State<BlockReasonPage> {
  String? selectedReason;
  final TextEditingController _customReasonController = TextEditingController();

  final List<String> predefinedReasons = [
    'Spam',
    'Arnaque',
    'Phishing',
    'Marketing',
    'Harcèlement',
    'Autre',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Raison du blocage',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Numéro à bloquer:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.number,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Pourquoi voulez-vous bloquer ce numéro ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: predefinedReasons.length,
                itemBuilder: (context, index) {
                  final reason = predefinedReasons[index];
                  final isSelected = selectedReason == reason;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        reason,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? const Color(0xFF2196F3) : Colors.black,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF2196F3),
                      )
                          : null,
                      onTap: () {
                        setState(() {
                          selectedReason = reason;
                        });

                        if (reason == 'Autre') {
                          _showCustomReasonDialog();
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedReason != null ? _confirmBlock : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Confirmer le blocage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomReasonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Raison personnalisée'),
          content: TextField(
            controller: _customReasonController,
            decoration: const InputDecoration(
              hintText: 'Entrez la raison...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  selectedReason = null;
                });
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final customReason = _customReasonController.text.trim();
                if (customReason.isNotEmpty) {
                  Navigator.of(context).pop();
                  setState(() {
                    selectedReason = customReason;
                  });
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  void _confirmBlock() {
    if (selectedReason != null) {
      widget.onReasonSelected(selectedReason!);
      Navigator.of(context).pop(); // Return to previous page
    }
  }
}