/// Thrown by remote DataSources; repositories turn it into a [ServerFailure].
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);
}

/// Thrown by local DataSources; repositories turn it into a [CacheFailure].
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local storage error']);
}

/// The person closed the Apple / Google sheet without choosing.
class CancelledException implements Exception {
  const CancelledException();
}

/// The chosen Apple / Google account already belongs to another Eala account, so it
/// cannot be linked (the app signs in to it and moves the anonymous user's things).
class AccountInUseException implements Exception {
  const AccountInUseException();
}
