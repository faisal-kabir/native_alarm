# Eala — Functional Spec (Backend & App Logic)

Source of truth for porting the prototype to Flutter + Firebase (Firestore, Cloud Functions, Storage) + OpenAI/Claude + ElevenLabs. Every rule below is extracted from the working prototype's logic, not the visual design — build against this, not against pixel-matching Figma.

**Terminology:** a *take* is one ready-to-play message: the generated text plus its spoken audio. The "shelf" is the one a Reason keeps ready ahead of time. How to build all of this is in [BACKEND_ARCHITECTURE.md](BACKEND_ARCHITECTURE.md).

**Reason.** What the user sees is a **Reason**: they add reasons, connect one to an alarm, and the alarm reminds them of it. Code identifiers use `cue` (`cue`, `cueId`, `CueCreate`, `cues.*`), and the creation flow is `CueComposer.jsx`. The free-text answer to "What are you working toward?" is the **Purpose** in the data model and on Reason detail; the second answer, "Why does it matter to you?", is the **why**.

**What the user reads is a different vocabulary, and it is fixed.** A Reason writes a **message**. "Take", "shelf" and "generation" never reach the screen, and neither does "wake-up" as a noun or "morning" (a Reason plays at 6am Monday and 9pm Thursday, so a time-of-day noun is wrong for half its readers). The verb "wake up" in an ordinary sentence is just English and stays. Code keeps `take` and `shelf`; the boundary is the screen (Settings › Prototype is exempt). Where this document says "wake-up" in prose it means the event, not UI copy.

**Status.** This document describes the prototype as of 2026-10-23, plus the server-side rules a real build must add. Where the prototype deliberately stops short of the spec, §16 says so; those are gaps to build, not behaviours to port.

---

## 1. Core data model — three objects, never merged

```
PURPOSE  →  CUE  →  ALARM
```

- **Purpose** — free text the user writes about what they're working toward. Lives inside a Reason, not standalone.
- **Reason** — a *standing instruction*, not a recording: `{purpose, why, focus, tone, voice, length, name}`. Produces new audio on a schedule — never one fixed file. **Every field can be edited after creation** (see below).
- **Alarm** — a schedule plus how it plays: `{time, days[], cueId, enabled, snooze, sound, ring}` (`ring` = the wake-up tone; `sound` = the music behind the message). References a Reason by id. Never owns audio.

**Why soundtrack lives on the Alarm, not the Reason.** It is the one choice that never reaches the renderer — the bed is mixed locally at playback (§5), so changing it costs nothing and invalidates no takes. That makes it a property of a *playing* rather than of an instruction. It also has to be per-alarm to be expressible at all: "a rising score behind my 6 AM alarm and silence behind my 3 PM one" is a choice about two alarms, not about the Reasons they play.

**Reasons are editable.** Every field — `focus`, `purpose`, `why`, `style` (tone), `voice`, `length`, `name` — can be changed on Reason detail, several at once, applied together by one **Save Changes** (with **Discard**); changed fields show their new value in orange. Nothing blocks an area change; Healing's gentler rules apply to a Reason while it is Healing (the demanding tone is not offered for it). A genuinely separate goal is a new Reason. Reasons are not capped per area — only the three alarms are limited (§4), and a Reason nothing plays costs nothing to keep; the server may hold an invisible ceiling (e.g. 50) against abuse.

**What an edit does to the message.** A Reason keeps **one** message (§6). An edit to `purpose`, `why`, `style`, `voice` or `length` while an alarm that is on plays the Reason spends one credit and writes the replacement at once, which replaces the message on the phone; the next ring plays the new wording. If no credit is left the edit does **not** save: Save opens the credits sheet, the edit stays held on screen, and the alarm keeps its current message (§4). Nothing is ever applied later on its own. An edit to a Reason **no enabled alarm plays** (none connected, the alarm is off, or the account has lapsed) costs nothing and writes nothing, but it lets the old message go, so it can never ring in the old voice or words; the alarm that is later switched on (or resubscribed) writes the first message from the new instruction, for one credit (§4). The person is told (see §11: "Editing a Reason").

**Hard invariant, enforce server-side too, not just client UI:** an alarm can never exist without a `cueId`. Cannot be created without one, cannot be toggled on without one. Deleting a Reason that alarms use must either reassign those alarms to another Reason or delete them with it — never leave an alarm pointing at nothing.

---

## 2. Firestore data model

```
users/{uid}
  name: string
  provider: "apple" | "google"
  premium: bool                      // mirrors entitlement.plan, kept for fast reads
  createdAt: timestamp

users/{uid}/entitlement (single doc)
  plan: "free" | "premium"
  interval: "annual" | "monthly" | null
  since: timestamp
  storeTransactionId: string         // for receipt re-validation
  status: "trialing" | "active" | "grace" | "expired" | "free"   // §10.1
  trialEnd: timestamp | null
  willRenew: bool                    // false the moment a cancellation lands

users/{uid}/cues/{cueId}
  name: string
  focus: string                      // enum, see §5
  purpose: string                    // user-authored, max 180 chars
  why: string | null                 // optional, "Why does it matter to you?"; joins the signature only when present
  obstacle: string | null            // optional, set in onboarding's mirror (snooze | phone | racing | energy | more): what usually happens after the alarm rings; goes into the message prompt (not editable on Reason detail); also chooses the Insight finding and the demo's closing line
  firstStep: string | null           // optional, ≤70 chars: a step the message is asked to steer toward; joins the signature only when present (not editable on Reason detail). **No screen sets it**
  style: string                      // tone enum, see §5
  voice: string                      // voice id, see §5
  length: "short" | "standard"
  seq: number                        // monotonic variant counter, never resets
  plays: number                      // times a message has been played (drives the pool, §6)
  due: bool                          // owed a new message when its turn comes (§6)
  pending: bool                      // an alarm action (new, switched on, re-pointed) is waiting for a first message because no credit was left (§4); never set by a Reason edit
  owed: number                       // writes already paid for that the shelf has not made yet
  written: { from: timestamp, n: number }   // messages written in the current 30-day window (§6)
  createdAt: timestamp

users/{uid}/cues/{cueId}/takes/{takeId}
  message: string                    // generated text
  audioUrl: string                   // Storage path, pre-rendered
  duration: number                   // seconds
  variant: number
  signature: string                  // see §6 — invalidation key
  madeAt: timestamp

users/{uid}/alarms/{alarmId}
  hour, minute, meridiem
  days: number[]                     // 0=Sun..6=Sat, [] = one-off
  byDay?: { [day]: { hour, minute, meridiem } }      // a time for each day it rings, see §11.1a; hour/minute/meridiem/days then mirror it
  cueId: string
  enabled: bool
  snooze: number                     // minutes, 0 = off
  sound: string                      // soundtrack id, see §5 — per-alarm, see §1
  ring: string                       // the ring tone ("Alarm sound" in the editor)
  enabledAt: timestamp               // last time switched on

users/{uid}/likes/{quoteId}           // today's quotes (§11.0a): { at: timestamp }, one per favorited line

users/{uid}/wakeLog/{day}            // one doc per calendar day, day = "YYYY-MM-DD"
  at: timestamp
  alarmId, cueId: string
```

Everything above is cloud source-of-truth and syncs via Firestore's built-in offline persistence. See §9 for what must **also** be cached on-device outside Firestore.


---

## 3. Entitlements — what a plan allows

Single source of truth, gate every AI/voice/length action against this — never trust a client-side flag alone.

**Free is not an acquisition tier — it is the lapsed state.** Onboarding requires a subscription to finish (§11), so nobody signs up into Free. It is only what an account falls back to when a subscription lapses, is cancelled or is refunded, and it grants nothing, because generation is the product and generation costs money on every wake-up.

| | Free (lapsed) | Premium |
|---|---|---|
| Reasons you may create | **0** | **Unlimited** |
| Alarms you may have | **0** | **3** (§4) |
| Voices selectable | all 8 (not gated) | all 8 |
| Soundtracks selectable | all 8 (not gated) | all 8 |
| Lengths selectable | Short, Standard (not gated) | Short, Standard |

**The app itself stays open.** A lapsed account is not locked out: they can browse their Reasons (they cannot save edits to them, §3), read and play what is on a shelf, delete Reasons and alarms, change settings, sign out and close their account. None of that costs anything to serve, and a paywall in front of it would be an app holding somebody's own work hostage over a renewal — the version of this that earns a one-star review and a chargeback rather than a resubscribe.

**The plan is enforced at the two actions that start spend**, and nowhere else:

- `createCue` — a Reason with an armed alarm keeps writing messages
- `armAlarm` — and arming is the moment that starts; `plannedDepth()` gives a Reason no shelf at all until an enabled alarm points at it

Switching an alarm **off** is never gated. Stopping something is not a purchase, and a person tidying up after cancelling must not be blocked from doing it.

The two gates are not built the same way:

- **`armAlarm`** runs through `lib/requirePlan.js`, which carries a continuation (`onDone`) so that subscribing finishes the action that opened the paywall — the alarm the user was arming ends up armed, not handed back as a form to fill in twice. It is called from every place an alarm can be switched on: the Alarms list switches, the editor's Enabled switch, and Save in the editor.
- **`createCue`** goes through `lib/createCue.js` (`startCueCreation`), the only module allowed to open the composer, so no button can walk around the plan. It opens the paywall with the refusal's reason and **no continuation**: after subscribing the user lands back where they were and taps again.

Voices, soundtracks and lengths are **not gated**: choosing one writes nothing, so a lapsed account may edit a Reason freely, and the plan is enforced only at `createCue` and `armAlarm`. `createCue` is refused with "Resubscribe to add reasons" and `armAlarm` with "Resubscribe to set your alarms".

There is **no cap on how many Reasons** a Premium account may hold; the plan gates *whether* you can create one, never *how many* Reasons. The one number that is capped is **alarms: three (§4)**. Creation is gated by plan only, and is never enforced by deletion. Nothing a lapsed user made is removed. A lapsed account can open a Reason and pick new values (held, as always), but **cannot save them**: **Save Changes** opens the paywall (`can()` action `editCue`, "Resubscribe to edit reasons"), and subscribing saves what was held. Renaming, which has no Save, opens the paywall when the title is tapped. Nothing is changed until they resubscribe, so resubscribing is a pure resume (alarms and messages come back as they were); an edit saved on subscribing costs one credit when an alarm that is on plays the Reason. The alarm editor works the same way: a lapsed account may change anything there, but **Save** opens the paywall (whether the alarm is on or off) and subscribing saves it. Nothing about an alarm or a Reason can be saved without a plan; deleting stays free. Deleting someone's work to enforce a downgrade is never correct, and here it would also be unrecoverable: an alarm cannot exist without a Reason (§1), so removing Reasons would silently disarm alarms.

`can(action)` returns `{ok, reason}`, and `reason` is the exact string the paywall shows as its headline — gate logic and paywall copy come from one function, never duplicated.

Nothing in §5 is locked: all 8 voices, all 8 soundtracks, Short (30s/62w) and Standard (45s/100w) are selectable on any account.

---

## 4. Cost control — three alarms and one message per Reason

**Cost is bounded by the shape of the product, plus one quiet meter on what the person asks for.** A message costs a few cents to write and speak, and a person can only wake up once or twice a day, so the *refill* (§6) is bounded by how often anyone can wake up. What the shape cannot bound is the person changing things: a new Reason is free, so a cap per Reason restarts with every one. Those writes are bounded by one meter on the account (rule 3). Switching an alarm on simply works; the alarm card shows "Preparing your message" and then "Message ready" (§11.1). Free grants nothing.


**1. Only a live Reason writes.** A Reason is **live** when an *enabled* alarm points at it; nothing is ever prepared for any other Reason (§6). Creating Reasons stays unlimited and free.

**2. Three alarms** (`ALARM_SLOTS = 3` in `lib/entitlements.js`). The point is not the number. An alarm is a *place*, there are three, and what bounds cost is that at most three Reasons are ever live:

- **Slots count every alarm, on or off.** What is on the screen is what you have; the only way to a different alarm is to change or remove one.
- **One alarm, one Reason.** A different time on some days is *inside* the alarm (a schedule card per time, §11.1a), so a second alarm is never needed to play the same Reason at another time. Three alarms are therefore at most three live Reasons, with nothing to swap and no "which one goes off" question. The picker and the reducer enforce it (`alarmOfCue` in `lib/entitlements.js`).
- **Nobody is cut down to it.** The limit stops *adding*; accounts and demo data that already hold more keep everything running, and nothing is deleted to enforce a downgrade.
- **Snooze is the answer to falling back asleep**, not another alarm: the ring returns after the alarm's own snooze length, and the message plays once, on getting up (§11.1, §12).

**3. Credits — one meter per account** (`lib/fresh.js`). The one thing the person can do to make us write a message that never rings is to ask for one over and over: swap an alarm's Reason, edit a Reason, create and delete alarms and Reasons. Nothing tries to tell those apart from honest use. Every message the person asks for takes one from a single account-wide allowance, and the allowance is the cap:

- **One balance of 100 a month**, the trial included, where **a credit is one fresh message**. 100 is 90 (three alarms, a message per play) plus 10 for changes, so ordinary tweaking never takes a day from the end of the month. The messages the app writes by itself as plays come due (§6) spend from the same balance, one each, so a person is never charged for the daily promise out of a hidden second pot. **When it resets:** every 30 days from the start of the paid subscription, on every plan (Annual is billed yearly, but its credits still reset monthly). **The trial is the first days of the first month**: subscribing (with or without the trial) starts a month of 100 on day one, and the trial converting does not restart it, so 50 used in the first 10 days leaves 50 for the other 20. A resubscribe after a lapse starts a new full month, so somebody who has just paid never starts with an empty ring. What a trial could cost is bounded by the silent per-day ceiling below (about 18 over 3 days) and by Apple's one trial per Apple ID, not by a smaller allowance. Pack credits (`bonus`) are never reset and survive a lapse, so they are there again on resubscribing. **Placeholder:** the right figure depends on the real cost per message (about 1.6¢ on Inworld TTS-2 plus text, so a full 90 is about $1.60). A real build also holds a **silent per-day ceiling** on messages written per account (about 6), so the month cannot be spent in one sitting; it is never shown.
- **Spends one (cost 1, however many fields changed):** saving a new alarm that is on; moving an alarm to a different Reason; saving a change to a Reason's `purpose`, `why`, `style`, `voice` or `length` while an alarm that is on plays it; switching on an alarm whose Reason has no message yet (this is what closes "make an alarm off, switch it on"); switching on an alarm whose Reason was edited while the alarm was off, so the new wording is written now instead of being heard one ring late.
- **Free:** switching an alarm off and on once its message exists, its time, days, soundtrack and ring, a rename, a change of area, saving with nothing changed, editing a Reason no alarm plays (nothing is written; the alarm that later points at it pays), and making a Reason. **Deleting never refunds**, which is what closes create-and-delete. Edits are held until Save, so twenty changes and one Save cost one.
- **Running out is a state, not an error.** An alarm still saves and switches on. The alarm keeps ringing the message it has. If it has none, the alarm still rings and goes straight from the ring to the area's quote (the wake-up quote screen, not the daily thoughts), with no voice message at all, so nobody gets used to a generic line. The new message is written when the allowance returns, oldest ask first. The Reason is marked `pending` and writes nothing until then. **It is said where the person is looking, never silently, and never as a message that goes:** saving or switching on an alarm whose Reason has never had a message first shows a small sheet, **"This alarm won't speak yet"** / "You're out of credits. Until Nov 14, it rings with a quote instead." with **Get 20 credits · $2.99** (buys, then sets the alarm, and its message is written at once) and a quiet **Set it anyway** (sets it as it is); closing it changes nothing (`lib/noMessage.js`, `NoMessageSheet`). An alarm whose Reason already has a message is set without asking, since it keeps ringing that one. Once set, it skips the "Preparing your message" strip (nothing is being written, so it must not promise it) and its card says "New message from Nov 14" with an **Add credits** link that opens the credits sheet; a Reason edit that needs a new message at none is **not saved**: the line under Save Changes reads "Out of credits. This change needs 1 credit to save.", and Save opens the credits sheet with "Saving this change needs 1 credit. Until then, your alarm keeps its current message." The edit stays held on the screen; buying a pack there saves it and writes the message in one step, charging one credit for the whole change; closing the sheet changes nothing. **Nothing the person does is applied later behind their back**: an edit is either saved now with a credit, or not saved. Buying a pack, or the monthly reset, writes the first message for an alarm that is waiting on one (the card said so), and only for a Reason an enabled alarm plays; a waiting Reason nothing plays is not charged.

