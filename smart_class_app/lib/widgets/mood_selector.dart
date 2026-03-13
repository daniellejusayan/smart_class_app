import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class MoodSelector extends StatefulWidget {
  final int? value;
  final ValueChanged<int> onChanged;

  const MoodSelector({super.key, this.value, required this.onChanged});

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  static const _moods = [
    {'emoji': '😞', 'label': 'Terrible'},
    {'emoji': '😕', 'label': 'Bad'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😄', 'label': 'Great'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final isSelected = widget.value == index + 1;
            return GestureDetector(
              onTap: () => widget.onChanged(index + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.accent : AppTheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _moods[index]['emoji']!,
                      style: TextStyle(
                        fontSize: isSelected ? 28 : 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _moods[index]['label']!,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
