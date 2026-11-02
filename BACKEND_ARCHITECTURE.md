# Eala — Backend Architecture & Tech Stack

For the Flutter + Firebase build. **Business rules live in [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md); this document says how to build them.** If the two disagree, the spec wins, except for the items in §14, which need a decision.

**Terminology:** a **message** is one ready-to-play item: the written text plus its spoken audio. A Reason keeps **one** ready message on the device (the "shelf"); each play writes its replacement. The spec and prototype call it a "take", so in code and Firestore it is still named `take` (`takes` collection, `takeId`, `onTakeDelete`); only the prose says "message". On screen the user reads **message**, and never "take", "shelf", "credit", "wake-up" (as a noun), "morning" or "Vault Mode" — see FUNCTIONAL_SPEC.md's terminology note, which the notification and error strings Functions send must follow too.

The prototype in this repository models some of this more simply than the design below (a single take list instead of a played flag, no server, no model). FUNCTIONAL_SPEC.md §16 lists exactly where; when this document and the prototype differ on a *rule*, the spec §16 says which one is the intent.

---

## 1. Principles

1. **The client writes instructions; the server writes money and content.** The client owns Reasons, alarms and the user's name. Only Cloud Functions write messages and entitlement.
2. **Nothing is generated at ring time.** Audio is pre-rendered and cached on the device.
3. **Offline-first.** Every normal user action (edit a Reason, toggle an alarm, log a wake) is a plain Firestore write that queues offline. Do not put these behind callable functions, which fail offline.
4. **The server never computes alarm times.** Alarms are wall-clock local and scheduled natively on the device. The server doesn't know the timezone.
5. **Enforce in Security Rules and Functions.** Client checks are UX only.
6. **Serverless only.** No VPS, no Express server, no containers.

---

## 2. Tech stack

**App (Flutter / Dart)**
- Flutter stable (pinned with FVM), Riverpod, `go_router`, `freezed` + `json_serializable`, `very_good_analysis`.
- Audio: `just_audio` + `audio_session`. Voice and background bed play on two players and are mixed on-device.
- Native alarms (Swift / Kotlin, bridged with Pigeon or platform channels):
  - iOS 26+: AlarmKit. Older iOS: `UNUserNotificationCenter` with Time-Sensitive / Critical Alerts (entitlement needs Apple approval).
  - Android: `AlarmManager.setAlarmClock`, full-screen intent, foreground service, `BOOT_COMPLETED` receiver, exact-alarm permission check.
- Firebase: `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_app_check`, `firebase_crashlytics`, `firebase_analytics`, `firebase_remote_config`.
- Sign-in: `sign_in_with_apple`, `google_sign_in`.
- Purchases: `purchases_flutter` (RevenueCat).
- Other: `timezone` + `flutter_timezone`, `permission_handler`, `flutter_local_notifications`, `speech_to_text` (dictation), `image_picker` (support screenshot), `share_plus` (sharing quote images), `path_provider`, `connectivity_plus`, `device_info_plus`, `workmanager` (Android background sync), `in_app_review`, `url_launcher` with in-app browser mode (SFSafariViewController / Custom Tabs).

**Backend (Firebase / Google Cloud)**
- Firebase Auth, Cloud Firestore, Security Rules, Cloud Storage, Cloud Functions 2nd gen (TypeScript, Node 20, `zod`), Cloud Tasks, Cloud Scheduler, Secret Manager, App Check, FCM, Remote Config, Delete User Data extension.
- Firebase Emulator Suite for local dev and rules tests.

**AI**
- LLM: Claude (`claude-haiku-4-5-20251001`) or OpenAI small model. Called only from Functions.
- Moderation: OpenAI Moderation API (free), on input and output.
- TTS: ElevenLabs. Flash model is about $0.04 / 1k chars, Multilingual v2 about $0.08 / 1k chars. Pick by listening test. Eight app voices map to eight ElevenLabs voice IDs.

**Payments:** RevenueCat (free under $2.5k monthly tracked revenue, then 1%), App Store Connect + Play Console products.