*How it shows.* The balance is the **credit ring**, and the user-facing word is **credits**. What one buys is a message.

- **The ring** (`CreditPill` / `UsageRing` in `components/CreditPill.jsx`) sits top-right on **My Reasons** and on a **Reason's own screen** (beside the "…" menu), for a subscriber only. No number and no glyph: orange, drained against the month's balance; a thin second half-ring in green once a pack has been bought (the month is spent first, so the orange half drains while the green waits full); a **grey ring with a small orange plus** at none (not red and not dashed: running out is a state, not an error, and the plus says the next move is to add more; it draws itself in once as the last credit goes). A short arc already says "low", so low is not a colour. It ticks when a credit is spent. Tapping always opens the credits sheet.
- **The credits sheet** (`CreditsSheet` in `components/sheets.jsx`, "Your credits") is two quiet lines and does not redraw the ring (the corner already is that picture). The subtitle says the one thing to learn: "1 credit = 1 new message". **Monthly** shows "99 / 100" over a hairline bar with "Resets Nov 14"; **Extra** shows its figure over its own bar with "Never expires". Both lines are always there, so the shape never moves. One extra line appears only when there is something to say: "Running low. New messages pause at zero." at 10 or fewer (a tenth of the balance, `nudgeAt`). At none there is no sentence: the zeros and the solid orange button say it. A full-width pack button whose weight follows need: a quiet outline while comfortable, a soft orange bar when low, the solid orange button at none.
- **Settings › Subscription** has a **Credits** row under Plan ("72 / 100", "+20" appended when there are extras; the credit glyph becomes the same grey ring with an orange plus at none) opening the same sheet, and one caption: "Credits reset Nov 14." / "Monthly credits reset Nov 14." (when there are extras) / at none "Alarms keep ringing. New messages wait for the reset." Hidden once Premium has ended.
- **The pack** is **+20 credits for a one-time $2.99, never expiring** (`PACK` in `lib/fresh.js`). It goes through the simulated App Store sheet as an In-App Purchase (`packItem`); on purchase anything waiting on the meter is written at once.
- **Nothing else shows it.** No badge on Save, no cost text in the editors and no toast with a count; the alarm card's "New message from Nov 14" line (above) is its only other trace. The reducer still charges by `alarmCost` / `cueEditCost` below; an alarm action with nothing left marks the Reason `pending`, and an edit with nothing left is refused (the screen opens the credits sheet first).

The same function decides what costs for the screens and the reducer (`alarmCost`, `cueEditCost`), so a badge can never disagree with what Save then does. The client copy is for the experience only; the real limit is on the server (BACKEND_ARCHITECTURE.md §6.1).

Helpers in `lib/entitlements.js`: `slotsUsed`, `slotsFree`, `canAddAlarm`, `canUseWithAlarm` (a Reason can be used with an alarm when a slot is free), and the one sentence `ALARM_LIMIT_NOTE` ("You can have up to 3 alarms."). The reducer refuses a fourth alarm; the real build enforces the same server-side.

**The limit is the shape of the screen, never an error.** Every doorway either shows an open place or shows nothing to press:

- **The Alarms tab is one screen for none, one, two and three alarms.** The title, the thought ring and the count never move; only the cards under them change, so deleting the last alarm never swaps the screen. It has no floating add button. **One add card** (`AddAlarm` in `components/AlarmSlots.jsx`) is the way to add, present while any place is free and absent when none is: with no alarms it is **the empty alarm**: a dark, dashed card about the size of a real alarm card, with one round orange plus button, "Set your first alarm" in bold and "Pick a time and a reason." under it. Orange fills only the plus. Because it is about an alarm card's size, saving the first alarm swaps like for like and nothing under it jumps. With one or two alarms it is a quiet dashed row, **"Add alarm"**, and nothing else. It is the shared `AddCard` (`components/AddCard.jsx`, also used by the Reasons tab, so the two tabs behave as one app) and a single component the whole way through, so deleting the last alarm morphs that card (it slides up, grows and takes its orange button) rather than replacing it. It draws no sample time, since a made-up alarm would read as one already set. There is deliberately nothing under it: onboarding's demo already played an ordinary alarm against Eala's, so a second sample here would repeat it, put sound on the home screen and need its own recording kept in step. The whole card is the button: no second "Add ›" link, no "N places left" (the meter already says it), no "another" (it makes no sense with none). **The meter** is on the right of the first list heading and is there in every state: "Your alarms · Up to 3" with none (which is how a new person learns the rule, before the first alarm exists), "Next alarm · 1 of 3" / "2 of 3" in between, and orange with a check, "3 of 3", when full — a finished state, not a refusal. There is no explanatory line under the card (it said what the card already says); the add card is never dimmed with the alarms when alarm access is off. **A full screen carries no sentence about the limit**. The meter is a button (an "i" beside it): it opens **"How alarms work"** (a name for screen readers only: on screen the page's own title is the one headline, with the close button on its row), four swipeable pages (or Next; the last page's button is "Got it", dots below), compact, each a title and one short line on top with a small moving picture under them: one picture that stays on screen and changes from page to page (the same three alarms, 6:30 AM, 12:30 PM and 9:00 PM, each with a switch): **Up to three alarms** (the three arrive and the last is switched off, dimmed in its place; "Switching one off keeps its place."), **One reason each** (a different reason slides into each alarm: Startup Mode, Training, Exam Prep; "Every alarm plays its own reason."), **Change any time** (the first alarm's reason turns into Family First and back; "Give any alarm a different reason."), **Free a place** (the second alarm slides left onto a bin and its place becomes a dashed "Add alarm"; "Swipe left to delete one. Its reason stays."). The sample reasons are never repeated, since one reason plays on one alarm. Each page is one idea and its picture shows exactly that idea. It explains and does nothing else — adding lives only in the add card, so there is one door. Removing an alarm reopens a place.
- **No alarms** is what somebody sees after deleting their last one (a new subscriber lands with one already made, see §11), so it is as plain as it can be, and it is the same screen as every other count (above), not a screen of its own. Nothing on it looks like an alarm that exists: a sample card would be made-up content that read as a thing already set. Somebody with no reason yet is taken through writing one from the alarm form, which returns with their time kept (`returnKey`). **It still ends on the Reason-ready screen**, with one button, **"Use with alarm"**, which carries the new Reason back to the half-made alarm: no "Save for later" (it is saved, and the alarm is waiting) and no jump straight from the last question to the form.
- **The Reason picker** ("What should wake you up?") shows only the alarm's own reason (first) and the reasons no alarm plays. **A reason another alarm uses is not shown at all**. With none free (every Reason already has an alarm, or none exist), the editor does not open the sheet: the Reason row and the footer button read "Add a reason" and go straight to writing a new one (§11), because a sheet with one button is a stop on the way. A new Reason is always free to make. (The sheet still says "Every reason already has an alarm." if it is ever opened in that state.)
- **Reason actions / detail / Reason-ready.** A Reason with an alarm offers "Edit its alarm"; one without offers "Use with an alarm" while a slot is free, and with none free the row is dimmed and locked (detail shows no status line, Reason-ready ends on Done).
- **The paywall states it** so the promise is never wider than the product: "3 alarms · Give each its own reason" in `BENEFITS`.

**How a Reason shows whether it is in use** (`UseBadge` / `CueEmblem` in `components/cards.jsx`). A Reasons-list row is **two lines for every reason** (name; area and tone) and one **badge on the corner of its icon** is the whole indicator: a **orange alarm-clock mark** when its alarm is on (the same mark as the Alarms tab, so the two connect without explanation), a **grey crossed-out alarm** when the alarm is off, and **nothing** when no alarm plays it. It sits on the icon so it can never collide with a long name and is always in the same place to scan; it springs in when it appears and changes colour rather than blinking when the alarm is switched. **The time is not on the row** — it lives on the Reason's own screen ("Reminder"), where there is room. Each row is spoken as "Startup Mode. Business, Focused tone. Played by your 6:30 AM alarm." / "Its 9:30 PM alarm is off." so nobody depends on colour. The **Reason picker** has no such indicator at all — it lists only the current reason and free ones, so one would be noise.

**Lapse and resume** touch nothing here: a lapse switches every alarm off (§10.1), and resubscribing switches back on the ones the lapse switched off.

## 5. Content options (fixed enums — mirror exactly, client and prompt both read from here)

**Focus areas** (10): `health` (sleep, diet, weight, chronic illness), `healing` (grief, sobriety, anxiety, hard times), `fitness`, `career`, `family`, `money`, `growth`, `business`, `study`, `relationships`. There is no free-text area: the focus is only a category, and anything specific is typed in `purpose`, which the writer treats as the source of truth. Choosing `healing` pre-selects the Calm tone (changeable). Each area has its own purpose starters, and `healing` has its own first-light and fallback lines — which must stay gentle, never urgent or upbeat-by-default.

**Tones** (5, none gated): `encourage` (Encouraging), `ground` (Calm), `focused`, `challenge`, `playful`. The picker pre-selects `encourage` (or `ground` for `healing`) until the user taps a tone, and `challenge` is not offered for `healing`. The id and the label differ for two of them — mirror the ids, not the labels.

**Voices** (8): `astra`, `lumen`, `beacon`, `dusk`, `vale`, `summit`, `ember`, `north`, all selectable on any plan (the `premium` flags in `data/mock.js` are unused). Each has a name, gender, accent, two traits and a group (Warm / Calm / Direct) in `VOICES` (`data/mock.js`).

**Soundtracks** (8, placeholder film/concert titles until our own are produced): `none`, `cornfield`, `time`, `experience`, `daylight`, `hoppipolla`, `free`, `rise`, all selectable on any plan. Soundtrack is mixed **at playback time on-device**, not baked into the rendered voice file — changing it must never trigger regeneration. It is stored **on the alarm, not the Reason** (§1); default for a new alarm is `cornfield`.

**Lengths** (2): `short` (30s, 62w), `standard` (45s, 100w, the default), both selectable on any plan.

---

## 6. The shelf — how "a new one every time" actually works

An alarm cannot wait on a network call at 6am. So audio is **always pre-rendered ahead of time** and cached; nothing is ever generated at fire time.

**Signature** = `voice | tone | length | purpose | userName`, plus `why` and `firstStep` when present (`signatureOf` in `lib/takes.js`). Soundtrack is excluded (see §5). A take records the signature it was written against, so a take can be asked whether it still agrees with the instruction (`takeIsCurrent`).

**An edit replaces the message.** After an edit to `purpose`, `why`, `style`, `voice` or `length` while an alarm that is on plays the Reason, the new message is written at once (one credit, §4) and replaces the one on the phone; with no credit left the edit is not saved (§4). With no alarm on, the edit lets the old message go and writes nothing; switching an alarm on later writes the first message from the new instruction (one credit). Outside an edit, a message is replaced only by the next one written after a play, and a message already on the phone is never deleted because an alarm was switched off.

**Every play owes a fresh message.** A message heard every day becomes furniture the brain files as noise, so each ring should be one nobody has heard. A Reason holds **one** message (`POOL = 1`): the one that plays next. After it plays it stays on the phone as what rings if its replacement has not arrived (a night with no connection, or no credits, replays it, never silence). Steps:

- **The first** is written when an alarm is first switched on for the Reason (paid for by the credit that action spends, §4).
- **After every play**, one new message is written and replaces the one just played. Each one spends a credit (§4). When no credit is left, nothing is written and the alarm keeps replaying the message it has until the monthly reset or a credit pack.
- **A monthly ceiling**: at most **31** written per Reason in any 30-day window (`MONTH_CAP`), a backstop for a misbehaving clock. A daily alarm needs 30.
- **Nothing is prepared** for a Reason with no enabled alarm — a Reason sitting unused in the library costs nothing to keep. Shelf depth is therefore 0 (no enabled alarm) or one (at least one).

A message that is already waiting is **never deleted** because the last alarm was removed or switched off; if an alarm points at the Reason again it plays that message with nothing new written. The trade-off of keeping one is that a night with no connection, or a month with no credits, repeats the same message (see "What rings"). That is accepted: it is also the nudge to buy a credit pack.

**Top-up job** (Cloud Function, triggered on: Reason created, alarm enabled/disabled, take consumed, and on a schedule e.g. daily):
1. For every live Reason, decide whether it is *owed* a message: it has none yet, or `due` was set when a play came due (every play owes one).
2. If owed and under the monthly ceiling, write **one** take and replace the Reason's current one with it. A take in the pool counts whatever signature it carries.
3. Write and bookkeeping (`seq`, `written`, `due`) land in one update, so there is never audio that has been rendered and not recorded.

The prototype runs this from one effect over the whole library after anything that could change what is coming — a Reason added, an alarm switched on or off, the name edited — and it settles in one pass.

**Consuming a take** (on wake dismissal, not on alarm ring; only the first dismissal of a calendar day consumes):
- The take that played stays as the Reason's only message until its replacement is written (it is the fallback). `plays` increases and the Reason is marked `due`: every play owes a fresh message. Whether it is written then depends on the account still having a credit and the Reason being under its monthly ceiling (§4).

*How the prototype models this.* It keeps one list of takes per Reason (the pool) plus `cue.message` and `cue.duration`, a mirror of whatever plays next that survives an empty pool. `topUp` writes the owed take and, with `POOL = 1`, replaces the previous one. There is no separate played flag, so a real build may store played state however suits it.

**What rings**, for every alarm on a Reason:
1. The take at the front of the pool.
2. Otherwise (the pool is empty, e.g. the first message has not arrived) the Reason's most recently played message, whatever voice or tone it was made in — no network needed.
3. Otherwise (the Reason has never had a message) the alarm still rings, and after the slide the wake flow skips the message and shows the quote (§12). No generic voice line is played. The alarm is never silent.
**Take duration is the spoken length only.** Never include the background bed's lead-in — one take can be played by two alarms with different beds (§1), so a duration that moved with the sound would be wrong for at least one of them.

**No "shuffle" / "show me another" feature.** One message per Reason; letting a user ask for another would spend credits and spoil the surprise. If someone dislikes a take, the fix is editing the Reason (§1) — or writing a new one and pointing the alarm at it.

**Variant counter (`seq`)**: monotonic, lives on the Reason, never derived from the shelf's current contents (the shelf is routinely emptied by consuming, and counting from what is left would restart at a variant already spoken). The local template writer also checks a new take against the one waiting and re-draws, up to six times, rather than ship two identical messages in a row.

