/// How a person signs in to keep their goals: Apple or Google. (Before either, they
/// are an anonymous user of this device.)
enum AuthProvider {
  apple('apple'),
  google('google');

  const AuthProvider(this.value);

  /// What the server (`user.primary_provider`, Supabase's identity provider) calls it.
  final String value;

  /// The provider named [value], or null for anything else (`anonymous`, null...).
  static AuthProvider? fromValue(String? value) {
    for (final provider in values) {
      if (provider.value == value) return provider;
    }
    return null;
  }
}