**Web / ops**
- Firebase Hosting: landing page, privacy, terms, FAQ. Must be publicly reachable for store review.
- GitHub, GitHub Actions or Codemagic, Fastlane, TestFlight, Play internal testing, Firebase App Distribution.
- Crashlytics, Cloud Logging / Error Reporting / Monitoring, Firebase Analytics (PostHog or Mixpanel optional).
- Support: Help Scout (or shared Google Workspace inbox at first).
- Figma, Google Workspace (email), Cloudflare or registrar DNS for `eala.app`.

**Not needed:** VPS, Node/Express server, separate database, Superwall (add later for paywall A/B tests), admin panel at launch (use Firebase console + RevenueCat dashboard).

---

## 3. Architecture

```
 Flutter app ──(plain writes, offline queue)──▶ Firestore ◀──(reads, realtime)── Flutter app
     │  ▲                                          │
     │  └── audio files (Storage, owner-read) ◀─┐  │ document triggers
     │                                          │  ▼
     │ purchase                          Cloud Functions ──▶ Cloud Tasks (top-up, per user)
     ▼                                          │  ▲
 App Store / Play ─▶ RevenueCat ─webhook────────┘  └── Cloud Scheduler (daily)
                                                │
                                   Secret Manager keys
                                                ▼
                         LLM ─▶ Moderation ─▶ ElevenLabs ─▶ Storage + Firestore (message)
```

Flow in one line: **the client changes a Reason or alarm → a Firestore trigger enqueues a top-up → the top-up writes the messages that are owed → the client downloads the audio.**

---

## 4. Firestore data model

All paths under `users/{uid}`. `uid` is the Firebase Auth uid (anonymous first, then linked with Apple/Google; linking keeps the same uid). Use the same uid as the RevenueCat `app_user_id`.