---

## 7. AI generation pipeline

### 7.1 Request flow (server-side only — API keys never touch the client)

```
Reason created or shelf needs top-up
  → Cloud Function
    → moderate(purpose + why)          [reject before generation, see §8]
    → build prompt (see 7.2)
    → call LLM (OpenAI/Claude)
    → validate output (see 7.3)
        → fail: retry once → still fail: fall back to local template writer
    → moderate the OUTPUT too, not just the input
    → call ElevenLabs TTS on the validated text
        → fail: retry → still fail: write nothing, release the credit, retry later (an empty Reason rings, then shows the quote)
    → sanitize text before TTS call (strip markdown/artifacts the LLM validation might miss — TTS reads asterisks/symbols aloud)
    → upload audio to Storage, write take doc to Firestore
    → push/sync so the client can cache it locally
```

### 7.2 Prompt rules (hard constraints on the system prompt)

1. **Never quote the user's purpose back verbatim with attribution.** No "you said X matters to you." Reference the goal as something already known between narrator and listener.
2. **No greeting in the generated text** — one Reason can ring at 6am Monday and 9pm Thursday.
3. **No time-of-day language and no clock times** — no "this morning," "tonight," "the sun is up," no "6:30" or "seven o'clock." "Today" and "tomorrow" are fine. Same rule as #2, same reason.
4. Plain spoken prose only — no markdown, no lists, no emoji, no stage directions, no quotation marks.
5. Second person. User's name at most once, never in the first three words.
6. End on one concrete action, not a summary.
7. Never mention the app name, alarms, or snoozing.
9. **No wake-up language** — never "wake up," "get up," "get out of bed," "rise" or "open your eyes." The message is heard by someone who is already awake (it plays after the slide to get up), so it has nothing to say about the act of waking.
8. **Purpose is first-person from the user ("building my startup"), spoken by a third party** — flip pronouns (my→your, I→you) before the purpose text is ever placed into the prompt or the output, or the voice ends up saying "the next step toward building MY startup."
10. **Optional inputs are handed to the writer as context, not quoted.** The *why* is the emotional weight of the message, a *first step* (if one exists) is something to steer toward, and the *obstacle* (what usually gets in their way) is spoken to without being named (`buildPrompt` in `lib/prompt.js`).

### 7.3 Output validation (reject and retry if any of these hit)

- Empty / whitespace-only response.
- Starts with a banned greeting pattern ("good morning," "rise and shine," etc.).
- Matches a "quoted-back" pattern (regex: `you (said|told|mentioned)... matters/is your goal`).
- Contains a time-of-day term or a clock time from rule 3 above (`namesTimeOfDay`, `namesClockTime` in `lib/timeless.js`).
- Contains wake-up language from rule 9 (`namesWakeCommand`), or names alarms or snoozing (rule 7).
- Contains markdown syntax or a bullet/list marker.
- Word count outside 0.6×–1.5× of the target for the selected length.
- **Model refusal string** ("I can't help with that," "I'm not able to...") — this must never reach TTS.

One retry maximum, then fall back to the local template writer (deterministic, no API call) so the user is never shown a hard failure or dead air.

---

## 8. AI safety & abuse — the non-negotiable list

This app is unusual: AI output isn't read on-screen and approved, it's **voiced unattended** at the moment the user is least able to react (waking up). Treat every text input that reaches the LLM as hostile-until-proven-otherwise.

| Risk | Requirement |
|---|---|
| Sexual / hate / harassment / self-harm content in `purpose` or `why` | Run through a moderation endpoint (OpenAI Moderation, or equivalent) **before** generation. Hard block, no generation attempt, friendly rejection to user. |
| Gibberish / nonsense input | Heuristic + moderation low-confidence check → don't generate; fall back to a generic template rather than hallucinate meaning into noise. |
| Prompt injection ("ignore previous instructions...") | User input passed to the LLM as clearly-delimited, explicitly-untrusted data — never concatenated as if it were an instruction. Test adversarially before launch. |
| Non-English input | Either support it explicitly (matched voice + language-aware prompt) or detect and reject with a clear "English only for now" — never silently mis-generate. |
| Unbounded input length | Hard cap `purpose` at **180 characters**, enforced **client and server** (the server enforces it whatever the client sends). |
| Cost-abuse / scripted spam generation | Server-side rate limit on the generation endpoint, independent of any client-side limit (the three-alarm rule, §4, is a business rule a client can bypass; a rate limit is a cost-safety rule that must live server-side only). |
| PII in free-text fields | Decide retention policy explicitly — don't silently forward to analytics/logs without disclosure. |
| Output still unsafe despite safe input | Moderate the LLM's output too, not just the input — a "safe" prompt can still produce an unsafe completion. |

---

## 9. Storage architecture — cloud vs. on-device

**Cloud (Firestore + Storage) is source of truth for everything** — Reasons, alarms, entitlement, wake log.

**Must also be cached on-device, independent of connectivity, because an alarm cannot wait on a network call:**
- The audio file for the take waiting on each Reason's shelf, **and the Reason's last played take** (the replay fallback). Nothing older.
- The OS-level alarm registration itself (`UNUserNotificationCenter` / `AlarmManager` — these live in the OS regardless of Firestore state).
- A local mirror of the Reason/alarm list, so the app is fully usable offline once signed in.

**Storage never grows unbounded** — a Reason's one take is kept until its replacement is written, then deleted (client deletes the local file; Cloud Function deletes the Storage object, with a lifecycle rule of ~2 days as a backstop for orphans). Briefly there are two files per Reason (the one that played and its replacement); at rest there is one. There is no "replay history" feature. Keep the **text transcript** in `wakeLog` for account records. The privacy policy must say this (the most recent message per Reason is retained until replaced).

**Sizing**: one file per Reason; typically a handful account-wide at ~250–500KB each ≈ a few MB resident. Not a real constraint — design for lifecycle correctness, not for size.

**Playing makes zero network calls** — an alarm replays what is already cached locally, so a device that is offline rings exactly as it would online; this is the most offline-resilient path in the app, not the least.

---

## 10. Payments (StoreKit / Google Play Billing)

- **Never trust a client "purchase succeeded" callback alone.** Validate the receipt / purchase token server-side (App Store Server API / Play Developer API) before writing `entitlement.plan = "premium"`.
- **Server notifications (webhooks) drive entitlement state**, not just the initial purchase event — renewals, cancellations, billing-retry/grace-period, and refunds all arrive independently of whether the app is open. `entitlement` should be a value the client *reads*, computed server-side, not something the client sets directly on purchase.
- **Restore Purchases is required** for App Store approval — must be implemented, not optional.
- **Plan switch is not a fresh subscribe.** Both plans are one App Store subscription group with **Annual one level above Monthly**. So Monthly → Annual is an upgrade: it starts at once and Apple refunds the unused part of the month, and the app offers it in-app (Settings › Subscription, §14.3). Annual → Monthly is a downgrade that starts at the next renewal, and the app never offers it: it is reachable only through Apple's own "See All Plans" behind Manage in App Store.
- Handle: Family Sharing, promo codes, Ask-to-Buy (App Store); account holds/pending purchases (Play).

**Pricing**: Annual $79.99/yr ($1.54/week equivalent, badge "Save 33%", 3-day free trial in onboarding), Monthly $9.99/month (shown as $2.31/week; no trial). The one-time offer is Annual at $47.99/yr ($0.92/week, 40% off, same trial), shown only in onboarding (§11). Both plans include the same thing — unlimited Reasons, three alarms (§4), every voice, soundtrack and length; the percentage is derived from the two prices, never typed.

**Where the trial is offered.** Only in onboarding (§11): on the onboarding paywall's Annual plan ("Start 3-day free trial", with "3 days free, then $79.99 a year" under it; its App Store sheet carries two priced lines, "3 days free · Starting today" and "$79.99 per year · Starting {date}") and on the one-time offer ($47.99 a year, the same trial). Monthly is "Start Monthly" with "$9.99 a month, charged today". The in-app paywall (`screens/Paywall.jsx`, opened from a gate, the Alarms "Renew" line or Settings) never offers a trial: it is the resubscribe route, and this person already had one. It is onboarding's paywall in the app: the same night, the same two plan cards (`PlanCards`, led by the price per week, "Save 33%" centred on the Annual card) and the list of what Premium contains (`BENEFITS`). Close and Restore at the top; "Pick up *where you left off*." as the headline; "Start Annual" / "Start Monthly" with "$79.99 a year, charged today · Cancel any time" / "$9.99 a month, charged today · Cancel any time" under it. While signed out it asks for an account first (§11.2). Moving from Monthly to Annual is on the Subscription screen (§14.3).

**What is sold.** One subscription (Annual or Monthly), the onboarding-only offer product (Annual at $47.99, same group), and the credit pack (+20 credits, $2.99, a one-time In-App Purchase, §4). A lapsed account is shown the subscription (the paywall, §10.1); an active or trialing account is shown no subscription offer.

### 10.1 Trial cancellation and lapse

The most common paid-funnel path there is: subscribe with the 3-day trial, cancel on day 1, keep access to day 3. The store handles the access window — what this section defines is **what the app becomes on day 4**, because that is the state the user actually lives in afterwards and the one the product has no second chance to get right.

**Entitlement state to track.** `plan` alone cannot express this, so `users/{uid}/entitlement` (§2) carries:

```
status: "trialing" | "active" | "grace" | "expired"
trialEnd: timestamp | null
willRenew: bool              // false the moment a cancellation webhook lands
```

`willRenew: false` while `status === "trialing"` is the cancelled-but-still-inside-the-trial state. It changes **nothing** about what the app allows — access runs to `trialEnd`, exactly as the store promised on the confirmation sheet. It is only read by the UI (see "What the app says", below).

**On lapse** (`trialEnd` passes with `willRenew: false`, or a subscription expires): a server-side webhook sets `status: "expired"` and `plan: "free"`. Nothing else is written. Specifically, **the lapse job never touches `cues`, `alarms`, or any take on a shelf.**

**The governing rule: disarm, don't delete, don't lock out.** On lapse every *enabled* alarm is switched off, and that is the only thing about the user's own data that a lapse changes.

| | During trial | After lapse |
|---|---|---|
| Enabled alarms | ring | **switched off** — time, days and Reason all preserved |
| Reasons, alarms, settings | live | **kept untouched**, fully browsable |
| Deleting, signing out, export, close account | available | **still available** |
| Creating a Reason / arming an alarm | available | **paywall** |

**Why off rather than left ringing.** An enabled alarm is a standing instruction to keep writing and speaking fresh messages — the one thing in this app that costs money. Leaving them armed with no plan behind them promises audio nothing will pay to render, and an alarm that rings into silence is worse than one that was honestly switched off. Off rather than deleted, so resubscribing is a switch flipped back rather than a morning rebuilt from memory. `enabledAt` is left alone: it records when the *user* last armed it.

**Nothing is deleted on lapse.** The webhook writes `status: "expired"`, `plan: "free"` and `enabled: false` on armed alarms — never a Reason, never an alarm row, never a setting.

**What the app says, and when.**

1. **On cancel, inside the trial** (`willRenew: false`, still `trialing`): nothing is taken away — access runs to `trialEnd` exactly as the store's confirmation sheet promised. One calm line on Settings, nothing modal: "Your alarms and Premium access continue until [date]." (Plan row: "Premium · Ends [date]".) Said before it happens rather than discovered on the morning it does. No win-back offer: they decided ten seconds ago, and arguing with a decision that fresh earns a deletion rather than a resubscribe.
   The Plan row reads "Premium · Ends [date]"; the Plan sheet subtitle reads "Premium ends [date]" (never "renews").
2. **After lapse**: the profile badge is gone and Settings shows the same slim "Premium has ended · Renew" line as Alarms (`components/RenewBar.jsx`), and nothing is repeated under the Subscription group The Alarms screen shows one slim, tappable line above the dimmed alarms: a small crown, "Premium has ended" and an orange "Renew ›", opening the paywall. Reason edits cannot be saved (Save opens the paywall); alarm edits cannot be saved either (Save opens the paywall).
3. **At the gates**: the paywall, as an answer to something they just tried to do, never a nag. (`can()` returns its reason, "Resubscribe to set your alarms"; the paywall does not print it, because its headline already says it.)

**Paywall copy must not compare against Free.** Free grants nothing (`TIERS.free.cues = 0`), so a comparison would only make the product sound withheld. State what the plan contains, full stop.

**Resubscribing is a resume, not a fresh start**, except for credits, which start a full month (§4). `plan: "premium"`, `status: "active"`, and the alarms the lapse switched off are switched back on (it marks them `pausedByLapse`, so an alarm the person had off already stays off; each is billed as switching it on would be); the pools refill themselves from the Reasons that were sitting there the whole time. No trial is offered — this person already had one. The app should say so in one line rather than welcome them as a new user.

**Edge cases this must survive:**
- Refund of the annual after the trial converts → same lapse path, immediately, no grace.
- Cancel and resubscribe inside the same trial window → one trial, not two.
- Lapse while offline → the client must reach the lapsed state from the cached entitlement on next open, with no network needed to do it: the alarms are switched off locally. A lapsed phone does not ring, offline or otherwise — that is the lapse working, not failing.
- Lapse mid-composer → the draft is not discarded; it saves, and the shelf simply does not fill.

### 10.2 Payment failure (billing retry / grace period)

A renewal charge can fail while the store still grants access. **The store's entitlement status decides when access ends, never the first failed charge.**

- **Grace / billing retry active** (`status: "grace"`): behaves exactly as active Premium — alarms stay on and every gate is unchanged. The only difference is copy: a slim, non-blocking pill in the ember tone, shaped like the "Premium has ended" line (`RenewBar`): "Payment issue" with **Update ›**. It shows at the top of Settings, directly under the profile card, **and at the top of the Alarms tab**, so a user who never opens Settings still sees it. **Update** deep-links to the store's payment-method screen (screen readers hear "Update your payment method to keep Premium active."). The prototype's subscription state reads "Payment issue". A second notification, "Payment still failing" (§11.0b), goes out a day or two before the grace period ends, because the lapse switches every alarm off; it is not sent if the payment has recovered.
- **Recovered** (store notifies a successful charge): `status: "active"`, card disappears, nothing else changes.
- **Grace ends, still unpaid**: treated exactly as a lapse (§10.1) — a webhook sets `status: "expired"`, `plan: "free"`; alarms switch off, generation stops, Reasons/alarms/data are kept, "Premium ended" shows, and resubscribing resumes.

Server notifications (`DID_FAIL_TO_RENEW`, `GRACE_PERIOD_EXPIRED`, `DID_RENEW` on iOS; equivalents on Google Play) drive these transitions; the client only mirrors the stored status.

---

## 11. Onboarding flow

**One job: take the person from curiosity to understanding what Eala is, hearing it, and subscribing knowing exactly what they are buying.**

