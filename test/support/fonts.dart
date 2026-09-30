import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's real fonts into the test environment. Without this,
/// Flutter tests use a placeholder font whose letters are much wider, which
/// makes layout checks unrealistic.
Future<void> loadAppFonts() async {
  const families = {
    'Inter': [
      'Inter_400Regular',
      'Inter_500Medium',
      'Inter_600SemiBold',
      'Inter_700Bold',
    ],
    'Poppins': [
      'Poppins_400Regular',
      'Poppins_500Medium',
      'Poppins_600SemiBold',
      'Poppins_700Bold',
    ],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}
