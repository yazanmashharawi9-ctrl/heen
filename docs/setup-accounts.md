# Account setup (done once, in a browser)

Everything here needs your own login, so it is done by you. Each step says
where its result goes. Nothing in this list is ever committed to the repository.

You already have: Apple Developer (same team as Tubes), Google Play Console, Cloudflare.

## 1. GitHub repository (public)

Create `heen` under your account, public, then push this folder to it.
Public repos get unlimited free minutes on GitHub-hosted Macs, which is what
builds the iOS app.

In **Settings ▸ Code security**, make sure **Push protection** is on.

## 2. Apple

1. **App Store Connect API key** — reuse the Tubes one (Team Key, Admin).
   Put it in `tools/asc/.env` as in Tubes (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`).
2. **Bundle id, Push capability, profile** — no browser needed:
   ```powershell
   python tools/asc/setup_signing.py --register-bundle-id --key-path ..\..\GitHub\Tubes\tools\asc\out\private_key.pem --set-github-secrets
   ```
   This reuses Tubes' distribution certificate (no new certificate slot), registers
   `com.mashharawi.heen`, enables Push Notifications, creates the "Heen App Store"
   profile and uploads the three signing secrets to GitHub.
3. **API key secrets for uploads**, as in Tubes:
   ```powershell
   gh secret set ASC_KEY_ID --body $env:ASC_KEY_ID
   gh secret set ASC_ISSUER_ID --body $env:ASC_ISSUER_ID
   [Convert]::ToBase64String([IO.File]::ReadAllBytes($env:ASC_KEY_PATH)) | gh secret set ASC_KEY_B64
   ```
4. **App record** — App Store Connect ▸ Apps ▸ + ▸ New App: name "Heen" (or «حِين»),
   bundle id `com.mashharawi.heen`, primary language Arabic.
5. **APNs key** (for weather pushes, M2) — developer.apple.com ▸ Certificates, IDs &
   Profiles ▸ Keys ▸ + ▸ enable *Apple Push Notifications service (APNs)*. Download the
   `.p8` once. It goes to Supabase secrets (step 4), never to GitHub.

## 3. Google Play

1. Play Console ▸ Create app: "Heen", free, package `com.mashharawi.heen`.
2. Create an **upload keystore** locally:
   ```powershell
   keytool -genkeypair -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Keep `upload.jks` and its passwords backed up somewhere safe outside the repo, then:
   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload.jks")) | gh secret set ANDROID_KEYSTORE_B64
   gh secret set ANDROID_KEYSTORE_PASSWORD
   gh secret set ANDROID_KEY_ALIAS --body upload
   gh secret set ANDROID_KEY_PASSWORD
   ```
3. The **first** App Bundle must be uploaded by hand (Play Console ▸ Testing ▸ Internal).
   Download it from the `release-android` workflow's artifact.
4. For automated uploads afterwards: Google Cloud ▸ service account with Play Console
   access (Users and permissions ▸ invite the service account's email, "Release" rights) →
   `gh secret set PLAY_SERVICE_ACCOUNT_JSON < play-service-account.json`.

## 4. Supabase

1. supabase.com ▸ New project "heen" (region close to most users, e.g. Frankfurt).
2. Link and push the schema from this folder:
   ```bash
   supabase login
   supabase link --project-ref <ref>
   supabase db push
   supabase functions deploy api tick send
   ```
3. Secrets (M2, when weather pushes start):
   ```bash
   supabase secrets set APNS_TEAM_ID=2G5KY3V739 APNS_KEY_ID=<key id> APNS_BUNDLE_ID=com.mashharawi.heen
   supabase secrets set APNS_PRIVATE_KEY="$(cat AuthKey_<key id>.p8)"
   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat fcm-service-account.json)"
   ```
4. The app needs the project URL and the **publishable** key (safe to ship in the app).

## 5. Firebase — Android push delivery only

Only Cloud Messaging is used; no database, auth, analytics or crash reporting.

1. console.firebase.google.com ▸ Add project "heen-push" (turn Google Analytics **off**).
2. Add an Android app `com.mashharawi.heen`, download `google-services.json` →
   `gh secret set GOOGLE_SERVICES_JSON < google-services.json` (never commit it).
3. Project settings ▸ Service accounts ▸ Generate new private key → that JSON is
   `FCM_SERVICE_ACCOUNT` in Supabase (step 4.3).
4. In Google Cloud, restrict the API key in `google-services.json` to the Android app.

## 6. Cloudflare (website, M2)

Pages project "heen" for the website; an API token with *Cloudflare Pages: Edit* →
`gh secret set CLOUDFLARE_API_TOKEN`.
