import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database/database.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database
  await Database.initialize();

  // Cleanup old chat messages (keep only last 30 days)
  await Database.cleanupOldMessages();

  runApp(const ProviderScope(child: MoneyApp()));
}
