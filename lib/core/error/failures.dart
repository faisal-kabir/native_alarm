abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// The person closed the Apple / Google sheet without choosing: not an error to show.
class CancelledFailure extends Failure {
  const CancelledFailure(super.message);
}
