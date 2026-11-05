import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the Supabase client to data sources. `Supabase.initialize` runs in
/// `main()` before anything resolves this.
@module
abstract class SupabaseModule {
  @lazySingleton
  SupabaseClient get supabase => Supabase.instance.client;
}
