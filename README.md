# Glasshouse

A customization app for iOS 17+ that owns the surfaces the system still lets
an ordinary app own: **Live Activities on the Lock Screen, the Dynamic Island,
and generated wallpapers.**

## What this is, and what it is not

Sideloading with **Sideloadly** does not jailbreak your phone. It controls how
an IPA is signed and installed, not what the app is permitted to touch. The app
still runs in Apple's sandbox, in its own process, with its own container.

That rules out anything living in another process:

| Surface | Status | Why |
| --- | --- | --- |
| Live Activity layout | **Full control** | iOS renders the SwiftUI you supply |
| Dynamic Island content | **Full control** | Same mechanism, fixed island geometry |
| Lock Screen card | **Full control** | Drawn by the widget extension |
| Accent / glass tint | **Full control** | Passed through to the extension |
| Wallpaper | **Full control** | Generated and saved locally |
| Home Screen icon grid | Not reachable | SpringBoard is a separate process |
| Control Center modules | Not reachable | Separate process, private frameworks |
| Status bar contents | Not reachable | Separate process |
| System Liquid Glass tint | Not reachable | Set by the OS, not by clients |

Real system-wide theming needs a jailbreak, or an unpatched kernel bug.
TrollStore's unsandboxing came from a CoreTrust flaw Apple closed in iOS 18.1
and has stayed closed. This app takes the other route: go deep on the one
surface that is genuinely yours, and say so plainly in-app (see the Guide tab).

## Building

Requires macOS — but you do not need to own one. Push this to a **public**
GitHub repo and every push runs a real Mac build on GitHub's runners, which
are free for public repos. That compiles all the Swift and catches errors,
at zero cost.

```bash
git init
git add .
git commit -m "Glasshouse"
git branch -M main
git remote add origin https://github.com/YOURNAME/glasshouse.git
git push -u origin main
```

Watch the **Actions** tab. `xcodegen` installs itself, the project generates,
everything compiles. The artifact is a simulator build — proof it works, not
something you can sideload onto a phone.

To get something **onto your iPhone** you need a signature Apple recognises.
That means either a rented Mac (~$1/hr) or the $99/year Apple Developer
account. **[SIGNING.md](SIGNING.md)** covers both, plus the six GitHub secrets
that turn this pipeline into a real `.ipa` builder.

By hand, with a Mac:

```bash
brew install xcodegen          # if you do not have it
cd Glasshouse
xcodegen generate
open Glasshouse.xcodeproj
```

Then in Xcode: select the `Glasshouse` scheme, pick your device, and set your
signing team under **Signing & Capabilities**. Change `PRODUCT_BUNDLE_IDENTIFIER`
away from `com.example` first, or provisioning will fail.

Sources use `@Observable`, so the deployment target is iOS 17.

## Getting it onto the iPhone

See **[SIGNING.md](SIGNING.md)** — it is the fiddly part and it has real
failure modes. Short version:

- **Rented Mac, free Apple ID** — Xcode → Archive → Organizer → Distribute.
  Costs about $1, works today, expires in 7 days.
- **$99/year, no Mac ever** — create the certificate and profile once on
  developer.apple.com, paste them into GitHub as secrets, and `build.yml`
  emits a signed `.ipa` on demand. Profiles still expire weekly; the build
  just regenerates.

## Live Activities

The user must have them enabled. There is no public deep link to that pane, so
the app falls back to its own settings page:

**Settings › General › Accessibility › Live Activities**

A running activity shows:

- In the **Dynamic Island** while unlocked — `compactLeading` (a symbol),
  `compactTrailing` (a circular gauge), and a `minimal` glyph when several
  activities compete
- On the **Lock Screen** after you lock the device, as a card laid out by
  `GlassLiveActivity.swift`

`Activity.request` throws instead of failing quietly, and returns nothing if
`ActivityAuthorizationInfo().areActivitiesEnabled` is false. Both are handled
in `ActivityController`.

## Layout

```
Glasshouse/
├── project.yml                          # XcodeGen manifest — source of truth
├── Sources/
│   ├── Shared/                          # compiled into BOTH targets
│   │   ├── GlassActivityAttributes.swift # ActivityAttributes + preset enum
│   │   ├── GlassTheme.swift              # theme model + UserDefaults store
│   │   └── HexColor.swift
│   ├── App/
│   │   ├── GlasshouseApp.swift          # entry, ThemeStoreController
│   │   ├── RootView.swift
│   │   ├── StudioView.swift             # compose + launch
│   │   ├── ThemesView.swift             # editor + wallpaper export
│   │   ├── ActivityController.swift
│   │   └── GuideView.swift              # capability disclosure
│   └── Widget/
│       ├── GlasshouseWidgetBundle.swift
│       └── GlassLiveActivity.swift      # Lock Screen + Dynamic Island
```

`Sources/Shared` is a member of both targets. That is required — the extension
needs `GlassActivityAttributes` to compile `ActivityConfiguration`, and
`ActivityAttributes` must be identical in both. If you see "cannot find type",
check the target memberships in `project.yml` before anything else.

## Where to extend it

- **New Lock Screen layout** — add a case to `GlassActivityPreset`, then a
  matching `some View` in `LockScreenCard`. The island is untouched; its
  geometry is fixed by ActivityKit.
- **Timer that ticks** — put a relative `Text(timerInterval:)` in the Lock
  Screen view. Do not poll with `update`; it burns the activity's update budget
  and the system throttles you.
- **Push updates** — `start(theme:state:)` currently passes `pushType: nil`.
  Set it to `.token` and forward the token to your own server for remote
  updates. The token arrives in `activity.pushTokenUpdates`.
- **App icon** — `Assets.xcassets` is not generated; add one in Xcode if you
  want a custom home screen icon for Glasshouse itself.
