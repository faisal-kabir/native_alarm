/// App-wide constant values.
abstract final class AppConstant {
  /// How many alarms a user can have at once (the "Up to 3" meter).
  static const int maxAlarmCount = 3;

  /// Border radius that turns any box into a pill / capsule.
  static const double pillRadius = 999;

  /// Steps of the Create Reason flow, as designed (the top progress bar fills 1/5
  /// on the first one).
  static const int createReasonStepCount = 5;

  /// Where the server's files (icons, images) live. The database stores only their
  /// path; add it to this with `mediaUrl()` (`lib/core/network/media_url.dart`) -
  /// never build a file URL by hand. This is Supabase Storage's public address; change
  /// it if the files are served from elsewhere (a CDN, another bucket prefix).
  static const String baseUrl = '$SUPABASE_URL/storage/v1/object/public/';

  static const String SUPABASE_URL = "https://jnvohuvefbjgcuzpnmek.supabase.co";
  static const String SUPABASE_KEY =
      "sb_publishable_jSRwQ9vwCi7cJloq1tdgqQ_7VVDeCIN";
}
