import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class RawSms {
  final String sender;
  final String body;
  final DateTime date;
  const RawSms({required this.sender, required this.body, required this.date});
}

/// Lecture de la boîte de réception SMS (Android uniquement).
/// Le code natif est dans android_patch/MainActivity.kt.
class SmsReader {
  static const MethodChannel _channel = MethodChannel('budget_app/sms');

  bool get supported => Platform.isAndroid;

  Future<bool> ensurePermission() async {
    if (!supported) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<RawSms>> readInbox({required DateTime since}) async {
    if (!supported) return [];
    final res = await _channel.invokeListMethod<Map>(
      'readInbox',
      {'since': since.millisecondsSinceEpoch},
    );
    return (res ?? [])
        .map((m) => RawSms(
              sender: '${m['address']}',
              body: '${m['body']}',
              date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
            ))
        .toList();
  }
}
