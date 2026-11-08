/// Where a list loaded from the server stands (only matters while there is nothing to
/// show yet).
enum LoadStatus {
  /// Waiting for the first answer from the server.
  loading,

  /// The server answered and the list is up to date.
  loaded,

  /// The server could not be reached and nothing is available to show.
  failed,
}
