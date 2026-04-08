import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/step_progress.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _border = Color(0xFF44403C);

class WizardEventScreen extends ConsumerWidget {
  const WizardEventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);

    final eventTypes = [
      ('wedding', 'Wedding', Icons.favorite),
      ('birthday', 'Birthday', Icons.cake),
      ('corporate', 'Corporate', Icons.business),
      ('house_party', 'House Party', Icons.home),
      ('anniversary', 'Anniversary', Icons.celebration),
      ('other', 'Other', Icons.event),
    ];

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Back to home
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back, color: _muted, size: 22),
                ),
              ),
            ),
            const StepProgress(currentStep: 1),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === HERO MINI ===
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_surfaceDark, _darkBg],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(text: const TextSpan(
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _textLight, height: 1.15, fontFamily: 'Inter'),
                            children: [
                              TextSpan(text: 'How many guests\nare '),
                              TextSpan(text: 'celebrating?', style: TextStyle(fontStyle: FontStyle.italic, color: _gold)),
                            ],
                          )),
                          const SizedBox(height: 6),
                          const Text("We'll calculate the perfect amount for your event", style: TextStyle(color: _muted, fontSize: 13)),
                        ],
                      ),
                    ),

                    // === BIG GUEST STEPPER ===
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          const Text('TOTAL GUESTS', style: TextStyle(fontSize: 11, color: _muted, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _CircleButton(
                                icon: Icons.remove,
                                onTap: wizard.totalPax > 10 ? () => ref.read(wizardProvider.notifier).setTotalPax(wizard.totalPax - 10) : null,
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () => _showNumberDialog(context, 'Total Guests', wizard.totalPax, 10, 2000, (v) => ref.read(wizardProvider.notifier).setTotalPax(v)),
                                child: Column(
                                  children: [
                                    Text(
                                      '${wizard.totalPax}',
                                      style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: _gold, height: 1),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      width: 80, height: 2,
                                      decoration: BoxDecoration(
                                        color: _gold.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              _CircleButton(
                                icon: Icons.add,
                                onTap: wizard.totalPax < 2000 ? () => ref.read(wizardProvider.notifier).setTotalPax(wizard.totalPax + 10) : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('Tap number to type directly', style: TextStyle(fontSize: 11, color: _muted)),
                        ],
                      ),
                    ),

                    // === DIVIDER ===
                    Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 24), color: _border),

                    // === CHILDREN MINI STEPPER ===
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: _gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.child_care, color: _gold, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Children', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight)),
                                Text('Included in total guests', style: TextStyle(fontSize: 11, color: _muted)),
                              ],
                            ),
                          ),
                          _MiniStepper(
                            value: wizard.childrenCount,
                            min: 0,
                            max: wizard.totalPax,
                            onChanged: (v) => ref.read(wizardProvider.notifier).setChildrenCount(v),
                            onTap: () => _showNumberDialog(context, 'Children', wizard.childrenCount, 0, wizard.totalPax, (v) => ref.read(wizardProvider.notifier).setChildrenCount(v)),
                          ),
                        ],
                      ),
                    ),

                    // === LADIES MINI STEPPER ===
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.woman, color: Color(0xFFEC4899), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ladies', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight)),
                                Text('Included in total guests', style: TextStyle(fontSize: 11, color: _muted)),
                              ],
                            ),
                          ),
                          _MiniStepper(
                            value: wizard.ladiesCount,
                            min: 0,
                            max: wizard.totalPax - wizard.childrenCount,
                            onChanged: (v) => ref.read(wizardProvider.notifier).setLadiesCount(v),
                            onTap: () => _showNumberDialog(context, 'Ladies', wizard.ladiesCount, 0, wizard.totalPax - wizard.childrenCount, (v) => ref.read(wizardProvider.notifier).setLadiesCount(v)),
                          ),
                        ],
                      ),
                    ),

                    Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 24), color: _border),

                    // === EVENT TYPE DROPDOWN ===
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: const Text("What's the occasion?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight)),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _surfaceDark,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: wizard.eventType,
                            isExpanded: true,
                            dropdownColor: _surfaceDark,
                            icon: const Icon(Icons.keyboard_arrow_down, color: _gold),
                            style: const TextStyle(fontSize: 14, color: _textLight, fontFamily: 'Inter'),
                            items: eventTypes.map((e) {
                              return DropdownMenuItem<String>(
                                value: e.$1,
                                child: Row(
                                  children: [
                                    Icon(e.$3, size: 20, color: _gold),
                                    const SizedBox(width: 12),
                                    Text(e.$2),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) ref.read(wizardProvider.notifier).setEventType(value);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // === DATE PICKER ===
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: wizard.eventDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(primary: _gold, surface: _surfaceDark, onSurface: _textLight),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) ref.read(wizardProvider.notifier).setEventDate(date);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _surfaceDark,
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: _gold, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                wizard.eventDate == null ? 'Select Event Date' : '${wizard.eventDate!.day}/${wizard.eventDate!.month}/${wizard.eventDate!.year}',
                                style: TextStyle(fontSize: 14, color: wizard.eventDate == null ? _muted : _textLight),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right, color: _muted, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // === TIME RANGE ===
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Start time
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: wizard.eventStartTime ?? const TimeOfDay(hour: 18, minute: 0),
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(primary: _gold, surface: _surfaceDark, onSurface: _textLight),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (time != null) ref.read(wizardProvider.notifier).setEventStartTime(time);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _surfaceDark,
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule, color: _gold, size: 18),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Start', style: TextStyle(fontSize: 10, color: _muted)),
                                        Text(
                                          wizard.eventStartTime == null ? '--:--' : wizard.eventStartTime!.format(context),
                                          style: TextStyle(fontSize: 14, color: wizard.eventStartTime == null ? _muted : _textLight, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('to', style: TextStyle(fontSize: 12, color: _muted)),
                          ),
                          // End time
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: wizard.eventEndTime ?? const TimeOfDay(hour: 22, minute: 0),
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(primary: _gold, surface: _surfaceDark, onSurface: _textLight),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (time != null) ref.read(wizardProvider.notifier).setEventEndTime(time);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _surfaceDark,
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule, color: _gold, size: 18),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('End', style: TextStyle(fontSize: 10, color: _muted)),
                                        Text(
                                          wizard.eventEndTime == null ? '--:--' : wizard.eventEndTime!.format(context),
                                          style: TextStyle(fontSize: 14, color: wizard.eventEndTime == null ? _muted : _textLight, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // === BOTTOM BAR ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkBg,
                boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: 0.3))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_gold, _goldLight]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.push('/wizard/types'),
                          child: const Center(child: Text('Next — Select Beverages', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Navigate to Hard Drinks category list
                      context.push('/category/a1000000-0000-0000-0000-000000000001');
                    },
                    child: const Text('Browse Catalog Instead', style: TextStyle(color: _gold, fontSize: 12, decoration: TextDecoration.underline, decorationColor: _gold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNumberDialog(BuildContext context, String label, int current, int min, int max, ValueChanged<int> onChanged) {
    final controller = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(label, style: const TextStyle(color: _textLight, fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: _gold, fontSize: 28, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: _darkBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 2)),
          ),
          onSubmitted: (val) {
            final n = int.tryParse(val) ?? current;
            onChanged(n.clamp(min, max));
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(
            onPressed: () {
              final n = int.tryParse(controller.text) ?? current;
              onChanged(n.clamp(min, max));
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: _gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// === CIRCULAR +/- BUTTON ===
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? _border : _border.withValues(alpha: 0.3), width: 2),
        ),
        child: Icon(icon, size: 24, color: enabled ? _gold : _muted.withValues(alpha: 0.3)),
      ),
    );
  }
}

// === MINI STEPPER (for children) ===
class _MiniStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final VoidCallback onTap;
  const _MiniStepper({required this.value, required this.min, required this.max, required this.onChanged, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
            child: Icon(Icons.remove, size: 16, color: value > min ? _gold : _muted.withValues(alpha: 0.3)),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textLight)),
          ),
        ),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
            child: Icon(Icons.add, size: 16, color: value < max ? _gold : _muted.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }
}
