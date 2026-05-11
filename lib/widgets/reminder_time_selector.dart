import 'package:flutter/material.dart';

class ReminderTimeSelector extends StatefulWidget {
  final DateTime? initialTime;
  final bool initialHasReminder;
  final Function(bool hasReminder, DateTime? time) onChanged;

  const ReminderTimeSelector({
    super.key,
    this.initialTime,
    this.initialHasReminder = false,
    required this.onChanged,
  });

  @override
  State<ReminderTimeSelector> createState() => _ReminderTimeSelectorState();
}

class _ReminderTimeSelectorState extends State<ReminderTimeSelector> {
  late bool hasReminder;
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    hasReminder = widget.initialHasReminder;
    if (widget.initialTime != null) {
      selectedTime = TimeOfDay.fromDateTime(widget.initialTime!);
    } else {
      selectedTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (time != null) {
      setState(() => selectedTime = time);
      _notifyChange();
    }
  }

  void _notifyChange() {
    if (hasReminder) {
      final now = DateTime.now();
      final reminderTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      widget.onChanged(true, reminderTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text('Activer un rappel'),
          value: hasReminder,
          onChanged: (value) {
            setState(() {
              hasReminder = value ?? false;
              if (!hasReminder) {
                widget.onChanged(false, null);
              } else {
                _notifyChange();
              }
            });
          },
        ),
        if (hasReminder)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Row(
              children: [
                const Text('Heure du rappel: '),
                GestureDetector(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