```
Splash (black; an ordinary grey alarm clock rings once and becomes Eala's "e": its hands sweep round and let go, the parts of the face outside the e fade to black as the rest turns white, the bells warm to orange; no blur. About 3 s on first launch, under 2 s after; a tap skips)
→ WELCOME: full bleed, real people getting up for something (a run, a child at sunrise, a quiet window, a sunrise met), each drifting slowly in for about 5 s and crossfading to the next, falling into black at the foot. No logo (the splash has just shown it); over the photos, "Wake up for" small and soft grey and, under it, large in the accent, what that photo is getting up for ("the finish line.", "the ones you love.", "yourself.", "the life you want."), rolling over with each photo; Get Started (or "Pick up where you left off" / "Start over" when a draft exists), with "Already have an account? **Sign in**" under it. Only the photos and that one phrase move; the button never does. **The photos are Unsplash placeholders linked from images.unsplash.com (`PHOTOS` in `Hook.jsx`) and must be replaced with licensed or commissioned photos before release.**
→ AREAS: "What do you want to *wake up for*?" / "Pick one for now. You can add more later." All ten areas as tiles; choosing one tints the sky and shows "Eala might say" with that area's line (`AREA_LINE`) → Continue
→ OBSTACLE: "After your alarm rings, what *usually happens*?" five cards: I keep hitting snooze · I reach for my phone · My mind starts racing · It's hard to get going · I get going fine. The answer is said back under the list as "What you'll hear" (`OBSTACLE.options[].reflect`) → Continue
→ FEEL: "When your alarm rings, what would *help most*?" five cards, one per tone: A reminder of why (Encouraging) · Something calm (Calm) · A clear next step (Focused) · A push (Challenge; not offered for Healing) · A little lightness (Playful). The chosen card shows an example line for their area under the list → Continue
→ INSIGHT: one published finding about their obstacle as a large counting figure with its source, an orange hairline acting it out, then "So your Eala will" and three ticked rows, one per answer (the area, the obstacle, the tone) → Continue (appears once it has all landed; a tap shows it at once)
→ COMPARE: "Tell me if this *sounds familiar*." then "First, how most days start. Then, how they could."; "Best with sound on" and **Show me** (the tap that lets audio play)
→ THE DEMO (below) → "See how it works"
→ HOW IT WORKS: "Written for you. *New every time.*" three looping, tappable beats: You tell Eala your goal / You pick who says it ("Eight voices to choose from.") / It's new every time → Continue
→ GOAL: "What are you *working toward*?" written large on the page (type or speak; starters while empty) → Continue
→ VOICES: "Who should *say it*?" / "Tap a face to choose. You can change it any time." All eight voices as a list (portrait, name, traits), a tap chooses, each row has its own play button for a sample → Continue
→ WHY (optional): "Why does it *matter to you*?" with their goal shown above it, written on the page like the goal (microphone, starters while empty); "Skip for now" while empty, Continue once there are words; a why too short to use keeps Continue off with "A few more words, or clear it to skip."
→ TONE: "How should it *sound*?" a letter holding a line in the chosen tone for their area, and the five tones (four for Healing) as dials under it → Continue
→ NAME (required): "What should Eala *call you*?" Continue stays disabled until the name is valid; on Continue the screen shows a greeting in their name by the time of day ("Good morning, Maya") and moves on by itself
→ WHEN: "When should Eala *find you*?" time wheel and days ("Pick at least one day" with none), with "Eala finds you in" and a live countdown → Continue
→ ALLOW: "Let Eala *ring*." / "Allow alarms so it rings on time, even when the app is closed." Their alarm on a locked phone and the system's own question drawn as OS chrome → Allow alarms (a decline continues)
→ NOTIFY: "Hear from Eala *between alarms*." / "A reminder before you're ever charged, and a thought for your day." One notification on a soft glow, drawn as the phone draws it, with a second resting behind it as iOS stacks them; the two trade places in a slow crossfade (Today's thought with a line for their area; "Your free trial ends tomorrow") → **Turn on notifications** (the system's question drawn as OS chrome; either answer shows its state, then Continue) or **Not now** (moves on without asking, keeping the one-time system question unspent). Allowed: "We'll be *brief*." and the glow warms; allowing also turns on Today's thought (`prefs.notify.quotes`, switched off in Settings). Declined: "No notifications." / "Your alarms ring either way." Alarms are never affected by this answer
→ MANIFESTO: "Why Eala exists", four lines arriving in one sweep, signed "The people who make Eala" (placeholder copy) → Continue
→ PROOF: "In their *own words*." one voice at a time, as on the landing page: five stars, the quote set large in light italic arriving word by word out of a soft blur with its last three words in orange, the name and area, then a row of five faces; the one speaking is lit inside an orange ring that fills over 6 s, then the next speaks (looping). The one in the person's area speaks first; tap a face or swipe the quote → Continue
→ PAYWALL (required) → [ONE-TIME OFFER, if they close the App Store sheet] → ACCOUNT (only if not signed in when the purchase began; Skip) → ALL SET → Take me in → the app
```

The order is `SCRIPT` in `screens/Onboarding.jsx` (the hook comes before it and is its own screen); copy is in `data/onboarding.js`; the screens are in `screens/onboarding/` (one file each). The soundtrack (default `cornfield`, changed on the alarm), the length (Standard) and the first step are not asked.

**Visual identity** (`screens/onboarding/ob.css`, scoped to `.ob5`, with `.theme-ob-dark` and `.ob5--ios`). Onboarding is drawn like the rest of the app (Appearance, §14.2): true black, SF Pro for headlines and UI, white text with iOS greys, solid grey cards (`#1C1C1E`), and orange (`#FF9A3C`) as the one accent, flat, on the emphasised words (written `*like this*` in the copy), selections and the primary button (orange with black text). Headlines are bold sans, not serif or italic. Two pieces live in `Onboarding.jsx`, outside the screens, so they carry across steps: **the horizon** (`Horizon`: one hairline across the top whose orange light advances to the paywall; it is the progress indicator and the back control, with no dots or step counts) and `Atmosphere`, which under `.ob5--ios` draws plain black (no sky glow, tint or grain). The demo, the paywall, the offer, the account step and the last screen are full bleed and have no horizon. Screens cross with a short slide and blur in the direction of travel; reduced motion makes every crossing a fade and shows text whole. Headings sit top-left; the footer button sits in the thumb zone.

**Copy economy.** One headline per screen and at most one short line; examples, starters and pictures stand in for explanation. The paywall states plans, trial, billing and cancellation on screen.

**Rules.** Every question has a use in the product and shows up within a minute: the area tints the sky and chooses Eala's lines, the examples and the demo; the obstacle is said back, shapes the Insight screen and the demo's closing line, and goes into the message prompt; the tone shows an example and writes the messages; the goal, why, voice and name make the Reason. No "morning" or "first minute" in what the person reads (the Name greeting reads the clock and is the one exception). Example content is labelled as an example. Nothing says an alarm exists or is set until it has been made. **Onboarding never writes, shows or plays the person's own message**: the demo's example for their area is the only message heard, and their first message is their first real alarm. (`MessagePreview.jsx` exists but is not in `SCRIPT`.)

**Placeholders that must be replaced before release.** The Manifesto lines are placeholder copy for the founders to write and sign. The Proof testimonials (`TESTIMONIALS`: Maya R., Daniel K., Sofia M., Marcus T., Elena V., with photos and five stars) are placeholders: before release they must be real customers' words with their permission, or the screen removed. The Insight figures are real published findings with their sources on screen (`INSIGHT.facts`, checked 2026-10-21); keep them only as cited.

**The demo** (`Preview.jsx`) sells what the snooze button does, and what Eala makes of it. It writes nothing to the store. On a locked phone iOS draws every alarm, Eala's included (§12), so the screen cannot be the difference; the big button the thumb finds half asleep can. On every alarm it is Snooze; on Eala's it plays your reason.

1. **The habit**: the phone's own ring and the classic four-beep tone. Only Snooze works at first: "Hit snooze, like always." ("You said you hit snooze. Go on." if that was their obstacle). Each press darkens the screen, runs 9 minutes off the clock in about a second ("9 more minutes") and rings again: "Just a few more minutes.", "One more.". After the third (6:57 for a 6:30 alarm), Snooze is drawn only and the slider works: "Now get up." → slide to stop.
2. **What it cost**: black, three lines arriving one by one: "27 minutes." / "Spent hiding from your day." / "What if they reminded you of *what you're working toward*?" Nothing moves on by itself; **Show me** appears once the lines have landed.
3. **The button's turn**: out of the black, only the orange Snooze button, in the place it always sits: "Every alarm has this button." (small, grey, word by word). Then the button takes a breath, a band of light crosses it and its label rolls into **Hear your reason**, while the grey line steps back and "Eala turns it into *your reason*." arrives large, word by word. Then the alarm rises back round it at the original time, titled with their area's suggested Reason name, ringing, with "Tap it" over the button. Only the button works, and Eala opens straight into the message (the demo skips Face ID). Reduced motion shows the ringing screen at once.
4. **The message**: the app's reminder screen playing about 22 seconds of an example for their area (a real recording with music for Business and Relationships, simulated elsewhere).
5. **The quote**: the app's quote screen with one line they just heard (`DEMO_QUOTE`) and Start My Day (no Replay message in the demo).
6. **The close**: the hook, answered. Black, no picture: "Your alarm says when." (grey) / "Eala says *why*." / "The first thing you hear, before the rest of the day gets to you." → See how it works.

A back arrow stays in the corner.

