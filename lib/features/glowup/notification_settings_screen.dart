// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _State();
}

class _State extends State<NotificationSettingsScreen> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('glowup_notifications_enabled') ?? false;
      final hour = prefs.getInt('glowup_notifications_hour') ?? 20;
      final minute = prefs.getInt('glowup_notifications_minute') ?? 0;
      _time = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glowup_notifications_enabled', _enabled);
    await prefs.setInt('glowup_notifications_hour', _time.hour);
    await prefs.setInt('glowup_notifications_minute', _time.minute);

    if (_enabled) {
      await NotificationService.instance.scheduleDailyReminder(
        id: 2001,
        title: 'Keep your glow streak going',
        body: 'Complete today\'s tasks to keep your streak alive.',
        hour: _time.hour,
        minute: _time.minute,
      );
    } else {
      await NotificationService.instance.cancel(2001);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (!mounted) return;
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: _enabled,
              title: const Text('Daily reminders'),
              subtitle: const Text('Get nudges to complete your daily plan'),
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Reminder time'),
              subtitle: Text(_time.format(context)),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _pickTime,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await _save();
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
