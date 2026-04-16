import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/step_progress.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);

/// Step 5: Delivery details + Payment info
class WizardReviewScreen extends ConsumerStatefulWidget {
  const WizardReviewScreen({super.key});

  @override
  ConsumerState<WizardReviewScreen> createState() => _WizardReviewScreenState();
}

class _WizardReviewScreenState extends ConsumerState<WizardReviewScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).trackWizardStepEntered(5, 'delivery');
    final wizard = ref.read(wizardProvider);
    _addressController.text = wizard.deliveryAddress;
    _phoneController.text = wizard.contactPhone;
    _instructionsController.text = wizard.specialInstructions;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _goToConfirm() {
    if (_addressController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: _surfaceDark,
        content: Text('Please fill in delivery address and phone', style: TextStyle(color: Color(0xFFEF4444))),
      ));
      return;
    }

    final wizard = ref.read(wizardProvider);
    if (wizard.eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: _surfaceDark,
        content: Text('Please select an event date in Step 1', style: TextStyle(color: Color(0xFFEF4444))),
      ));
      return;
    }

    final notifier = ref.read(wizardProvider.notifier);
    notifier.setDeliveryAddress(_addressController.text.trim());
    notifier.setContactPhone(_phoneController.text.trim());
    notifier.setSpecialInstructions(_instructionsController.text.trim());

    ref.read(analyticsProvider).trackWizardStepCompleted(5, 'delivery');
    context.push('/wizard/confirm');
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardProvider);

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 5),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: RichText(text: const TextSpan(
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textLight, height: 1.15, fontFamily: 'Inter'),
                        children: [
                          TextSpan(text: 'Delivery &\n'),
                          TextSpan(text: 'payment', style: TextStyle(fontStyle: FontStyle.italic, color: _gold)),
                        ],
                      )),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: Text('Where should we deliver your order?', style: TextStyle(color: _muted, fontSize: 13)),
                    ),

                    // Event banner
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.05),
                        border: Border.all(color: _gold.withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.celebration, size: 18, color: _gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: _mutedLight, fontFamily: 'Inter'),
                              children: [
                                TextSpan(text: '${wizard.totalPax}', style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
                                TextSpan(text: ' guests • ${wizard.eventType.replaceAll('_', ' ')}'),
                                if (wizard.eventDate != null) TextSpan(text: ' • ${wizard.eventDate!.day}/${wizard.eventDate!.month}/${wizard.eventDate!.year}'),
                              ],
                            )),
                          ),
                          Text('NPR ${wizard.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _gold)),
                        ],
                      ),
                    ),

                    // === DELIVERY DETAILS ===
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.local_shipping_outlined, size: 16, color: _gold),
                            SizedBox(width: 8),
                            Text('Delivery Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textLight)),
                          ]),
                          const SizedBox(height: 12),
                          _DarkInput(controller: _addressController, label: 'Delivery Address', maxLines: 2),
                          const SizedBox(height: 8),
                          _DarkInput(controller: _phoneController, label: 'Contact Phone', keyboardType: TextInputType.phone),
                          const SizedBox(height: 8),
                          _DarkInput(controller: _instructionsController, label: 'Special instructions (optional)', maxLines: 2),
                        ],
                      ),
                    ),

                    // === PAYMENT PLACEHOLDER ===
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surfaceDark,
                        border: Border.all(color: _gold.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.payment, size: 28, color: _gold),
                          SizedBox(height: 8),
                          Text('Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textLight)),
                          SizedBox(height: 4),
                          Text(
                            'Payment integration coming soon.\nWe will confirm your order via call.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _darkBg, boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: 0.3))]),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(border: Border.all(color: _gold, width: 1.5), borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('Back', style: TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _goToConfirm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_gold, _goldLight]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: const Center(child: Text('Review Order', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  const _DarkInput({required this.controller, required this.label, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textLight, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        filled: true,
        fillColor: _darkBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gold, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
