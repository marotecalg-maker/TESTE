# Building Rosome for iOS with Codemagic (no Mac)

The repo already contains a ready `codemagic.yaml` with two workflows.

## 1. Push the code to GitHub

Create an empty repo on GitHub (e.g. `rosome`), then:

```bash
cd D:\kioku
git remote add origin https://github.com/<your-user>/rosome.git
git push -u origin main
```

## 2. Connect Codemagic

1. Sign up at [codemagic.io](https://codemagic.io) (free tier includes 500 build min/month).
2. **Add application** → connect your GitHub → pick the `rosome` repo.
3. Choose **"codemagic.yaml"** as the configuration (it's detected automatically).

## 3. Quick test build — no Apple account needed

- Run the **`ios-test-build`** workflow.
- It compiles the app unsigned and produces a `.app` you can run on the iOS
  Simulator or inspect. (An unsigned build can't be installed on a physical
  iPhone — that needs signing, see step 4.)

## 4. App Store / TestFlight — needs Apple Developer Program ($99/yr)

One-time setup:

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/).
2. In **App Store Connect**, create the app record with bundle id
   **`com.rosoume.kioku`**, and note its numeric **Apple ID** (shown under
   *App Information*).
3. Create an **App Store Connect API key**
   (Users and Access → Integrations → keys), download the `.p8`.
4. In **Codemagic → Teams/App settings → Integrations → App Store Connect**,
   add the key and name it **`CodemagicAppStoreKey`** (this exact name is used
   in `codemagic.yaml`).
5. Edit `codemagic.yaml` → in `ios-appstore`, set `APP_STORE_APPLE_ID` to your
   app's numeric Apple ID.
6. Run the **`ios-appstore`** workflow. It signs the IPA, auto-picks the next
   build number, and uploads to **TestFlight**. Flip `submit_to_app_store: true`
   when you want a public release.

## Store listing you'll also need

- **Privacy Policy URL** → `https://sites.google.com/view/rosomprivay/accueil`
- **Support URL** → `https://sites.google.com/view/rosomesuppor/accueil`
  (make sure both Google Sites pages are Published / public)
- App icon is generated (1024 included); screenshots you capture from a
  device/simulator.

## Notes

- Bundle id is `com.rosoume.kioku` across Android, iOS, and `codemagic.yaml`.
- The Flutter project codename is `kioku`; the public app name is **Rosome**.
