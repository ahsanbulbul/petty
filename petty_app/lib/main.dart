import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pmxyeihahwudrrgczkou.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBteHllaWhhaHd1ZHJyZ2N6a291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MzEzNTUsImV4cCI6MjA3NTMwNzM1NX0.5BC6IcPLY7rAr2cFAG4T-vBkXU7sYXo5lg8xIubSjkw',
  );
  runApp(const ProviderScope(child: PettyApp()));
}
