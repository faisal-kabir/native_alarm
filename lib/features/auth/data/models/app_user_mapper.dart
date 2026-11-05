import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';

extension SupabaseUserMapper on User {
  AppUser toEntity() => AppUser(id: id, isAnonymous: isAnonymous);
}