| Path | Fields | Client writes? |
|---|---|---|
| `users/{uid}` | `name`, `provider`, `premium` (mirror of entitlement), `createdAt` | `name` only |
| `state/entitlement` | `plan` (`free`/`premium`), `status` (`trialing`/`active`/`grace`/`expired`/`free`), `interval` (`annual`/`monthly`), `trialEnd`, `willRenew`, `since` | No |
| `cues/{cueId}` | `name`, `focus`, `purpose` (≤180), `why` (optional), `obstacle` (optional enum: `snooze` \| `phone` \| `racing` \| `energy` \| `more`), `firstStep` (optional, ≤70), `style`, `voice`, `length`, `seq`, `plays`, `due`, `pending` (a write is waiting on the credit meter, §6.1), `written` (`{from, n}`), `createdAt`, `moderation` | Create: all except `seq`, `plays`, `due`, `written`, `moderation`. **Update: `name`, `focus`, `purpose`, `why`, `style`, `voice`, `length`** (§5); `obstacle` and `firstStep` are create-only for now (the prototype has no screen that edits them, and none that sets `firstStep` at all) |
| `cues/{cueId}/takes/{takeId}` | `message`, `audioUrl` (Storage path), `duration`, `variant`, `signature`, `madeAt`, `playedAt` (null until played) | No |
| `alarms/{alarmId}` | `hour`, `minute`, `meridiem`, `days[]` (0=Sun, `[]` = one-off), `byDay?` (`{[day]: {hour, minute, meridiem}}`: a time per day, spec §11.1a; the top-level time and `days` mirror it — schedule one OS alarm per distinct time and check the platform's alarm limit), `cueId`, `enabled`, `snooze` (min, 0=off), `sound`, `ring`, `enabledAt` | Yes (validated) |
| `wakeLog/{YYYY-MM-DD}` | `at`, `alarmId`, `cueId`, `takeId`, `text` | Yes |
| `likes/{quoteId}` | `at` — one per saved quote (§6.8) | Yes |
| `devices/{token}` | `platform`, `updatedAt` | Yes |
| `meta/limits` | generation counters for rate limiting | No |

Notes on deviations from the spec:
- `entitlement` lives in a `state` collection beside the other server-only documents.
- `takes.playedAt` is optional. A Reason keeps one message (`POOL = 1`); a message that has just played stays as the fallback until its replacement is written. A client may use `playedAt` to tell the two apart while both exist.
- `cues.moderation` is new, server-only: `pending` | `ok` | `generic` | `blocked` (+ `reason`).
- `wakeLog.text` is new. See §6.7 and the spec's storage rules (keep the transcript, not the audio).
- Do not mirror `message` or `duration` onto the Reason as the prototype does. The client reads the Reason's `takes` and plays the front of the pool.

Storage paths: `users/{uid}/takes/{takeId}.mp3`, `support/{uid}/{id}`.

---

## 5. Security Rules (requirements)

- A user reads and writes only under their own `uid`.
- **Never client-writable:** `state/*`, `takes`, `cues.seq`, `cues.moderation`, `users.premium`, `meta/*`.
- **Reason create** requires `entitlement.plan == 'premium'` (read with `get()`). Reason update (the owner changing `name`, `focus`, `purpose`, `why`, `style`, `voice` or `length`) requires `entitlement.plan == 'premium'`; a lapsed account can read, delete and nothing else.
- **Reasons are editable:** the owner may update `name`, `focus`, `purpose` (≤180), `why`, `style`, `voice` and `length`; no value of `voice`, `length` or `sound` is plan-gated, but any Reason update needs Premium (above). No other field is client-writable. Because an edit to `purpose`, `why`, `style`, `voice` or `length` replaces the message (§14 D1), rate-limit regeneration server-side per Reason (the 30-day ceiling in §6 bounds the cost; add a per-day cap on top). Test it in the rules unit tests.
- **Reason validation (on create):** `purpose` ≤180 chars, `why` ≤180 chars, `firstStep` ≤70 chars, enums for `focus`/`style`/`voice`/`length`/`obstacle`.
- **Alarm validation:** `cueId` must exist (`exists()`), `snooze` ≥0, `sound` in enum. Any alarm write needs Premium, except setting `enabled` to false, which is always allowed (a lapsed account's alarm edits open the paywall in the app). **Alarm limit:** no more than three alarm documents (FUNCTIONAL_SPEC.md §4). Rules cannot count across documents, so the client enforces it for UX and `onAlarmWrite` is the backstop (§7): a create that would make a fourth alarm is deleted.
- **Hard invariant:** an alarm can never exist without a valid `cueId` (create or update).
- `wakeLog` create/update: owner only, doc id must match `YYYY-MM-DD`.
- **Storage:** owner read on `users/{uid}/**`, no client write. `support/{uid}/**` is owner write with size ≤5 MB and `image/*` only.
- App Check enforced on Firestore, Storage and Functions. Test rules with `@firebase/rules-unit-testing`, including "try to write another user's data" and "try to grant myself Premium" and "try to create a fourth alarm".

---

## 6. Core logic

### 6.1 Cost control
Cost is bounded by these rules (FUNCTIONAL_SPEC.md §4):
- **Only a live Reason writes.** A Reason is live when at least one *enabled* alarm points at it. Nothing is prepared for any other Reason.
- **At most three alarms** (`ALARM_SLOTS`; one Reason each), so at most three Reasons are live. Reasons are unlimited. A Reason that is not live keeps whatever message it already has, unused.
- **Per Reason, a monthly ceiling:** at most 31 messages written in any 30-day window (`written.n`, reset when `now − written.from > 30d`). A daily alarm needs 30 (one per play, §6.3), so the ceiling is a backstop for a misbehaving clock; past it the Reason keeps rotating what it has.
- A failed generation (TTS failed) is not counted and costs no credit: nothing was delivered to the user.
- **Credits — the account-wide meter on what a person asks for** (FUNCTIONAL_SPEC.md §4, rule 3). Reasons are free to make, so any per-Reason cap restarts with each new one; the cap therefore lives on the account. `meta/limits/{uid}` holds `{ periodStart, used, bonus }`, written **only** by Cloud Functions (rules deny client writes), and `periodStart` is anchored on the subscription's start: it rolls every 30 days on every plan (monthly credits on Annual too), and is reset to a full balance at every new subscription (first purchase or trial start, resubscribe after a lapse). A trial converting is not a new subscription and keeps its month. `bonus` is never reset, lapse included.
  - **One balance**, `ALLOWANCE` = 100 a month, the trial included (no separate trial allowance: the per-day ceiling bounds what a trial can cost); a credit is one message. The top-up writes in §6.4 spend from the same balance, one each, so the balance alone bounds the cost of any account whatever it does. Add a silent per-day ceiling on messages written per account (about 6) so the month cannot be spent in one sitting. Set the figures from the real cost per message; at about 1.6¢ a message (Inworld TTS-2) a full 100 is about $1.60 against about $6.67 a month on the annual plan.
  - **What costs one** is decided by the server from the write itself, never from a client flag: a new enabled alarm; an alarm's `cueId` changing; a Reason write that changes `purpose`, `why`, `style`, `voice` or `length` while an enabled alarm points at it; an alarm switched on whose Reason has an empty pool, or whose message was written before the Reason's last edit (its signature no longer matches). Everything else is free. Deleting refunds nothing, and the counter is not derived from documents that can be deleted, so delete-and-recreate cannot reset it.
  - **Out of allowance is a state, never an error.** An alarm write (new, switched on, re-pointed) is accepted: the Reason gets `pending: true`, nothing is generated, and the alarm rings and then shows the quote, with no voice message. A **Reason edit** that needs a credit is **rejected** instead (the client opens the credits sheet first; the server refuses it as a backstop), so an edit is never applied later on its own. When the period rolls over or a pack is bought, `pending` Reasons are walked oldest first, but only those an enabled alarm plays are charged and generated; the rest stay pending, free. A paid edit generates the replacement at once (not on a later morning), so it is on the device, offline-ready, before the next ring.
  - **Idempotency.** Charge and generate in one transaction keyed by a client-supplied operation id, so a retry or a double-tap spends once. The generation endpoint also has the per-minute and per-hour limits in §7 and a global spend alarm; if daily spend jumps, a kill switch stops writing for every account (alarms keep ringing what they have) until it is cleared.
  - **Add-on packs** are a consumable in-app purchase (RevenueCat/StoreKit, non-renewing; +20 credits, $2.99, never expiring). The webhook adds to `bonus` in `meta/limits/{uid}` idempotently by transaction id. Spending takes from the month's `ALLOWANCE` first and from `bonus` only after it; `bonus` is not reset at the period boundary. A refund (the store's `REFUND` event) takes back whatever of it is unspent. Buying a pack immediately releases `pending` Reasons, oldest first.
  - **Trials** are tied to the Apple ID (App Attest / receipt `original_transaction_id`), so a new account does not buy a new allowance.
- **Enabling an alarm** is the user-visible trigger: if the Reason has no message the top-up writes the first one; otherwise nothing is written until a play makes one due (§6.3). The client shows "Preparing your message" then "Message ready" on the alarm card; it asks no question and quotes no number.


### 6.2 Entitlement
- Only the RevenueCat webhook function writes `state/entitlement` (and mirrors `users.premium`).
- Free grants nothing. Premium allows unlimited Reasons and three alarms, all voices, sounds and lengths.
- Plan is enforced at creating a Reason, arming an alarm and saving an edit to a Reason or an alarm (rules, §5). Switching off and deleting are never gated. Lapsed accounts can still browse, delete, sign out and delete the account.

### 6.3 The pool and what rings
- **Signature** = `sha256(voice|style|length|purpose|name)` (plus the `why` and the `firstStep` when present, in that order). Soundtrack is excluded, and so is `obstacle`: it only colours the prompt ("speak to it without naming it") and is not a reason to discard a waiting message.
- **Pool size: 1** message per live Reason (`POOL`). **Zero** for a Reason with no enabled alarm: nothing is prepared for it.
- **No rotation:** the Reason's one message plays at every ring until its replacement is written. `plays` increments on every consume.
- **When a new message is owed** (`due = true`, set by the consume): after every play, as long as the account has a credit left (§6.1). The first message is written when the first alarm is switched on (no message yet). The new message **replaces** the old one; the old one is deleted only after the new one is stored.
- **Nothing is deleted otherwise.** If the last alarm is deleted or switched off, the message stays, unused. If an alarm is pointed at the Reason again it plays it with nothing new written.
- **What rings** (same rule for every alarm on the Reason):
  1. the message at the front of the pool
  2. otherwise (the Reason's message was lost or has not arrived) the most recently played message, whatever voice or tone it was made in, with no network
  3. otherwise (the Reason has never had a message) ring, then the quote card with no voice message
- **With no connection or no credits** the alarm replays the message cached on the device; a missing refill costs only variety. An edit made offline syncs when the connection returns, and until the next message is written the Reason plays the last one it has.
- No "shuffle" or "show me another" feature.


### 6.4 Top-up job (`topUpUser(uid)`)
Runs as a Cloud Task, one at a time per user (lock doc with `lockedUntil`). Triggered by: Reason create, alarm create/edit/enable/disable, message consumed, plan change, daily sweep.

1. Load entitlement. If plan isn't premium, stop (lapsed accounts generate nothing).
2. For each **live** Reason in library order (newest first, as the app lists them), skip unless `moderation` is `ok` or `generic`:
   - skip if the Reason already has a message and `due` is false
   - skip if `written.n ≥ 31` inside the current 30-day window, or if the account has no credit left (§6.1)
   - otherwise generate **one** message and replace the Reason's current one with it. An edit to what a message is written from writes the replacement at once (decision D1, §14).
3. Cap work per run (e.g. 6 messages), then re-enqueue itself if more are owed. This keeps each run short.
4. Enqueue with a short delay and a deterministic task name per user per 30s window, so rapid edits collapse into one run.


### 6.5 Generating one message
1. Read `seq` from the Reason; `variant = seq`.
2. Build prompt (see `src/lib/prompt.js`): user name and purpose passed as **delimited, untrusted data**; rules live in the system prompt. Flip pronouns in `purpose` first (my→your, I→you; see `toSecondPerson` in `src/data/mock.js`). Sanitize the name to letters, space, hyphen, apostrophe (2–24 chars).
3. Call the LLM. **Validate** and reject if any hit: empty; starts with a banned greeting; quoted-back pattern; time-of-day term or clock time; wake-up language, or a mention of alarms or snoozing; markdown or list marker; word count outside 0.6×–1.5× target (62 / 100 words for short / standard); refusal string.
4. On rejection retry once. Still failing → **template writer** (port `writeMessage` from `src/data/mock.js`; omit the greeting openers, since generated text must have no greeting).
5. Moderate the output. Unsafe → treat as a failure (template).
6. Sanitize for TTS (strip markdown, symbols, quotes).
7. ElevenLabs TTS (retry once). Failure → no message is written, the credit is released and the write retries on the next top-up. The Reason keeps what it has; with nothing, the alarm rings and shows the quote.
8. Upload the mp3 to Storage. Use a mid-bitrate mono mp3 (~64 kbps ≈ 0.5 MB/min; verify the ElevenLabs output format names).
9. **Transaction:** write the message, `seq = seq + 1`, clear `due`, `written.n += 1`, and spend the credit (§6.1).

`duration` is the spoken length only, never including the background bed.

### 6.6 Waking up and consuming a message
The message is marked played on **dismiss** ("slide to get up"), never on ring. Nothing is written for it here: it was prepared ahead of time (§6.3, §6.5).
- The client writes `wakeLog/{localDay}` directly (works offline). First dismissal of a day creates the doc with `cueId` and `takeId`; later dismissals that day only update the entry and do **not** consume again. (Alarms on different Reasons: D5.)
- Trigger `onWakeLogCreate` (create only), when the message that played was the Reason's current message:
  - set `playedAt = now` and `plays += 1` (no rotation: there is only one)
  - set `due` (every play owes a fresh message) and enqueue a top-up; the write happens only if the account has a credit and the Reason is under its monthly ceiling (§6.1)
- If the alarm replayed the last played message (nothing new was available), the `wakeLog` entry is still written and the message simply plays again next time.
- Snoozing never writes a message or touches the pool.


### 6.7 Snooze lines
A snooze replays the Reason's same message — there are no separate snooze clips, nothing extra to render, and nothing for the client to fetch at snooze time.

### 6.8 Today's quotes
The 160 lines (ten areas × 16, ids `${area}-${nn}`, append-only) ship with the app or from Remote Config / a CDN file, so showing them costs nothing and needs no function. The three of the day are computed on the device from (who, which day), and each notification carries only the id of one line — the client rebuilds the rest. A save is a write to `users/{uid}/likes/{quoteId}`; there are no counts, so nothing is aggregated. Share images are drawn on the device. The notifications are scheduled pushes, three a day spread across the day (never two together), sent only when `prefs.notify.quotes` is true; the switch is off until the person turns it on from the run's last card or Settings. Not built: the notification, a share link, and any server-side ranking.

---

## 7. Cloud Functions

| Function | Trigger | Does |
|---|---|---|
| `onAuthCreate` | Auth onCreate (v1 trigger) | Create `users/{uid}` and `state/entitlement` (free) |
| `onCueWrite` | Firestore | If `purpose`, `why` or `firstStep` changed: moderate, language check, gibberish check → set `moderation`. Then enqueue top-up. |
| `onCueDelete` | Firestore | Delete the Reason's alarms (backstop; the client also deletes them in one batch), messages, Storage files |
| `onAlarmWrite` | Firestore | Enforce the three-alarm limit (delete a create that would exceed it or repeat a Reason), then enqueue top-up |
| `onWakeLogCreate` | Firestore | Set `due` when a play comes due, enqueue top-up (§6.6) |
| `onTakeDelete` | Firestore | Delete the Storage object |
| `topUpUser` | Cloud Tasks | §6.4 and §6.5 |
| `revenuecatWebhook` | HTTPS | §8 |
| `dailyMaintenance` | Scheduler | Sweep trials past `trialEnd` with `willRenew=false` (webhook backstop), enqueue top-up for users with enabled alarms, prune `meta/limits` |
| `submitSupport` | Callable | Validate, rate-limit, attach context (plan, app/OS/device, permission states), create ticket (Help Scout API or email-to-inbox) |
| `deleteAccount` | Callable | §11 |

Callables and HTTPS: require auth (except the webhook), App Check, `zod` validation.

**Rate limiting** (separate from the per-Reason monthly ceiling and the account meter in §6.1): per-user counters in `meta/limits`, e.g. max generations per hour and per day, enforced in `topUpUser`. Also cap Reason writes via the task debounce above.

---

## 8. Payments and lifecycle

**Products** (one subscription group, Annual one level above Monthly): Annual $79.99/yr with a 3-day free trial as its introductory offer; Monthly $9.99/mo; the onboarding one-time offer, Annual at $47.99/yr with its own 3-day trial (a separate product in the same group, shown only after the onboarding App Store sheet is closed); and the credit pack, +20 credits for $2.99 (consumable). Check introductory-offer eligibility before showing any trial: Apple grants one per Apple ID per group.

Set `Purchases.logIn(uid)` in the app. The webhook authenticates with a shared-secret header and de-duplicates by event id. **Verify event names and fields against RevenueCat docs.**

| RevenueCat event | Effect |
|---|---|
| Initial purchase (trial) | `plan=premium`, `status=trialing`, `trialEnd`, `willRenew=true` |
| Initial purchase (no trial) | `status=active` |
| Renewal | `status=active` (covers trial conversion and recovery from grace). |
| Cancellation | `willRenew=false` only. Access runs to `trialEnd` / period end. |
| Uncancellation | `willRenew=true` |
| Billing issue | `status=grace`. Behaves as active Premium. |
| Product change | Update `interval` only. |
| Expiration / refund | **Lapse** (below) |

**Lapse** (one transaction):
- `status=expired`, `plan=free`, `willRenew=false`, `trialEnd=null`, `users.premium=false`
- every alarm with `enabled=true` → `enabled=false` (keep `enabledAt`)
- never delete a Reason, alarm, message or setting

**Resubscribe:** `status=active`, no trial. The alarms the lapse switched off (`pausedByLapse`) are switched back on, each billed as switching it on would be; alarms the person had off stay off. The pools refill from the existing Reasons.

Rules: cancel + resubscribe in the same trial never grants a second trial. Purchases are never trusted from the client callback. The client only reads `state/entitlement`.

---

## 9. Client responsibilities (what the backend relies on)

- **Sync:** on app open, on silent FCM push and in a background task, read the Reason's `takes` and download any missing audio to app storage. Delete local audio when the message doc disappears.
- **OS alarm registration:** re-schedule on every alarm change, on app open and after reboot. Alarms are local and use the device clock and timezone, so re-check across DST.
- **Lapse offline:** if `status=expired`, or `trialing` with `willRenew=false` and `now > trialEnd`, switch alarms off locally on open. The write queues and syncs later. A lapsed phone does not ring, offline or not.
- **Permissions:** re-read alarm and notification permission on every foreground. Show "Enable Alarm Access" when off.
- **Composer and drafts:** Firestore offline persistence keeps Reason edits. Don't discard a draft on token expiry; Auth refreshes silently.
- **Ring time:** play per the §6.3 rule (unplayed message, else last played, else ring then the quote), mix the alarm's `sound` locally. Never call the network.

---

## 10. Safety and abuse

- Moderation runs on `purpose` + `why` + `firstStep` **before** any generation (blocked → no generation, friendly message from `moderation.reason`), and on LLM output.
- English only: detect non-English input and block with "English only for now".
- Gibberish → `generic` (template with a generic purpose) instead of hallucinating meaning.
- Prompt injection: user text only in delimited data fields; adversarial tests before launch.
- Hard caps: `purpose` and `why` 180 chars each and `firstStep` 70 chars, enforced in rules **and** Functions.
- Server-side rate limit (§7). App Check on everything.
- Keep user `purpose`, names and transcripts out of analytics events and logs.
- Record vendor retention settings (LLM, ElevenLabs) and sign DPAs.

---

## 11. Account deletion, support, push

- **`deleteAccount` (callable):** `recursiveDelete` on `users/{uid}`, delete Storage prefixes, delete the RevenueCat subscriber (REST), delete the Auth user. Tell the user to cancel the store subscription themselves (the app cannot). Data export stays client-side as in the prototype (Reasons, alarms, preferences).
- **Support:** the form in Settings → `submitSupport`. The client uploads the optional screenshot to `support/{uid}/…` (size and type limits above). Name and email are prefilled and editable. Set a retention period and include support data in account deletion.
- **Push (FCM):** tokens in `devices/`. Silent pushes tell the app to sync audio. Three categories in user prefs: "Trial & billing" (trial ending, payment failed, payment still failing, Premium ended, new messages paused), "Alarm reminders" (all alarms off for a whole day) and "Thoughts for the day" (off by default). Every notification, its words and its category are listed in FUNCTIONAL_SPEC.md §11.0b. Lifecycle messages are sent by Functions from webhook changes. "Payment still failing" is scheduled by the `billing issue` webhook for a day or two before the store's grace expiry (cancelled on recovery).

---

## 12. Environments, delivery, monitoring, cost

- **Three Firebase projects:** dev, staging, prod, with matching Flutter flavors. Choose the Firestore location once (it can't change).
- **CI:** analyze and test on every PR, Functions unit tests (Vitest/Jest), Emulator Suite tests for rules and triggers. Release: Fastlane to TestFlight / Play internal, `firebase deploy` for Functions, rules, indexes, Hosting. Upload dSYMs and Android mapping files for Crashlytics.
- **Monitoring and alerts:** Functions error rate, generation failures, TTS failure rate, webhook failures, top-up queue depth. App-side: log `alarm_scheduled`, `alarm_rang`, `alarm_dismissed` and alert when scheduled vs rang diverge. Report native alarm failures as Crashlytics non-fatals.
- **Backups:** Firestore scheduled backups and point-in-time recovery.
- **Cost:** a message costs about 3–6¢ (TTS dominates). A daily alarm needs 30 messages per Reason a month (one per play, §6.3) and the account's balance is 100 (§6.1), so a subscriber with the maximum three live Reasons (three alarms) costs at most about $1.60 a month on Inworld TTS-2 ($2.70–5.40 at the 3–6¢ above) against about $5.70–8.50 net revenue, and typically far less. Trials cost about 3–6¢ each (one message). Set billing budgets and alerts on Google Cloud, the LLM provider and ElevenLabs, plus the per-user cap in §7.
- **Admin:** no panel at launch. If needed later, a small Hosting page with admin-only Functions gated by custom claims (look up user, reset, delete).

---

## 13. Company, store and compliance checklist

- Form the legal entity; IP assignment from all contributors; file the "Eala" trademark.
- Apple and Google **organization** accounts (Apple needs a D-U-N-S number, which takes days); apply for the Apple Small Business Program; bank and tax forms.
- Apply early for the **Critical Alerts** entitlement.
- Counsel-approved privacy policy and terms at public URLs (replace the prototype's draft text). The draft says played audio is deleted; it must now say each Reason keeps one message, replaced as new ones are written. Privacy labels and the Data Safety form must match the actual SDKs.
- iOS Info.plist: alarm usage, microphone, speech recognition; background modes: audio, fetch, remote-notification. Android: `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE`, `WAKE_LOCK`, `RECORD_AUDIO`.
- Sign in with Apple is required because Google sign-in is offered. Restore Purchases and in-app account deletion must exist.
- Confirm ElevenLabs commercial licence, soundtrack licences and voice-portrait licences. Keep the records.
- No medical or sleep-treatment claims in app or store copy.

---

## 14. Decisions

- **D1 — Edits and the message.** Reasons are editable. After an edit to what a message is written from (`purpose`, `why`, `style`, `voice`, `length`) with an alarm on the Reason, the edit spends one credit and writes the replacement immediately, replacing the one message on the device; with nothing left the edit is not saved (rejected; the client shows the credits sheet) and the old message keeps playing. An edit to a Reason no enabled alarm plays deletes its message (nothing is written); the alarm that is later enabled writes the first one from the new wording. A rename or an area change leaves the message alone. The client holds edits and commits once.
- **D2 — Snooze audio.** A snooze replays the same message, so there are no snooze clips (§6.7).
- **D3 — Failed generations** (TTS failure) do not count towards the per-Reason monthly ceiling or the credit meter, because nothing was delivered to the user.
- **D4 — One-off alarms.** A one-off alarm must switch itself off once it has done its job, or it keeps a message prepared every day. The prototype does it the moment the alarm *rings* (the foreground scheduler stands in for the OS); the native build should do it on dismissal or on the missed screen, whichever ends the cycle, so a one-off that was never answered is not silently re-armed.
- **D5 — Alarms on different Reasons** dismissed on the same day: only the first dismissal consumes a message (one `wakeLog` per day). Confirm that is acceptable. (The prototype consumes on every dismissal — FUNCTIONAL_SPEC.md §16 — so this is a requirement on the real trigger, not behaviour to copy from the prototype.)
- **D6 — Top-up order** across Reasons is library order, as in the spec. Ordering by next alarm would be fairer but needs the device timezone on the server.
- **D7 — LLM and TTS model choices** by listening and cost test; state management and native-alarm approach (custom native recommended over a package, since alarm reliability is the core promise).
