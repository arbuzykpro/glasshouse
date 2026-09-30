# Getting an installable app

Read this before you spend anything. Most of this repo works without paying.

---

## What you get for free, right now

Push the repo to **GitHub as a public repo** and every push runs a real Mac
build for free. It compiles all the Swift, and it will tell you if you broke
something. That's genuinely useful and costs nothing.

You get a simulator build. **You cannot put that on your iPhone.** Apple
requires a signature it recognises, and there's no free way to produce one
without a Mac.

| | Cost | What you get |
| --- | --- | --- |
| GitHub Actions, public repo | Free | Compiles everything. Catches errors. No installable app. |
| Rented Mac + free Apple ID | ~$1–4 | Real `.ipa`. Works on your phone. Expires in 7 days. |
| $99/year Apple Developer | $99 | Everything above, no expiry, and you never need a Mac again. |

The $99 is Apple's requirement for signing without a computer in front of you.
It's deliberate. There's no clever workaround.

---

## Before you start: change the bundle ID

`com.example.glasshouse` is a placeholder. Apple will reject it. Pick something
only you will use, and change it in **two** places:

1. `project.yml` — `PRODUCT_BUNDLE_IDENTIFIER` for `Glasshouse` and
   `GlasshouseWidgetExtension`
2. `.github/workflows/build.yml` — the two keys inside `provisioningProfiles`

Make the app one level deeper, e.g. `com.yourname.glasshouse`. The widget
extension stays `<app id>.widgets`.

---

## One-time setup (needs the $99 account)

### 0. Install Git for Windows

You need `git` anyway to upload the repo, and it bundles `openssl`, which the
next few steps need. One install covers both.

### 1. Generate a certificate request (CSR)

This is a "please sign this key" file. It contains a fresh private key plus
your details.

Open Git Bash and run:

```bash
openssl req -new -newkey rsa:2048 -nodes \
  -keyout glasshouse-key.pem \
  -out glasshouse.csr \
  -subj "/CN=Apple Development: Your Name"
```

Keep `glasshouse-key.pem` somewhere safe. If you lose it, you start over.

### 2. Ask Apple to sign it

Go to <https://developer.apple.com/account/resources/certificates> and sign in.

- **Certificates** → the `+` button → **Apple Development** → upload
  `glasshouse.csr` → download the `.cer`

### 3. Turn the certificate into a `.p12`

The `.cer` is the lock; the `.pem` is the key. Apple wants them combined.

```bash
openssl x509 -inform DER -in "Apple Development YourName.cer" -out cert.pem
openssl pkcs12 -export -out cert.p12 -inkey glasshouse-key.pem -in cert.pem
```

`cert.p12` is your secret. Anyone with it plus your profile can sign as you.
Treat it like a password.

### 4. Register your iPhone

<https://developer.apple.com/account/resources/devices> → `+`

You need the **UDID** — a 40-character string unique to your phone. You may
already have it: **Sideloadly shows it** on its main screen. Alternatives are
3uTools or iMazing, both free on Windows.

### 5. Create a provisioning profile

<https://developer.apple.com/account/resources/profiles> → `+`

- Type: **iOS App Development**
- Select your App ID (register a new one matching your bundle ID if needed)
- Select your certificate from step 2
- Select your iPhone from step 4
- Name it `GlasshouseProfile`
- Download the `.mobileprovision`

The name matters — it has to match the `PROVISIONING_PROFILE_NAME` secret.

---

## Add it to GitHub

Go to your repo → **Settings** → **Secrets and variables** → **Actions** →
**New repository secret**, six times:

| Secret name | Paste in |
| --- | --- |
| `APPLE_CERT_P12_BASE64` | see below |
| `APPLE_CERT_PASSWORD` | the password you chose in step 3 |
| `APPLE_TEAM_ID` | developer.apple.com → Membership, 10 characters |
| `PROVISIONING_PROFILE_BASE64` | see below |
| `PROVISIONING_PROFILE_NAME` | `GlasshouseProfile` |
| `KEYCHAIN_PASSWORD` | any random string |

For the two base64 secrets:

```bash
base64 -i cert.p12 -o cert-p12.txt
base64 -i "GlasshouseProfile.mobileprovision" -o profile.txt
```

On Windows with Git Bash, `base64 -w0` wraps at 0 characters (no newlines).
PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.p12"))`

Then the **Actions** tab → **Run workflow**. Download the
`Glasshouse-ipa` artifact, unzip it, and drop the `.ipa` into Sideloadly.

---

## If something fails

Read the log in the failed step. The usual ones:

**`errSecInternalComponent`** — the keychain partition list wasn't set. Check
that the `set-key-partition-list` step ran and didn't error.

**`No profiles for 'com.example.glasshouse'`** — bundle ID mismatch, or the
profile doesn't cover that App ID. Recheck step 5 against your actual ID.

**`Unable to find a destination`** — Xcode version drift. The workflow pins
`/Applications/Xcode_16.2.app`; if the runner image changed, run
`ls /Applications | grep Xcode` and update that path.

**`provisioning profile ... doesn't include signing certificate`** — the
profile was made with a different certificate. Delete and recreate it in step 5
using the one from step 2.

**Profile expired** — development profiles last 7 days, free or paid. Regenerate
in step 5. The $99 account extends the *account*, not the profile; a new
profile is still needed each week.