**The paywall** (`screens/onboarding/Paywall.jsx`). A back arrow and Restore at the top; the headline "Let Eala find you at *{time}*."; then, for **Annual**, the trial as a vertical timeline: **Today** · Everything unlocks · "A new message every time your alarm rings, in a voice you choose." → **Day 2** · We remind you · "A notification the day before you're charged." → **Day 3** · Your plan begins · "Cancel before and pay nothing."; for **Monthly**, the list of what Premium contains (`BENEFITS` in `lib/benefits.js`: a new message every time, up to 100 a month; built from your goal; pick the voice and tone, from 8 voices; 3 alarms). Pinned at the foot: the two plan cards (`PlanCards` in `kit.jsx`: Annual preselected, each led by its price per week, "$1.54 /week" and "$2.31 /week", with a "Save 33%" badge centred on the Annual card's top edge), the orange button ("Start 3-day free trial" / "Start Monthly") and one line under it ("3 days free, then $79.99 a year · Cancel any time" / "$9.99 a month, charged today · Cancel any time"). There is no skip and no countdown.

**The one-time offer** (`screens/onboarding/Offer.jsx`). Closing the App Store sheet on the onboarding paywall opens it, once per onboarding (`offer` / `offerSeen` in the draft). It sells Annual at **40% off: $47.99 a year** (`OFFER` in `lib/plans.js`; the percentage and the weekly price are derived), with the same 3-day trial, renewing at $47.99. A real build sells it as its own App Store product in the same subscription group. From the top: an ✕ (back to the paywall; the only way out); the price drop, animated once: "$79.99" appears large, an orange line strikes it and it steps back, "$47.99 /year" counts down into its place in orange italic, a "−40%" stamp lands beside it, and a pill with an orange light running round its edge reads "Just **$0.92** a week"; then "A one-time offer", "Before you go, *a better price*.", "Everything you just saw, for less." and three ticked lines (Still 3 days free · Your price never goes up · Cancel anytime). At the foot: "Only on this screen. Once you leave, it's gone." beside a pulsing orange dot, **Claim 40% off**, and "3 days free, then $47.99 a year". Claiming opens the App Store sheet with "3 days free · Starting today" and "$47.99 per year · Starting {date}"; closing that sheet leaves them on the offer. There is no timer: what is limited is that the screen is shown once. With reduced motion the price drop shows its final state. **Prototype only:** the App Store sheet on the onboarding paywall carries a second side button on its left edge, "Double Click to See Offer", opposite "Double Click to Subscribe" on the right, which opens the offer every time; remove it (`payment.onOffer` in `PaymentSheet.jsx`) before release.

**The last screen** (`FirstMessage.jsx`). After the purchase (and the account step, if any), one screen makes the Reason and the alarm from everything they said, through the normal reducer paths: the Reason (area, goal, why, obstacle, tone, voice, Standard length, the area's suggested name) and an alarm (their time and days, on, snooze 9 minutes, the default soundtrack and ring). An orange check draws itself; "You're all set, {name}."; "Eala will find you {Monday at 6:30 AM}." (or, if alarms were declined, "Your alarm is saved. It stays quiet until you allow alarms in Settings."); a card with the area, the goal, the why (when there is one), the voice and the tone; then **Take me in**, which dissolves into the Alarms tab on the same sky (`lib/handoff.js`). Nothing is played here: the Reason's first message is written once the alarm is on (one credit, §6) and is first heard when the alarm rings. The creation happens once: the ids of what it made are kept in the draft (`made`), so a remount, a reload or a killed app on this screen finds its own Reason and alarm instead of making a second pair.

**A draft survives quitting.** Every step is saved on the device as it is answered (`eala.onboarding.draft.v5`; versioned, and a draft with an unknown step is ignored). Before the purchase the hook offers **"Pick up where you left off"** with "Start over". After it, a subscriber who quits on the account step or the last screen is taken straight back there on the next open, with no hook and no paywall; a subscriber with no such draft (it expired, or the plan came back by signing in) goes straight into the app. A draft past the paywall is never offered to somebody without a subscription, so nothing is made unpaid. It is dropped on finishing and after 14 days, and it stays on the device.

- **Pay first, identity after.** The payment sheet is the very next thing after a price is tapped. "Needs an account" is decided **once, when the purchase begins** (`needsAccount`), and never re-evaluated, so the step list cannot reflow under the open payment sheet.
- **The account step can be skipped.** "Keep your Eala *safe*." / "Sign in so your reasons and plan follow you to any phone." offers Apple and Google, with "Sign in later? **Skip**".
- **Name is required**: Continue is disabled until it is valid, and there is no Skip. It is saved to the account after the purchase and used to address them in each message (§1). Validation: 2 to 24 chars, letters plus space, hyphen and apostrophe, sanitised on input (`lib/name.js`).
- The profile written to `state.onboarding` keeps the time and days (the first alarm's preset, read by `alarmPreset`) and the answers that enter the product (area, obstacle, tone, voice).
- **Known gaps before the real build:** `firstStep` is in §1, `lib/takes.js` and `lib/prompt.js`, but no screen sets it, and `validate()` does not check that it appears. `obstacle` is stored on the Reason and sent in `buildPrompt` but is not editable on Reason detail. Voice samples, example audio for all but two areas, and soundtrack samples are simulated; a real build plays one short pre-rendered line per voice and a clip per track.
- **Trial eligibility.** Apple grants one free trial per Apple ID per subscription group. The real build must check introductory-offer eligibility (StoreKit / RevenueCat) before showing the trial: an ineligible person sees the paywall and the offer without the trial timeline and without "3 days free", or they would be charged at once under a promise of a free trial.

**Demo shortcut (every build).** A small "Skip onboarding (demo)" link, drawn outside the phone frame while the first onboarding screen shows, signs in as Alex with an annual Premium plan (no trial), completes onboarding and lands on Home. It bypasses the paywall and must be removed (the `onDevSkip` prop in `Onboarding.jsx`) before a real release.

**Reason composer — onboarding's own screens** (`CueComposer.jsx`). Making a Reason in the app uses onboarding's screens, words and order (`screens/onboarding/`: Areas → Goal → Voices → Why → Tone), so the second Reason feels like the first; what sells (obstacle, insight, demo, how it works, name, manifesto, proof, paywall) is left out. It is drawn like onboarding (black, §11 Visual identity), with its horizon line for progress and back (back on the first screen leaves). Area is skipped when one is already chosen (e.g. from a library row). **Goal** is required (12-character / two-word floor, 180 cap, starters, dictation); **Why** is optional ("Skip for now" while empty); **Voices** is the eight-voice list with a sample per row; **Tone** is onboarding's letter and dials plus a **Length** choice (Short / Standard) under them, which onboarding does not ask, and its button, **Create Reason**, saves. Tone and voice follow the area until chosen (Calm for Healing, which hides Challenge). There are no Premium locks here: only a subscriber can open the composer (§3). The name is suggested from the area ("…" plus a number if taken) and edited on the Reason-ready screen. The soundtrack is set on the alarm (§1). Saving writes the Reason with an empty shelf; nothing is written for it until an enabled alarm points at it (§6). The why is stored on the Reason, editable like every other field (§1), joins the take signature only when present, and is spoken back in the second person without attribution (never "you said").

**Editing a Reason** (Reason detail). Every row is a tap target with a chevron: **Area of life**, **Purpose**, **Why it matters** ("Add" in orange when empty), **Tone**, **Voice**, **Length** (the name is edited in the title and, because a rename rewrites nothing, still saves on its own). Each opens its own sheet; a choice there is **held, not saved**: the row turns orange (and is spoken as "Changed, not saved"), and a **Save Changes / Discard** bar rises from the foot with one line under it (below). People change several things at once, and each tap is a step in one change, not a final answer, so nothing lands until Save: one commit, one new message. Save shows no message: the Save bar going away and the orange on the changed rows clearing is the answer. Leaving with unsaved changes asks "Discard changes? — This reason stays as it is now." The Purpose and Why sheets are one component with starters, a microphone and a character counter; Why may be cleared ("Remove"). Voice and Length are not locked. A lapsed account can open every sheet and hold changes, but Save Changes (and the title, for a rename) opens the paywall, and subscribing saves what was held (§3).

**When the new words are written.** A change reaches the next message *written*. With an alarm on, that message is written at Save, so the next ring already plays the new wording; with none on, the old message is let go and the first new one is written when an alarm is switched on. The screen says it once: the line under **Save Changes** reads **"Changes will apply from your next new message."** in every case. There is no banner at the top: one sentence, in the one place the person is looking when they decide. A changed field is shown by its **value turning orange**, not by repainting the row. Out of credits, an edit that needs a new message reads "Out of credits. This change needs 1 credit to save." instead, and Save opens the credits sheet (§4).

**The Reason-ready screen** (`CueCreate.jsx`) is onboarding's last screen (`FirstMessage`) without the alarm line, always dark like the composer: an orange seal with a check, "Your reason is *ready*.", and a card holding the reason — the area (icon and label, in its colour), the **name** as the card's title (tappable, with a pencil — it is how the Reason is filed in the list), the goal (clamped at three lines) and the why under it, then two cells, Voice (portrait and name) and Tone. No "Eala will find you…" line, because no alarm plays it yet, and no play control: nothing is written until an alarm points at the Reason. Then **Use with alarm** / "Save for later" (the Reason is saved either way; **Done** when all three alarm places are taken). A Reason created from inside the alarm editor ends here too, with one button, **Use with alarm**, which hands it back to the alarm draft, so the time and days are never lost.

---

## 11.0 The first look around

**Once, on arriving in the app, four stops on the Alarms tab** (`components/AppTour.jsx`). Onboarding sold the idea; the first screen after it holds four things at once and none is labelled in words a newcomer already has, so each is lit in turn through a soft dark veil, with a title and one line on a small card beside it:

1. **Your alarm** (the next-alarm card): "Tap it to change the time or what it plays. Each time it rings, you hear a new message." With no alarm, the add card instead: **Your first alarm**, "Tap here to set one. …"
2. **Up to three alarms** (the meter): "Each one plays its own reason. Tap here any time to see how it works."
3. **Three thoughts a day** (the thought ring): "Short lines for what you're working on, new every day. Tap the ring to read them."
4. **Your reasons** (the Reasons tab in the dock): "What your alarms talk about. Change the goal, voice or tone any time."

**How it behaves.** It starts about 1.4 s after the Alarms tab settles, only with nothing over it (no sheet, screen, dialog, ring or payment); anything that covers the tab puts it away and it comes back from the start once the tab is clear. The tab scrolls to the top first. The light glides between stops (one cut-out that moves and reshapes, with a thin orange edge breathing slowly), and the card sits under the target in the top half of the screen and over it in the bottom half, with a notch pointing at it. Progress is dots (the current one long and orange), not a count. **Next** / **Got it** on the card; a tap anywhere else also moves on, and **never acts on what is lit**: the tour shows, and doing things is for after. **Skip** is on every stop but the last; Escape skips, the arrow keys move. A stop whose target is not on screen is left out, decided once when it starts, so the dots never change count. Reduce motion makes the light jump and the words fade.

**Once.** `prefs.tourSeen`, set by Got it or Skip and by nothing else. The thought ring's own note (§11.0a) and the swipe hint (§11.1) wait until it is set, so two lessons never stack, and finishing it marks the ring's note seen (the tour has said what the ring is). Settings › Prototype › App tour replays it. The copy follows the screen vocabulary: "message", never take or shelf, and no time of day.

**The Reasons tab gets two stops of its own**, the first time it is opened after the Alarms tour (`REASONS_TOUR`, `prefs.reasonsTourSeen`, about 0.7 s after the tab settles). The tour never switches tabs itself: it explains the screen the person chose to open. Only two things there cannot be read without being told, so there are two stops, and each card carries a small live picture instead of a longer sentence:

1. **Your credits** (the credit ring, round light): "The ring empties as you use them and fills again each month. Tap it any time to see what's left." Under it, a miniature ring that gives up a sliver with a "−1" rising off it, beside "1 credit = 1 new message" (the credits sheet's own line, §4).
2. **Playing on an alarm** (the icon of a reason an alarm plays, the one whose alarm is on if there is one): "The mark on a reason says whether an alarm plays it." Under it, the three states side by side, arriving one after another: the orange mark "Alarm on", the crossed-out mark "Alarm off", a dashed empty ring "No alarm".

"New Reason" is not a stop: a dashed card with a plus already says what it does. A lapsed account has no ring and may have no marks; a stop that is missing is left out, and with nothing at all to point at the tour is put away without being marked seen. Settings › Prototype › Reasons tour replays it.

## 11.0a Today's quotes

**Three thoughts a day, not a feed.** Eala is an alarm, and a person can have three of them, so there are three thoughts a day; this is a quiet moment beside it. Tapping the entry opens **three** full-screen cards side by side, each with a heart, a share arrow and a close button, a sideways swipe between them and three dots at the top (no numbers, each tappable), and, the first time only, a nudge: after the words land the card slides a few pixels toward the next and eases back (`prefs.quotesNudged`), so nothing has to say "swipe". It opens on the first one not yet read. It opens from a notification (each carries one of the lines) or from **Thoughts for today**, a ring at the top right of the Alarms tab (`components/ThoughtRing.jsx`). The ring shows no words: the words are the reward for opening it, and a control of fixed size cannot break on a long quote or pass for a caption. Inside it is today's painting (`SceneArt`, still), the one the thought opens on, so the thought opens out of the ring (a fade and slight scale from the top right, `rise` in `App.jsx`) and closes back into it. A small quote mark on its corner says what it is. The ring is **three arcs, one per thought**: orange until it has been read (being on its card is reading it, `prefs.quotesRead = { day, ids }`), grey after, with a soft glow and an orange quote badge until all three are read; the picture is the next unread one. Tomorrow's three bring the orange back. There is no number, no streak and no badge count. It never dims with the alarms when alarm access is off, and it is the same size in every state and in every screen state (no alarms, none switched on, three). It has no label, so it teaches itself once: the first time it is unread, a short note under it, "Your thoughts for today", fades in, then goes after a few seconds or on the first tap, and never returns (`prefs.thoughtHintSeen`). The dock has three tabs (Alarms, Reasons, Settings); `tab: 'quotes'` in a saved state is read as Alarms.

**The count of alarms** is the meter ("● ● ○  2 of 3", opening "How alarms work") on the right of the first list heading: "Your alarms" with none, "Next alarm" when one is on, "All alarms" when none is switched on (§4).

**Content.** `data/quotes.js` — 160 lines, 16 for each of the ten areas, **written for Eala, unsigned and original** (no attributed quotes: a famous line under the wrong name is the most common failure of the category, and licensed text is a cost that grows with every share). Ids are `${area}-${nn}` and are what a save is stored against, so **the lists are append-only**: retire a line by replacing its text in its slot, never by deleting or reordering. The lines follow the same timeless rules as the wake-up copy and are checked by `npm run audit:copy`.

**Choosing the thoughts** (`lib/quotes.js`, `todaysThoughts`, three; `todaysThought` is the first: a pure function of who and which day, so it is the same if you leave and come back, new at the person's midnight, and needs no server). Each person has their own fixed order of the library and the days walk down it, so **a line does not come back until the list has been used**, with no memory of what was shown. With a Reason, the first two of the day come from the areas they hold Reasons in and the third from everywhere else; with none, it is the whole library. A `lead` id (the line a notification carried) wins even when it is no longer today's. The notification, the ring and the card all read the same function. At three a day a person with one Reason in one area walks that area's 16 lines in about 8 days before one returns; **the library has to grow** (plan: about 200 lines per area at launch, written in one reviewed batch and shipped as a downloadable file, not inside the app, plus about 50 per area a month) so that figure becomes months.

**The card** (`components/QuoteCard.jsx`, shared by today's thought and by a favorite opened from the grid). Scene, area label, the line set large (44 to 28 px by length) arriving word by word, and under it two round, icon-only buttons: a **heart** and a **share arrow**. They have no words because they are the two glyphs every age group already reads from every other app, and each keeps an accessible name ("Add to favorites", "Share this quote"). The heart and the collection use one word: a heart **favorites** a line and the collection is **Favorites**. Double-tap anywhere favorites (it never removes one; the heart does). A favorite fires a haptic and a burst of hearts. A one-line hint ("Double-tap to favorite") shows until a favorite is made or seven seconds pass (`prefs.quotesHintSeen`). **A fourth page ends it.** After the third thought, one more page, with no dots (they fade out, so it reads as the end and not a fourth thought): black with a soft orange glow, a small orange check that draws itself, "Thanks for checking in", "See you tomorrow", and an orange **Done** pill (closes the screen, like the X). Three short lines at most: the page is a goodbye, not a message. It is a page of its own because the third card was too full to end on.

**The card links to nothing outside itself**, like a story: no call to action and no way into another part of the app, only the line, the heart, the share arrow and a way out. **No counts on the lines**: there is nobody else in the app to make a number mean anything, and a made-up one is the one thing a quote app must not do.

**Favorites** (`screens/quotes/Favorites.jsx`). `state.likes = { [quoteId]: timestamp }`, persisted under that key; the timestamp is when it was saved. It opens on the library (below). A pile opens the swipe view: each line set large, the way the person met it, with its area and no save date, a sideways swipe to older ones ("2 of 8"; sideways because up and down is a different gesture elsewhere). **Once a pile holds more than six** (`GRID_AT`) a grid button appears at the top right of that view: a 2-column grid of tiles, newest first, each a miniature of the card, and a tile sends the swipe view to that line. The list is taken when Favorites opens, so a line un-favorited while it is open stays put and the page never jumps under a thumb. With none, it says how to favorite.

**The library.** From the first favorite on (`libraryFor`), Favorites opens on a library, so it is one shape however many there are and a hundred saved lines are a few things to choose between, not a hundred swipes. No save dates are shown anywhere in Favorites (the swipe view and the grid tiles carry none). "Favorites" set large with "40 lines you kept, in 7 areas" under it; then **All favorites**, a wide card painted with the newest saved line and showing its first words, "40 lines · newest first"; then **By area**, a pile per area in two columns, fullest first. A pile is painted with that area's newest saved line, carries the area's icon, its name and "14 lines", and has one or two card edges showing behind it (by how many it holds) so it reads as a stack of lines rather than a button; the piles arrive one after another. Counts belong here: they are the person's own, not anybody else's. Tapping a pile opens the same swipe view, grown out of that pile, holding only that area's lines newest first, with the area's name and "3 of 14" at the top and the grid button once the area holds more than six; Back returns to the library (and from the grid, to the swipe view: one level per tap, and a double tap never walks out two). The library re-reads the favorites each time it is shown again, so a pile emptied while inside it is gone on the way back; inside a swipe view the list still stays put.

**How you get there.** A labelled pill in the top corner opposite Close: two stacked cards and "Favorites", nothing else. It is drawn as a place, not an action. It carries no heart and no number: a heart with a number beside it reads as a like count, the one count this screen must never show. The number lives inside Favorites ("2 of 8"). **What connects the heart to the pill is the heart itself:** saving a line sends a small heart from the card's heart button up into the pill along a soft rising curve (about 0.8 s, smaller as it goes), and the pill takes it with a slight pulse and a light haptic. Taking a heart off flies nothing, and nothing flies inside Favorites or with reduced motion (the pill only pulses). The pill is absent until there is a favorite and pops in as the first heart lands, which is how somebody learns where it went.

**Backgrounds.** Eighteen painted SVG scenes (`components/Scene.jsx`; dunes, mountains, ocean, forest, night, aurora, clouds, meadow, plain, lake, city, summit, road, lanterns, snow, galaxy, lighthouse, canopy), five or six suited to each area (`AREA_SCENES` in `lib/quotes.js`), each turned a few degrees round the colour wheel and optionally mirrored per line so one painting reads as several. Drawn, not photographed: nothing to license or download, identical on any screen, and a few KB each. A line always has the same look (derived from its id), so the picture someone favorited is the picture they share. The bright parts of a scene (sun, moon, the pale band of sky at the horizon) sit **below the band where the line is set**, so the words never cross them; measured against the scrim, white text clears 3:1 (the AA floor for large type) over at least 95% of the text area in each of the first nine scenes. The other nine (lake to canopy) follow the same placement rule and have been checked by eye behind a real line, but not yet measured.

**Share** (`lib/shareQuote.js`). Draws a 1080×1920 card on a canvas from the same painting the thought shows (same scene, hue and mirror), the line balanced so the last line is never one word, the area label, and the Eala mark and name at the foot. The share sheet gets the image when the device accepts files, the words when it does not, and the clipboard (a one-button dialog, "Copied" / "Paste it anywhere.") when there is no share sheet; cancelling is silent.

**The daily thoughts.** `prefs.notify.quotes`, **off until the person says yes**, switched on and off under Settings › Notifications as "Thoughts for the day". It is its own category on purpose: switching off trial and billing notices must not switch off the thought, and switching it off must never touch an alarm. Alarms are not governed by it. **They ship at launch**: three a day, spread across the day so they arrive apart, each carrying the id of one of today's thoughts and opening on it. The prototype cannot send them; Settings › Prototype › *Lock screen* sends one and opens the thoughts when it is tapped, and says Off when the switch is off.

---

## 11.0b Notifications (with the app closed)

Every notification Eala sends is defined once, in `lib/notifications.js`: its words, the Settings › Notifications switch that governs it, whether this account is owed it, and where a tap lands. The alarm itself is not a notification: AlarmKit rings through Silent and Focus with its own full-screen UI, and no switch here can silence it.

| Notification | Switch | Sent when | Title / body | Tap opens |
|---|---|---|---|---|
| Trial ends tomorrow | Trial & billing | the day before a trial that will renew converts | "Your free trial ends tomorrow" / "Eala Premium starts {day} at {price}. Cancel before then and you won't be charged." | Settings › Subscription |
| Payment failed | Trial & billing | a renewal fails (grace period) | "Your payment didn't go through" / "Premium and your alarms stay on while Apple retries. Update your payment method to keep them." | Settings › Subscription |
| Payment still failing | Trial & billing | a day or two before the grace period ends, once, only if still unpaid | "Your alarms will switch off soon" / "Your payment still hasn't gone through. Update it before {date} to keep Premium and your alarms on." | Settings › Subscription |
| Premium ended | Trial & billing | the subscription lapses | "Your Premium has ended" / "Your reasons and alarms are saved. Resubscribe to switch your alarms back on." | Settings › Subscription |
| New messages paused | Trial & billing | the last credit of the month is used, once | "New messages are paused" / "You've used all {n} credits. Your alarms keep ringing, and new messages return {date}." | the credits sheet |
| Alarms are off | Alarm reminders | a whole day with every alarm off or none set; once until an alarm has been on again; never to a lapsed account | "Your alarms are off" (or "No alarm is set") / "Switch one on and Eala will ring with your reason." | the Alarms tab |
| Today's thought ×3 | Thoughts for the day (off until asked) | three a day, spread apart | "Today's thought", subtitle the area, body the line | today's thoughts, opened on that line |

Rules: one job each, said in the title, the body saying what happens next; no time-of-day words; never repeated for the same event; iPhone notifications off, or the category's switch off, means it is not sent, and Settings says so where the switch is.

**In the prototype** there is no OS, so `components/LockScreen.jsx` draws the phone with Eala closed: the lock screen (date, clock, a dawn wallpaper), our notifications arriving one at a time with a soft chime and a haptic, grouped into one stack that a tap fans out ("Show less" folds it), swipe sideways to clear, tap to open (the lock screen lifts away and Eala opens where the notification points), and the bottom line or Escape to open Eala with nothing. Settings › Prototype › *Lock screen · all due* shows everything this account is owed now; each row under it sends one, or says why it would not arrive (Not due / Off). Only the icon, title, subtitle, body and tap target are ours in a real build; the rest of that screen is the OS's.

## 11.1 Saving an alarm and turning it on

Creating a Reason or an alarm is free; only an **enabled** alarm whose Reason has no ready message causes one to be prepared (§6). **There is no confirmation sheet:** a switch that asks permission feels broken. The alarm card confirms instead — "Preparing your message", then "Message ready" — so what happened is visible without being a step. The editor shows the Enabled switch for a new alarm too (it starts on, and the person may save it off) and no cost text.

Two things can still stand in the way, and each is a plain answer to something the person just tried:

- **The plan** — a lapsed account is sent to the paywall with a continuation, so subscribing finishes the switch (`lib/requirePlan.js`, §3).
- **No free place** — there is nothing to interrupt: an empty place is the only way to add an alarm (§4), so no screen offers one that cannot be saved.

Turning an alarm **off** is never asked about. Order on Save: plan check (§3) → commit. Saving or editing an alarm never asks for an account (§11.2).

- **Alarm card.** Top row: the Reason's emblem and name (small caps) on the left, the switch on the right. Then the time, then one line — "Next ring · in 8 hr 13 min", or "Rings in … · once" for a one-off, or just "Off" — then, for repeating alarms, the seven day dots with the next one marked. An off alarm is dimmed and desaturated, and every switch works the same way: nothing about the limit (§4) can stop an alarm from coming on, because a fourth alarm never exists. **The footer carries only the transient state:** when an alarm goes off → on it shows a spinner with "Preparing your message" and a 2 px indeterminate line along the card's bottom edge (no percentage or stage names), which resolves into a drawn check and "Message ready", and that strip then fades after ~2.5 s on every card, the Next-alarm hero included. Every OFF → ON gets the same two moments (about 5 s when a message is really being written, about 2.8 s when the Reason already has one), because an alarm enabled with no animation reads as a tap that did nothing, and two alarms behaving differently teach a rule nobody can see. Turning off, and saving an alarm that was already on, get nothing. The only persistent sentences are trouble: "New message from Nov 14" with an Add credits link when an enabled alarm's Reason is waiting on credits (§4), and "Message not written yet" for an enabled alarm whose Reason has no message for any other reason. (The prototype fakes the wait.) **Swiping a card left deletes the alarm** — the card drains to the off look, a ring opens and fills, and past the commit point (about 38% of the width) letting go dissolves it; a shorter pull leaves it open with the ring as a button. It is asked first, with one dialog ("Delete this alarm?" / "Your reason stays in My Reasons." — Cancel, Delete): going past the line, tapping the ring on a swiped card or the plain Delete button all rest the card open on its ring while it is asked, then it dissolves on Delete and comes home on Cancel. There is no Undo, because nothing in this app appears and then disappears on its own. A screen reader or keyboard gets a plain Delete button. A one-time hint demonstrates the swipe on the first alarm (Settings › Prototype › Swipe hint replays it).
- **Alarm editor** (compact: time, days, Reason, soundtrack, ring, snooze): the wheel stands on the page with nothing under it, as on every phone's own clock; the seven weekday buttons, with nothing under them — no days chosen is a one-off, which people already know, and with days lit the buttons say the rest, so no hint, no countdown and no spelled-out copy ("Mon Tue Thu Fri Sat") is shown; one line under them that is always there: "Rings once · tap days to repeat" with no day lit, **"+ Add another time"** (§11.1a) with one or more; **What you'll hear** — the Reason row (emblem, name, "Area · Tone", **Change**) or, with none chosen, a dashed "Choose a reason" row ("Add a reason" when the library is empty; the Reason is deliberately never chosen for them); the Soundtrack row and the Alarm sound row; Snooze as a switch with a "Snooze length" row beneath it only when on; an Enabled switch (on by default for a new alarm) and, for an existing alarm, Delete. The footer button reads "Choose a reason" (or "Add a reason") until there is one, then "Save Alarm" for a new alarm or "Save Changes" for an existing one, and is absent when an edit has changed nothing. A new alarm starts switched on; switching it off saves it off, and the card shows "Off". If the editor is opened with no free place (§4) it closes at once and a one-button dialog says "You can have up to 3 alarms." The editor shows **no status line, no transcript, no player and no "stored on this phone" caption**, and has no preview button (§16).
- **Delete alarm** (the editor's Delete row) does exactly what swiping does on the list: it asks the same question first ("Delete this alarm?"), then the screen closes and the alarm is gone. The Reason stays in My Reasons, and the retained message is never mentioned. Deleting a **Reason** that alarms use still warns "The alarm that plays it will be deleted too. An alarm cannot ring without a Reason." and deletes them with it — the user decides, the alarms are never left pointing at nothing. Out of credits, deleting a Reason that has a message adds one sentence to the same dialog: "You're out of credits, so a new reason won't have a message until Nov 14." (`lib/deleteCue.js`).

## 11.1a One alarm, a different time on different days

"6:30 on weekdays, 8:00 on weekends" — or a different time every day — must not cost a second alarm place or a second Reason. An alarm therefore may carry `byDay`: a time for each day it rings. The editor never shows `byDay`; it shows **schedules** (`lib/schedule.js`: `groupDays`, `fromCards`, `addCard`, `toggleCardDay`), each a time and the days that ring at it, like the iPhone's Sleep schedule.

**One schedule is the plain alarm and looks like one**: the wheel on the page, the seven days under it, no card chrome. Under the days is one line that is always there, so nothing arrives when a day is tapped: "Rings once · tap days to repeat" with none lit, **"+ Add another time"** with one or more.

**Add another time** makes a second schedule (`components/ScheduleCards.jsx`) for the days that have no time; with all seven in use it splits the weekend off the week, which is what most people who ask for a second time mean. It starts at the last schedule's time and its wheel opens, scrolled into view. From here each schedule is a card: its time large, what it repeats ("Weekdays", "Weekends", "Mon–Sat") and a chevron, then its own seven day buttons. **One wheel is open at a time** (tap a time to open it, the same again to close). The link goes when no day is left to give.

**The seven days mean one thing: tap a day to put it in this card.** A day that rings at another time shows faintly here (an outline, not a fill; its accessible name says when it rings) and tapping it moves it. Tapping a lit day turns it off. A card whose last day leaves goes with it, and with one card left the editor returns to the plain look. Every day different is seven cards of one day, and one alarm place. Cards that end up with the same time are saved as one (`finalize`), and an alarm with `byDay` opens grouped by time, weekdays before the weekend. With no day lit it rings once, and the wheel sets that time.

**Everywhere else it reads as the next ring.** `lib/format.js` `schedulesOf` groups the days that share a time. The card prints the time that rings next (the one the person is waiting for), and lights every day it rings on. It does not list the other times: the lit days say which days ring, and opening the alarm shows each time. A Reason's alarm row reads like the card: the time that rings next, and the days it rings on (or Off). The scheduler fires whichever time is due; a day has one time, so at most one rings on any date. Nothing about cost changes: one alarm place, one pool of messages and at most one ring a day (§4, §6). In the real build each distinct time is one OS alarm, which is a platform limit to check (BACKEND_ARCHITECTURE.md).

---

## 11.2 The account gate

Only **buying a subscription** asks who you are; saving an alarm does not. The subscription needs an identity because an entitlement held on device state alone is lost on reinstall and never reaches another phone (StoreKit would sell it anonymously; *keeping* it is what needs the account). **The real build still needs an identity before the first armed alarm**, because that is the first byte of spend — a cost that cannot be attributed, rate-limited or defended against reinstall abuse without one. An anonymous Firebase Auth uid (BACKEND_ARCHITECTURE.md §4) satisfies that without a login wall; sign-in then links to it.

- **Not asked:** opening the app, the demo, making a Reason, saving or editing an alarm, turning one on.
- **The in-app paywall while signed out** swaps its footer for "Continue with Apple / Google" ("One step first, so Premium follows you rather than this phone.") with a Back that returns to the plans, and the sign-in and the purchase are one gesture. Onboarding's paywall does the opposite by design (§11: pay first, identity after).
- Sheet titles are by reason: `account` "Keep your reasons safe" (opened from Settings, where there is no step being blocked) and `returning` "Welcome back" (onboarding's first screen).
- Each gate takes a continuation, so the interrupted action finishes by itself; being handed back a form to submit twice is what makes a gate feel like a wall.
- Signing out ends the session and nothing else: Reasons, alarms, name and plan stay on the device, because the name and the plan are built into every message and every gate. `deleteAccount` is the only action that clears them.

---

## 12. Alarm firing & wake-up flow

**Why the ring is iOS's own screen.** iOS does not let an app draw its own screen over a locked phone, so a custom ring (Eala's old night ring, with its own Snooze and slide) cannot exist in a real build. Eala rings through **AlarmKit** (iOS 26+), which shows the system's alarm screen, rings through Silent and Focus, and lets the app set only the title, the tint and one button. So the design starts from that limit: the system rings; the one button we name, **Hear your reason**, is how Eala is opened; and everything Eala draws begins after it. The prototype draws the system's screen and nothing more, so it never promises a ring the real build cannot have. Android has no such limit (a full-screen intent may draw its own screen); the prototype models only the iPhone, and Android's ring screen is not designed yet (§13).

**What rings: `WakeFlow`.** A full-screen overlay in stages: **ring → Face ID → reminder → quote**, with the **lock screen** (`away`) between rings. The ring is only a ring; the voice waits for somebody who has chosen to be awake. The foreground scheduler (`useAlarmScheduler`) and Settings › Prototype › Ring open it.

- **Ring: the system's, not ours** (`components/SystemRing.jsx`). Eala rings through AlarmKit, and on a locked phone, in Silent or in Focus no app may draw its own ring screen, so the prototype draws iOS's, as faithfully as a web page can, and promises nothing the real build cannot have. Ours to choose is only what AlarmKit allows: the title (the Reason's name, with iOS's alarm glyph), the tint (orange `#FF9A3C`) and the label of one button. Laid out as the iPhone draws it: title and a clock as large as its width allows in the upper third; at the foot two tall full-width controls, the orange **Hear your reason** and iOS's own **slide to stop** (a dark track, a glass knob, shimmering words). The tone is synthesised (`lib/ringTone.js`); iPhone needs `unlockAudio()` on the first touch and the audio session set to "playback".
- **The one rule: only opening Eala ends a ring.** **Hear your reason** runs Face ID (`FaceId`: brackets breathe, then close on a check, about 0.9 s; the ring keeps sounding until Eala is open) and opens Eala at the message. **Slide to stop** only silences it: the phone goes back to its lock screen (`AwayLock`), where our Live Activity says when it rings again and a tap on it does what Hear your reason does; it rings again after the alarm's snooze length (1 minute if snooze is off). After 30 minutes (`GIVE_UP_MIN`) it stops ringing for good and the message waits in the app. Nothing counts rings and nothing scolds. The prototype shows the lock screen for 8 seconds and then advances the simulated clock by the snooze length (`useWakeClock().advance`); native waits the real snooze.
- **Ringing on an unlocked phone** (Settings › Prototype › Ring · phone unlocked). iOS does not take the screen: the alarm drops out of the Dynamic Island as a banner (`RingBanner`) with two round buttons, an arrow that opens Eala at the message (no Face ID) and ✕, iOS's stop, which only silences it. Silenced, the Live Activity sits compact in the Dynamic Island (`IslandCountdown`) with when it rings again; a tap opens Eala.
- **A ring test** (from Make sure Eala rings, `params.test`) checks the ring only: either control ends it with one quiet confirmation, with no message, no quote and no second ring.
- **Getting up** is opening Eala. A real alarm logs the wake (`wakeLog`) and consumes the message; a simulation writes nothing. The screen then crossfades into the reminder. **If the Reason has no message** (none written yet, for instance out of credits), the flow skips the reminder and goes straight to the quote, with no Replay link: a generic voice line would teach people to expect one. Nothing on this screen mentions credits: the sheet shown when the alarm was set already said it.
- **Look: a continuation of the iPhone.** The screens after the ring are drawn in the same language as the ring and the rest of the app (Appearance, §14.2): true black, SF Pro, white with iOS's grey secondary text, solid grey controls, and orange as the only colour (`components/IosWake.jsx`, shared with the onboarding demo).
- **Reminder** (`IosMessage`). Out of Face ID's black, unhurried: the date small and grey over the Reason's name as a large title (as "Alarms" heads Clock), a round grey sound button at the right (it mutes the voice and music; the words go on), the words set like Apple Music lyrics (bold, left aligned, lit as they are spoken, `Reader`), and at the foot the app's player: a round orange play / pause button (replay once it has run out) beside a waveform that is also the scrubber (`ScrubWave`: tap to jump, drag to scrub; a real slider for keyboards and screen readers). **Continue**, a quiet orange word under the player, appears after nine seconds or when the message ends; nothing advances on its own. For Relationships and Business the message is a bundled recording (`data/reminders.js`) with music under it (`lib/backgroundMusic.js`: looped, faded in and out, held with the voice, muted with it); other areas read a written message against a simulated clock.
- **Quote.** A small orange quotation mark and "A thought to keep" in grey, then one line for the area, bold and large, arriving word by word; then **Start My Day** (an orange capsule with black text) and **Replay message** (a grey capsule), which appears once the line has landed. No greeting, no streak or scoreboard, no area chip, and no save, share or rating. The line is chosen by walking the area's pool by calendar day, offset per Reason, so none repeats until the whole pool has been seen (about a dozen per area). Lines are Eala originals, unattributed, and obey the same no-time-of-day rule.
- **The screen names the hour; the voice never does.** A Reason's message is written once and played by its alarm at any hour, and a snooze can carry a ring past noon, so no spoken or printed line may name a time of day (enforced for model output in §7.3 and, for our own written pools, by `npm run audit:copy`, which shares one word list with the validator in `lib/timeless.js`). The wake-up screen reads the **device clock, live**: the time and date, and a sky whose colour follows the hour (`lib/sky.js`).
- The message is marked played, and the `wakeLog` entry written, only on **dismiss** — never on the alarm merely ringing. Nothing is written here: a message was prepared ahead of time (§6). One `wakeLog` entry per calendar day; later dismissals that day update the existing entry.
- **Prototype only: a foreground scheduler stands in for the OS.** The web prototype has no `UNUserNotificationCenter`/`AlarmManager`, so `lib/useAlarmScheduler.js` checks the clock every second while the tab is open and opens the ringing screen for any enabled alarm whose time has come (it rings for up to 2 minutes after the set time; anything older is missed). A one-off alarm switches itself off as it rings. Native builds must not port this — the OS owns firing (§13).

---

## 13. Platform-specific requirements (iOS & Android)

### iOS
- **Ring through AlarmKit** (iOS 26+). It is the only way an app's alarm can take a locked phone's screen and sound through Silent and Focus, and the screen it shows is the system's: the app sets the title (the Reason's name), the tint (orange) and one button (**Hear your reason**, which opens Eala through Face ID). Slide to stop is the system's and only silences; the snooze-length re-ring, the 30-minute give-up and the countdown are scheduled by Eala and shown as a Live Activity (AlarmKit's countdown presentation, a widget extension), which is the one part of the lock screen Eala designs (§12).
- **Before iOS 26** there is no AlarmKit: fall back to local notifications with Critical Alerts (the entitlement needs Apple's manual review, so apply early) or Time-Sensitive delivery. That path cannot take the screen; it shows a notification whose tap opens Eala at the message. Decide whether to support it at all before building it.
- Verify local notification scheduling survives: Background App Refresh disabled, Low Power Mode, and the app being force-quit by the user. A foreground-triggered top-up (on app open) must exist as a backstop in case background execution never ran.
- Set correct `interruptionLevel`/Time-Sensitive on notifications or they can get bundled/delayed by notification summary.

### Android
- Request `SCHEDULE_EXACT_ALARM` (Android 12+); detect if it's revoked and prompt re-grant — don't fail silently.
- Handle `BOOT_COMPLETED` to reschedule alarms after a device reboot (Android wipes scheduled alarms on restart otherwise).
- OEM battery managers (Samsung, Xiaomi, Huawei, OnePlus) are known to kill background alarms even with correct permissions — add an onboarding step detecting the manufacturer and linking to OEM-specific "disable battery optimization for this app" instructions.

### Both
- **Alarm access (the OS grant) — one phrase, one destination.** Every "alarms are blocked" surface uses the action "Enable Alarm Access" and deep-links to the app's page in system Settings. Alarms screen: the large banner ("Alarm access is off"). Under it, every alarm that is on says "Won't ring · Alarm access is off" in place of its next ring, and shows no "Preparing" or "Message ready" strip: the switch keeps the person's choice, so granting access brings each back as it was. Settings: a compact status row, "Alarm Access — Off ›", not a second warning card. Alarm editor: while access is off the Enabled switch reads off and cannot be turned on (tapping it opens system Settings), the alarm's stored enabled value is preserved, and the "This alarm won't ring — Enable Alarm Access" card shows below. Permission state is re-read when the app returns to the foreground so warnings clear without a relaunch. Notifications-off is secondary: "Notifications are off in iPhone Settings. Your alarms will still ring."
- **Timezone/DST**: alarms are wall-clock local, always follow the device clock — never store or apply a fixed timezone offset. Verify the actual scheduling math re-anchors correctly across a DST boundary (classic alarm-app bug class), not just that a UI message is shown.
- Device reboot, storage-full during audio caching, multiple alarms firing near-simultaneously — all need graceful fallback to "reuse what's already cached," never a crash or silent failure.

---

## 14. Account & data lifecycle

- **Account deletion must be real**, not cosmetic — delete the user's Firestore docs, Storage objects, and confirm data-usage settings with OpenAI/ElevenLabs (API calls by default aren't retained for training, but verify and document this for GDPR/CCPA "right to be forgotten" compliance).
- **Multi-device conflict**: Firestore's default last-write-wins will silently drop a concurrent edit from a second device — acceptable for alarm fields here. A Reason's fields are editable (§1), so two devices editing the same field at once keep the later one; field-level updates (not whole-document writes) keep edits to different fields from clobbering each other.
- **Session/token expiry mid-flow**: must refresh silently; a user mid-composer must never lose an unsaved draft to a token expiry.
- **Cloud is source of truth but the app must be fully usable offline** once signed in at least once — every write (toggle alarm, consume take, log wake) queues and syncs rather than blocking on connectivity.

---

## 14.1 Legal pages and support

All three About links — Help & Support, Privacy Policy, Terms of Use — open **in an in-app browser**, not the system browser. On iOS that is `SFSafariViewController`, on Android a Custom Tab: the address being visited stays visible, the app is never left, and returning is one tap. A link that ejects somebody to Safari mid-session is a link some of them do not come back from.

**Privacy Policy and Terms of Use are hosted pages, not bundled screens.** They have to be correctable without an app release — a policy that can only be fixed by shipping a build is a policy that stays wrong for a review cycle. Both URLs are also required at App Store submission, so they must resolve publicly, not only from inside the app.

**Draft copy must be visibly marked as draft.** The prototype's bodies are placeholder text and say so in a band at the top of the page. Plausible-looking legal prose that nobody drafted is more dangerous than obviously unfinished prose, because only one of the two gets noticed before it ships.

**Help & Support is a form, not a mailto: link.** Fields: name and email — **prefilled from the account and editable**, since the reply address is not always the one the sign-in provided — subject, message, and an optional image attachment. Submit is disabled until name, a valid-looking email, subject and a message of reasonable length are all present.

- There is deliberately **no topic/category picker**. Four tall rows to pick a routing label is a lot of screen for something the subject line already says in the sender's own words, and a category chosen in a hurry routes worse than the sentence written about it.
- The attachment is **never read into memory client-side** — only its name and size, for the row that shows what is attached. A screenshot of somebody's lock screen is not something to load for decoration.
- Server side: the attachment needs a size cap, a content-type allowlist, and the same retention decision as any other user-supplied file (§8, PII).

## 14.2 App shell and Settings

**Nothing appears and then disappears on its own.** There are no toasts, snackbars or timed banners anywhere. A message that goes before it is read, or sits on top of the thing it is about, is worse than none, so whatever has to be said is either shown where it applies (a status on the alarm card, a standing line on a Reason, the Favorites button appearing) or asked and answered in a one-button dialog (`notice` in the store: the alarm limit, a copied link, something the OS would do). Deleting asks first for the same reason: with no Undo to catch a slip, a question has to. Confirmations whose result is already on screen (saved, subscribed, signed out) say nothing.

**Shell.** Three tabs in a floating dock — Alarms, Reasons, Settings — each an icon with its name beneath it (a bare glyph has to be learned; a word is read at a glance, and the Reasons glyph is not self-evident), with one orange pill behind the chosen icon and label that slides between tabs. The order follows the product: a Reason is what an alarm plays, so those two sit side by side; Alarms stays first because it is what the app sells and what rings on its own; Settings is last by convention. The prototype is drawn as an iPhone 14 Pro Max (430 × 932 pt screen, 126 × 37 pt Dynamic Island) and on a desktop window shorter than that the whole frame is scaled down, never just its height. Adding a Reason or an alarm is the shared add card (§4, `AddCard`), the last item of its list: the dashed empty-item card with an orange plus when the list is empty ("Add your first Reason" / "Set your first alarm"), a quiet dashed row ("New Reason" / "Add alarm") otherwise. There is no floating button on either tab. Screens push over the tabs as a stack; sheets belong to the screen that opened them and are dismissed by any navigation; destructive confirmations are modals; the ringing screen and the paywall are full-screen overlays. The payment sheet is its own layer on top of all of them and is never covered, because an app that can draw over a payment confirmation can fake one.

**Pickers and choice lists** (one convention, so a list is learned once).

- **One mark for the chosen row** (`SelectMark` / `SelectButton` in `components/ui.jsx`): an empty ring before anything is chosen, and a filled orange disc with a check on the chosen one. Where the row's body does something else when tapped (previewing a voice or soundtrack), the mark is its own 44 pt button and draws at 24 pt.
- **A sheet is a title, the choices and one button.** A subtitle appears only where it teaches something the title and rows do not: Soundtrack ("Music that plays behind your message."), Alarm sound ("Tap play to hear it."), Credits ("1 credit = 1 new message"), and the Reason picker's "Every reason already has an alarm." state. Area, Tone, Length, Voice, Purpose, Why and Snooze have none.
- **Descriptions stay on one line** in the Area and Tone sheets at 14 pt (the rows are tightened to fit); on a very narrow phone they wrap rather than clip.
- **Voice sheet (editing a Reason).** Each row is a play button, the portrait and details, and the choose mark. The play button only plays a sample; a tap on the row only chooses, so nothing sounds unless play was pressed. The composer's voice step works the same way: a tap on the row chooses, its play button plays (§11).
- **Suggested wording** under an empty Purpose or Why box is set in regular weight under the caption "Or start from one of these", and goes away once anything is typed.

**Appearance.** There is one look, the iPhone's own (Clock's), so the system's ring and Eala read as one place: true black, SF Pro, white and iOS greys, solid grouped grey cards (no glass tint, no gradients, no glow), and orange (`#FF9A3C`) as the one accent, with black text on orange buttons. It is applied by class: `.ios` in `styles/global.css` (the tabs, Settings and the screens behind it, the alarm editor, Reason detail), `.ob5--ios` in `screens/onboarding/ob.css` (onboarding, the composer, the Reason-ready screen, the paywalls), `.quotes-ios` (the Quotes tab) and `IOS` in `components/IosWake.jsx` (the wake-up). There is no light mode, no appearance setting and no theme switch. The older navy-and-gold tokens (`styles/tokens.css`, `--gold: #E7B563`) still sit underneath and are overridden by these classes; a gold that shows anywhere is a bug.

**Time zones are handled as behaviour, not a setting.** Alarms are wall-clock local and follow the device; there is no override (a manual zone in an alarm app is how people miss flights). The first time the app opens in a new zone it says once, in a modal, "Welcome to a new time zone." and that the alarms still ring at the time set.

**Settings**, in order (every row has one job, and nothing is there for show): the profile card (initial, name, a PREMIUM badge, "Signed in with Apple / Google" or "Not signed in") → Profile (rename; the same name rules as onboarding); the payment-issue card while in grace (§10.2), whose Update deep-links to Apple's payment settings; the slim "Premium has ended · Renew" line after a lapse (`RenewBar`, shared with Alarms); **Alarm**: *Make sure Eala rings* (§14.3; its value reads "Access off" in the warm colour when the grant is missing, which is the only place Settings says so); **Notifications**: *Trial & billing* (the trial ending, a failed payment, a renewal coming), *Alarm reminders* (one note after a whole day with every alarm off or none set, never repeated until an alarm has been on again; `lib/alarmReminder.js`, clock `offSince`/`offNudged` in the store; not sent to a lapsed account; Settings › Prototype › *Lock screen* shows it; on by default) and *Thoughts for the day* (off until asked for, ships at launch, §11.0a), with one caption ("These settings don't affect your alarms.", or, with notifications off in iOS, the warning and a **Turn on in Settings** link); **Subscription**: *Subscription* (value: "Premium · Annual", "Ends Oct 28", "Payment issue" or "Ended"; opens the Subscription screen, §14.3) and *Credits* (hidden after a lapse; opens the credits sheet), with one caption ("Credits reset Nov 14.", or the plan's end, or what a lapse kept); **Support**: *Help & Support* (the form, §14.1), *FAQ* (hosted, §14.3), *Request a feature* (§14.3), *Leave a review* (Apple's write-review page, `itms-apps://apps.apple.com/app/id…?action=write-review`; the system rating prompt is separate and asked after the third real alarm); **Legal**: Privacy Policy and Terms of Use (§14.1); **Account**: *Sign In* (signed out, with "Keep your reasons, alarms and Premium if you delete the app or switch phones.") or *Sign Out* (confirmed), and *Delete account* (confirmed; the server deletes for real, §14); while the subscription would still renew, the confirmation adds "Your subscription is billed by Apple and keeps renewing until you cancel it." and a **Cancel Subscription First** button (to Settings › Subscription), because deleting the account does not cancel billing (App Store Review 5.1.1(v)); and the version and build as a plain footer line.

**Deliberately absent.** *Tips & offers* (nothing sends any; it returns with the first real campaign, with a consent record). *Export my data* (answered by support on request if GDPR portability is needed). *Appearance* (dark only). *Reduce motion* and *Haptics* (the iPhone's own Reduce Motion and System Haptics switches already govern both, and the app follows them; a second switch in the app would only be a second place to set the same thing). *An in-app downgrade to Monthly* (§10). *A "streak deadline", rest days, strict mode or "prevent app deletion"* (Erly's, built for missions and streaks; Eala has neither). *An evening "set your alarm" reminder* (our alarms repeat; the re-enable reminder covers the real failure).


- **Notifications have no master switch.** The OS permission cannot be set by an app, only read, so a switch claiming to hold it would be decoration. What is ours to ask is which *kinds* of notification we send, and the two are kept apart so that somebody silencing promotions cannot thereby silence a failed payment. Alarm Access (the alarm grant) and notification permission are separate state: an alarm sounds through the silent switch, Do Not Disturb and Focus by design, so losing notifications costs a message, not a morning. When notifications are off the caption says so, and says "Your alarms will still ring" unless alarm access is also off.
- **There is no "ring on silent" switch** and no fade-in or volume preference: a preference nothing reads is a promise the app quietly breaks. Snooze length belongs to each alarm.
- **Reduce motion** follows the iPhone's own setting only (Accessibility › Motion › Reduce Motion); one hook drives both CSS and the animation library, because the CSS rule alone does not reach the latter. A fade is not motion. Haptics likewise follow System Haptics. Neither has a switch in the app.
- **Settings › Prototype** is a developer menu behind a single row at the foot of Settings ("Prototype"), which opens it as its own screen, so it never crowds the real settings. It is rendered in every build (`SHOW_PROTOTYPE` in `Settings.jsx`), with the caption "Development builds only." It holds: **Ring** (a simulated ring on a locked phone), **Ring · phone unlocked** (the Dynamic Island banner, §12) and **Ring · real voice** for Relationships and Business; **Swipe hint** (replays the alarm-card hint); **App tour** and **Reasons tour** (§11.0); **Lock screen · all due** and one row per notification in `lib/notifications.js`, each sending it or saying why it would not arrive (Not due / Off) (§11.0b); **Load demo data**; a stepped **subscription simulator** — the state, then 1 · Start 3-day trial, 2 · Cancel subscription, Payment fails (grace period), Payment recovered, 3 · Trial ends (expire now) — each step offered only when it is the one that comes next, so no state a real store cannot produce can be reached; the **Notification permission** and **Alarm permission** toggles; **Payment sheet** (its appearance; it follows the device's Light/Dark by default, as StoreKit does); **Credits left** (set the balance to 10, 3 or 0, or reset the month); **Takes ready** (each Reason's shelf as `have/planned`, starred when the waiting take no longer matches); and **Replay onboarding**. There is no failure simulator: a Reason is created without rendering anything, and the shelf refills invisibly.

---

## 14.3 Screens behind Settings

**Subscription** (`screens/Subscription.jsx`). Everything about money on one screen:
- **The plan card.** "Eala Premium" over the plan's name (Annual or Monthly) and a status pill (*Active*, *Free trial*, *Cancelled*, *Payment issue*, *Ended*). Then the price ("$79.99 per year") and one sentence with the date that matters:
  - "Renews Oct 21, 2027."
  - "Free until October 24, then $79.99 a year."
  - "Ends October 28 · no more charges"
  - "Payment failed. Premium stays on while Apple retries." (with **Update payment method**)
  - "Your reasons and alarms are saved." (with **Resubscribe**)
- **Switch to Annual.** Shown only to a Monthly subscriber renewing normally: "Save 33%", "$79.99 a year, about $1.54 a week. Starts today, and Apple refunds the rest of this month." and **Upgrade for $79.99 a year**. The button opens the App Store sheet (`upgradeItem`: "Starting today", with the refund stated in its terms). Telegram offers the same move in the same place; Erly offers none. It is the one plan change the app sells, because it saves the person money (§10).
- **Included.** Five one-line rows read from the product: a new message every time you wake; 100 messages a month, from day one; 3 alarms, unlimited reasons; every voice, tone and soundtrack; three new thoughts every day.
- **Manage.**
  - *Manage in App Store*, which reads *Renew in App Store* once cancelled. It calls StoreKit `showManageSubscriptions`.
  - *Restore Purchases* (`AppStore.sync()`), on every state including Ended.
  - *Cancel Subscription*, while it renews.
- **Apple's terms**, in one short line under it all: "Renews automatically. Cancel at least 24 hours before renewal in your Apple Account."

**Cancelling** (`cancelSurvey` sheet). The app cannot cancel a subscription, so it asks one question and hands over:
- **The question.** "Why are you cancelling?" with eight answers:
  - too expensive
  - don't use it enough
  - alarm didn't ring
  - alarm too quiet
  - messages not personal
  - messages repetitive
  - prefer a regular alarm
  - something else, with an optional note
- **The answer** is logged (`cancel_reason`) and nothing else is done with it.
- **The two alarm answers** add one line, "Often it's an iPhone setting. Make sure Eala rings", as a link, never as a step in the way.
- **The exit.** **Continue to cancel** opens Apple's subscription page; **Keep Premium** closes.
- **No guilt.** There is no screen arguing back (Erly's "Your streak ends here" is what this must not be, §10.1). The sheet names the date access runs to.

**Make sure Eala rings** (`screens/RingCheck.jsx`). AlarmKit rings through Silent, Do Not Disturb and Focus. Three iPhone settings can still make an alarm too quiet to wake anyone, and this page names them. From the top:
- **Alarm access, live.** "On. Eala can ring." or "Off. Eala can't ring." with **Turn on**. It is the one setting the app can read.
- **Three cards**, each a short reason and the exact taps:
  - **Turn the ringer up**: Settings › Sounds & Haptics › Ringtone and Alerts, all the way up. Alarms use the ringer volume, not media.
  - **Lock the volume**: Settings › Sounds & Haptics › Change with Buttons, off.
  - **Keep it loud when you look**: Settings › Face ID & Passcode › Attention Aware Features, off.
- **The Dynamic Island note.** A bar stuck in the Dynamic Island after an alarm (an AlarmKit Live Activity) clears by ringing a test alarm and stopping it; if not, restart.
- **Ring a test alarm** (the footer button, with a bell). It counts down from 5 in a small orange ring that empties ("Lock your phone now", Cancel), then rings exactly as an alarm does: the system ring (§12) titled "Test alarm", with Hear your reason and slide to stop. Either one ends the test: an orange check draws itself, "Eala can ring." / "Your alarms will sound just like this, even on Silent." and Done. No message and no quote play, and nothing is written or spent. Back on the page the button becomes a quieter "Test again".
  - In the real build it schedules a real AlarmKit alarm 5 seconds out ("Lock your phone to hear it as you will"), with a countdown and Cancel. It rings the first enabled alarm's tone and plays its reason's message, and like every simulation it writes, consumes and spends nothing.
  - In the prototype it opens the ringing screen after the countdown.
  - With access off, the button opens Settings instead.

**FAQ** (`PAGES.faq` in `data/legal.js`, hosted at eala.app/faq). It opens in the in-app browser as an accordion, one answer open at a time, and is edited without a release. The questions:
- How is my message written?
- When do I hear it?
- Will Eala ring on Silent or in Focus?
- Does it work without a connection?
- What are credits?
- What happens if I run out?
- Why can I have only three alarms?
- Can I change a reason after making it?
- How do I cancel?

Every answer follows this spec and changes when a rule does.

**Request a feature** (`screens/Feedback.jsx`). "What should we build next?" over "Tell us what would make Eala better for you. We read every request." It has one box (1,000 characters, a counter) and **Send request**, enabled from 10 characters. The account is attached on the server. The reply is a one-button "Thank you" dialog. It is separate from Help & Support because an idea is not a problem report and should not need a ticket.

## 15. Consolidated edge-case checklist

- [ ] Empty / gibberish / sexual / hateful / self-harm content in purpose or focus-note — moderated pre-generation, every time
- [ ] Prompt injection attempts — tested adversarially
- [ ] Non-English input — explicitly supported or explicitly rejected, never silently mis-generated
- [ ] LLM refusal string reaching TTS — detected and treated as a generation failure, falls back to template
- [ ] TTS failure/timeout — nothing is written and the credit is released; the alarm still rings and shows the quote, never silence
- [ ] Generation never happens at alarm-fire time — always pre-rendered and cached ahead of need
- [ ] A Reason keeps one message, writes one fresh message per play while credits last (each spends one of the account's 100), replays its current message when none can be written, and never writes more than 31 in 30 days
- [ ] Removing the last alarm from a Reason never deletes its waiting take
- [ ] Nothing is prepared for a Reason with no enabled alarm
- [ ] An alarm is never silent: the Reason's message → ring, then the quote with no voice message
- [ ] Alarm cannot exist without a Reason — enforced server-side, not just client UI
- [ ] Soundtrack changes never invalidate a take or trigger regeneration
- [ ] A lapsed account keeps every Reason and alarm it made; creating a Reason, arming an alarm and saving an edit open the paywall
- [ ] Timezone/DST transitions re-anchor wall-clock alarms correctly
- [ ] Device reboot reschedules Android alarms
- [ ] OEM battery optimization doesn't silently kill alarms — user is guided to disable it
- [ ] Notification/exact-alarm permission revoked mid-use is detected and surfaced, not silently broken
- [ ] Purchases validated server-side via receipt, never trusted from client callback alone
- [ ] Entitlement state driven by store webhooks, not just the initial purchase tap
- [ ] Restore Purchases implemented (required for App Store approval)
- [ ] Trial cancelled mid-window keeps full access to `trialEnd` — cancellation changes UI copy only, never entitlement
- [ ] Privacy Policy and Terms URLs resolve publicly, and placeholder copy is marked as draft until counsel signs it off
- [ ] Lapse never deletes a Reason, an alarm or a setting — all restored in full on resubscribe
- [ ] A lapsed account can still browse, delete, sign out and close the account, but cannot save an edit to a Reason (Save Changes, or tapping the name, opens the paywall)
- [ ] Lapse switches every enabled alarm off; time, days and Reason survive intact
- [ ] Switching an alarm OFF is never gated, on any plan
- [ ] Subscribing from a gate completes the action that opened it
- [ ] Payment failure inside grace period keeps full Premium and alarms; only a grace-period expiry lapses the account
- [ ] Cancelled-but-active account shows the end date on Plan row and both sheets, and nothing is taken away before it
- [ ] Alarm-access-off blocks enabling an alarm in the editor without resetting its stored settings; one phrase and one deep link on every surface
- [ ] Reasons are unlimited; alarms are capped at three (§4), and the Alarms tab shows that as places, never as an error
- [ ] Three alarms: no add button; one add card while any slot is free (the dashed empty-alarm card with an orange plus and "Set your first alarm" with none, a dashed "Add alarm" row with one or two; none when full and no footer sentence); the same screen for 0, 1, 2 and 3 alarms, with the meter ("Up to 3" / "N of 3" / orange "3 of 3", on the first list heading) opening "How alarms work"; deleting the last alarm morphs the add card, never swaps the screen; removing one (after the question) reopens a place; the Reason picker lists only the alarm's own Reason and Reasons no alarm plays; the reducer refuses a fourth alarm
- [ ] Swiping an alarm away or pressing Delete in the editor asks "Delete this alarm?" first; Cancel (or tapping outside) brings the card home, and no message appears and disappears afterwards
- [ ] The day picker shows a hint only when no day is chosen
- [ ] Onboarding paywall has no path forward except subscribing, and `onboarded` flips only after it
- [ ] Account deletion actually deletes cloud data, not just local state
- [ ] Every write path works offline and syncs on reconnect

- [ ] Reasons are editable: every field is changed on Reason detail, held, and applied by one Save Changes (Discard reverts; leaving with changes asks first); Security Rules allow updates to `name`, `focus`, `focusNote`, `purpose`, `why`, `style`, `voice`, `length` by the owner (voice and length are not plan-gated); the server rate-limits regenerations
- [ ] Editing `purpose`, `why`, `style`, `voice` or `length` replaces the message: written at Save for one credit with an alarm on, let go with none on; at zero credits the edit does not save and the credits sheet opens; renaming or changing the area writes nothing
- [ ] Credits: 100 a month from the first day (the trial included), resetting every 30 days from the subscription start on every plan; a resubscribe starts a full month; pack credits never reset; at zero, setting an alarm whose Reason has never had a message shows "This alarm won't speak yet" first
- [ ] Alarms and Reasons share one add card (`AddCard`): the dashed empty-item card with an orange plus when the list is empty, a quiet dashed row ("Add alarm" / "New Reason") at the end of the list otherwise; no floating button on either tab; adding the first item and removing the last morph the card, never swap the screen
- [ ] Only opening Eala (Hear your reason, the Live Activity or the unlocked banner's arrow) ends a ring; slide to stop only silences it, the lock screen's Live Activity shows when it rings again, the same message rings again after the snooze length, and ringing stops for good after 30 minutes
- [ ] Reason detail shows every field as a tappable row (Purpose and Why open a text sheet with starters and a microphone; Why may be cleared); a changed row turns orange and a Save Changes / Discard bar appears; the alarm card shows "Preparing your message" after a rewriting save
- [ ] Alarm editor shows no status line, transcript or player; the alarm card shows "Preparing your message" → "Message ready" transiently, and "Message not written yet" or "New message from Nov 14 · Add credits" as its only standing sentences
- [ ] Switching an alarm on needs no confirmation; only the plan check (paywall) can interrupt it; ON → OFF never does
- [ ] Saving an alarm never asks for an account (§11.2); only subscribing from the in-app paywall does
- [ ] The in-app paywall never offers a trial; only onboarding's Annual plan does
- [ ] Outside Settings › Prototype, no user-facing string says "wake-up" as a noun, "take", "shelf" or "generation", and none names a time of day except onboarding's Name greeting, which reads the clock; `npm run audit:copy` passes

---

## 16. Where the prototype stops short of this spec

Everything above is the target. These are the places the prototype does less, so nobody ports a gap as if it were a behaviour. None of them changes a rule; each is something the real build has to add.

**Rules the prototype does not enforce**

- **One consumption per day.** The spec says only the first dismissal of a calendar day consumes a message (§6). The prototype writes one `wakeLog` entry per day, as specced, but *every* dismissal dispatches `consumeTake`, so two alarms on different Reasons dismissed the same day each advance their own pool. Whether that is acceptable is BACKEND_ARCHITECTURE.md D5.
- **Automatic lapse.** Nothing lapses by itself. `lapse` is dispatched only from Settings › Prototype; the prototype does not notice `trialEnd` or a grace period passing, and does not apply the offline lapse-on-open of §10.1. The real build derives the state from the cached entitlement on open and from webhooks.
- **Plan-less shelves.** `plannedDepth` does not check the plan (it relies on lapse switching every alarm off and on arming being gated), so the top-up would still write for an enabled alarm on a lapsed account if one could exist. The three-alarm limit (§4) is likewise enforced by the reducer only.
- **The fresh-message meter is client-side.** It lives in local state and is trusted by nothing; the real one is a per-account counter written only by the server (BACKEND_ARCHITECTURE.md §6.1). Settings › Prototype can set it to 10, 3 or 0 and restart the month. The pack is bought through the simulated sheet, with no receipt, no restore and no refund handling.
- **Server-side everything.** Security Rules, the 180-character cap on the server (the client caps it in the composer, which is the only entry point), rate limits, moderation, language detection and prompt-injection handling (§8) do not exist, and Reason edits are checked by nothing but the client.
- **No model and no voice.** Messages come from a local template writer (`data/mock.js`); a take's duration is estimated from word count at 2.4 words a second; audio is a simulated playhead. `lib/prompt.js` holds the system prompt, `buildPrompt` and `validate` (the §7 contract) and is exercised by nothing — the writer's output is not validated, because it is written to the rules. A Reason with no message (for instance one `pending` on the credit meter) rings and then goes straight to the quote; the voice message is skipped (§12).
- **No store.** Purchases go through a simulated payment sheet and the plan is a local value. "Restore" (on both paywalls) only reports there is nothing to restore. There is no receipt validation, no webhook and no resume line on resubscribe (§10.1) — nothing is announced.
- **Quotes and notifications.** No notification is sent (the prototype has no OS; Settings › Prototype › *Lock screen* stands in, §11.0b), there is no share link and no server-side ranking (§11.0a).
- **The one-time offer** is a second price in the prototype; there is no separate store product, and trial eligibility is not checked (§11).

**Onboarding gaps**

- **The first message is the local writer's.** Onboarding plays no message; the Reason's first message is written by the local template writer when the alarm is switched on, and voiced by the simulated clock when it rings. The real build writes it on the server (one credit) and renders the real voice.
- **The trial reminder is not delivered.** The rule is built (`trialReminder` in `lib/entitlements.js`: the day before a trial that will renew converts, in the Trial & billing category), Settings › Subscription names its date ("We'll remind you on October 23.") or why it won't come, and Settings › Prototype › *Lock screen* shows the notification. The real build schedules it as a local notification when the trial starts (asking for notification permission after the purchase only if the onboarding Notify step was skipped or declined), removes it on cancel, and backs it with a server push.
- **`firstStep` is never collected** (§1); the backend document lists it as create-only, and `validate()` does not check that a message steers toward it.

**Behaviours modelled more simply**

- The pool is one list of takes per Reason (length 1) plus the `message`/`duration` mirror (§6); there is no played flag and no Storage cleanup.
- Sign-in is a button that sets a provider; "Signed in with Apple" is a label, not an identity.
- Ringing again after slide to stop runs in the foreground via `useAlarmScheduler`; a closed tab rings nothing, and a one-off alarm switches itself off as it *rings* (BACKEND_ARCHITECTURE.md, D4, says on dismiss).
- State is one reducer persisted to `localStorage` under `eala.prototype.v1`. Both OS permissions are persisted too, only because there is no OS to ask; a real build reads them on every foreground and never stores them.
