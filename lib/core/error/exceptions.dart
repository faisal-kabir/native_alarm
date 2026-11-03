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
