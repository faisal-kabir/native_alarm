/// App-wide constant values.
abstract final class AppConstant {
  /// How many alarms a user can have at once (the "Up to 3" meter).
  static const int maxAlarmCount = 3;

  /// How far the ringing screen's Snooze puts the alarm off, in minutes.
  static const int snoozeMinutes = 5;

  /// Border radius that turns any box into a pill / capsule.
  static const double pillRadius = 999;

  /// Steps of the Create Reason flow, as designed (the top progress bar fills 1/5
  /// on the first one).
  static const int createReasonStepCount = 5;

  /// The "What are you working toward?" text: at most this many characters, and at
  /// least [purposeMinLength] characters and [purposeMinWords] words to continue.
  static const int purposeMaxLength = 180;
  static const int purposeMinLength = 12;
  static const int purposeMinWords = 2;

  /// The optional "Why does it matter to you?" text: empty (skip) or at least this
  /// many characters; at most [purposeMaxLength].
  static const int matterMinLength = 8;

  /// How long a reason can be, in seconds (the length choice on the sound step), and
  /// the one chosen at first.
  static const List<int> reasonLengthsSeconds = [30, 45];
  static const int defaultReasonLengthSeconds = 30;

  /// Longest name a goal can be given. A goal is named after its topic (a chip or the
  /// person's own words), so this is also the longest topic.
  static const int reasonNameMaxLength = 20;

  /// A topic the person types needs at least this many characters to continue.
  static const int topicMinLength = 2;

  /// The topic chips arrive in steps: the first 20, then "More" opens up to 35, then
  /// "More" the rest (`chipSteps`).
  static const List<int> topicChipSteps = [20, 35];

  /// Suggestions are shown this many at a time ("More ideas" adds as many again).
  static const int suggestionsPerPage = 3;

  /// Where the server's files (icons, images) live. The database stores only their
  /// path; add it to this with `mediaUrl()` (`lib/core/network/media_url.dart`) -
  /// never build a file URL by hand. This is Supabase Storage's public address; change
  /// it if the files are served from elsewhere (a CDN, another bucket prefix).
  static const String baseUrl = '$SUPABASE_URL/storage/v1/object/public/';

  /// Google sign-in (Google Cloud project `eala-01` → Google Auth Platform → Clients).
  /// [googleServerClientId] is the *Web* client: Google makes the ID token for it, and
  /// Supabase (Authentication → Providers → Google → Client IDs) accepts it.
  /// [googleIosClientId] is the iOS client; its reversed form is the URL scheme in
  /// `ios/Runner/Info.plist`, and the two must change together. Client IDs are public
  /// (no secret goes in the app).
  static const String googleServerClientId =
      '980238433703-5j6f873707lpbc8dpniq125e2rmgr5ss.apps.googleusercontent.com';
  static const String googleIosClientId =
      '980238433703-6o5pmdms55q2br4bgkspfvhnoch390s0.apps.googleusercontent.com';

  static const String SUPABASE_URL = "https://jnvohuvefbjgcuzpnmek.supabase.co";
  static const String SUPABASE_KEY =
      "sb_publishable_jSRwQ9vwCi7cJloq1tdgqQ_7VVDeCIN";
}
