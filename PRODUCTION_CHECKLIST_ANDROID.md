# 🚀 Android Production Checklist - Google Play Store

**Target:** BeatYourRival Android App  
**Goal:** Publish to Google Play Store  
**Timeline:** 5-7 days

---

## ✅ PRE-FLIGHT CHECKLIST

### Phase 1: Core Functionality (COMPLETE ✅)
- [x] User authentication (Firebase Auth)
- [x] Battle creation and acceptance
- [x] Video recording (camera)
- [x] Video upload (Firebase Storage)
- [x] Video playback
- [x] Turn-based gameplay
- [x] ELO rating system
- [x] Activity feed
- [x] User profiles
- [x] Search functionality
- [x] Leaderboard
- [x] Friends system

### Phase 2: Premium Features (IN PROGRESS)
- [x] 3-day free trial system
- [x] Premium user detection
- [x] Trial expiration logic
- [x] Access control (battles locked after trial)
- [ ] **Subscribe screen** ← NEXT TASK
- [ ] **Stripe payment integration** ← NEXT TASK
- [ ] Payment flow testing
- [ ] Premium badge display

### Phase 3: Production Requirements
- [ ] App signing (release keystore)
- [ ] Build release APK/AAB
- [ ] Privacy Policy
- [ ] Terms of Service
- [ ] App icon (512x512, 1024x1024)
- [ ] Screenshots (phone, tablet)
- [ ] Feature graphic (1024x500)
- [ ] App description
- [ ] Store listing content
- [ ] Content rating questionnaire
- [ ] Google Play Console setup

---

## 🎯 IMMEDIATE TASKS (Days 1-3)

### Task 1: Build Subscribe Screen (Day 1-2)

**What to build:**
- Screen that shows after trial expires
- Display: "Your 3-day trial has ended"
- Button: "Subscribe to Premium - $9.99/month"
- Benefits list:
  - ✅ Unlimited battles
  - ✅ Auto-record all performances
  - ✅ Watch replays anytime
  - ✅ No ads
- "Restore Purchase" button (for users who already paid)

**Location:** `lib/screens/premium/subscribe_screen.dart`

**Navigation:** Show when:
- User tries to create/accept battle after trial expires
- User clicks "Upgrade to Premium" in profile

---

### Task 2: Stripe Integration (Day 2-3)

**Setup required:**
1. Create Stripe account
2. Get Stripe publishable key
3. Get Stripe secret key (store in Firebase Functions)
4. Configure Flutter Stripe package (already installed ✅)
5. Create Stripe product/price (subscription)
6. Test payment flow

**Payment flow:**
1. User clicks "Subscribe to Premium"
2. Stripe payment sheet opens
3. User enters card details
4. Payment processes
5. Update user document: `isPremium: true`, `premiumExpiresAt: null`
6. Show success message
7. User can now access battles

---

### Task 3: App Signing & Build (Day 3-4)

**Generate release keystore:**
```bash
keytool -genkey -v -keystore beatrivals-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias beatrivals
```

**Update `android/key.properties`:**
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=beatrivals
storeFile=beatrivals-release.jks
```

**Update `android/app/build.gradle`:**
- Set `versionName` (e.g., "1.0.0")
- Set `versionCode` (e.g., 1)
- Configure signing config

**Build release:**
```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

---

### Task 4: Store Assets & Content (Day 4-5)

**Required assets:**

1. **App Icon** (already have? Check `android/app/src/main/res/mipmap-*/`)
   - 48x48, 72x72, 96x96, 144x144, 192x192
   - Generate with: https://icon.kitchen or https://appicon.co

2. **Feature Graphic** (1024x500 px)
   - Main promotional banner
   - Shows in Play Store search results
   - Design with Canva or Figma

3. **Screenshots** (minimum 2, recommended 8)
   - Phone: 1080x1920, 1440x2560, or actual device resolution
   - Capture screens:
     - Login screen
     - Battle list
     - Battle detail
     - Video recording
     - Video playback
     - Profile
     - Leaderboard
     - Activity feed

4. **Promotional Video** (optional but recommended)
   - 30 seconds - 2 minutes
   - Show app in action
   - YouTube link

---

### Task 5: Legal Documents (Day 5)

**Privacy Policy (REQUIRED):**
- What data you collect (email, username, profile pic, videos)
- How you use data (battles, leaderboard, matchmaking)
- Third-party services (Firebase, Stripe, Firebase Storage)
- User rights (delete account, data export)
- Generator: https://www.freeprivacypolicy.com/

**Terms of Service (REQUIRED):**
- User responsibilities
- Content guidelines (no inappropriate content)
- Battle rules
- Payment terms
- Account termination
- Generator: https://www.termsofservicegenerator.net/

**Where to host:**
- Option 1: GitHub Pages (free, easy)
- Option 2: Firebase Hosting (already using Firebase)
- Option 3: Your website

**URLs needed:**
- `https://yoursite.com/privacy-policy`
- `https://yoursite.com/terms-of-service`

---

### Task 6: Google Play Console Setup (Day 5-6)

**1. Create Google Play Developer Account:**
- Go to: https://play.google.com/console
- Pay one-time $25 fee
- Fill out account details
- Verify identity (bank account or ID)

**2. Create App:**
- Click "Create app"
- Enter app name: "BeatYourRival"
- Default language: English (US)
- App type: App
- Free or paid: Free (with in-app purchases)

**3. Store Presence > Main Store Listing:**
- **App name:** BeatYourRival
- **Short description:** (80 chars max)
  "Battle rappers, singers, and performers in epic video showdowns!"
- **Full description:** (4000 chars max)
  ```
  🎤 BeatYourRival - The Ultimate Performance Battle App!

  Challenge friends and rivals to epic video battles! Record your 
  best performance, let your opponent respond, and let the community 
  decide who wins!

  ✨ Features:
  • 🎥 Record 90-second performance videos
  • ⚔️ Turn-based video battles
  • 🏆 ELO ranking system
  • 🎬 Watch performances anytime
  • 👥 Find opponents worldwide
  • 📊 Track your battle stats
  • 🎯 Multiple genres: Hip Hop, R&B, Pop, Rock, and more!

  🎁 Free Trial:
  • 3 days full access
  • No credit card required
  • Try all features

  💎 Premium:
  • Unlimited battles
  • Auto-record all performances
  • Watch replays forever
  • No ads

  Perfect for:
  • Rappers & MCs
  • Singers & vocalists
  • Beatboxers
  • Dancers
  • DJs
  • All performers!

  Download now and show the world your talent! 🚀
  ```
- **App icon:** 512x512 PNG
- **Feature graphic:** 1024x500 JPG/PNG
- **Screenshots:** Upload 2-8 images
- **Category:** Music & Audio (or Entertainment)
- **Tags:** battle, rap, music, performance, video, competition
- **Contact email:** your-email@example.com
- **Privacy policy URL:** https://yoursite.com/privacy-policy

**4. Store Presence > Store Settings:**
- **App category:** Music & Audio
- **Tags:** music, battle, rap, video, performance

**5. Policy > App Content:**
- **Privacy Policy:** Provide URL
- **Ads:** Select "No, my app does not contain ads"
- **Content rating:** Complete questionnaire
  - App includes: User-generated content
  - Users can interact: Yes
  - Age rating: 13+ (or 17+ if allowing explicit content)
- **Target audience:** Ages 13+
- **News app:** No

**6. Policy > App Access:**
- **All app features available:** Yes
- Or provide test account if login required

**7. Policy > Data Safety:**
- **Data collected:**
  - Email address (required for login)
  - Username
  - Profile picture (optional)
  - Video recordings (performances)
- **Data usage:**
  - App functionality (battles, profiles)
  - Analytics (Firebase Analytics)
- **Data security:**
  - Data encrypted in transit (HTTPS)
  - Data encrypted at rest (Firebase)
  - Users can request data deletion
- **Data sharing:**
  - Videos shared with other users (public battles)
  - No data sold to third parties

**8. Release > Production:**
- **Upload AAB file:** `app-release.aab`
- **Release name:** "v1.0.0 - Initial Release"
- **Release notes:**
  ```
  🎉 Welcome to BeatYourRival!

  Features in v1.0.0:
  • Record and upload performance videos
  • Challenge opponents to video battles
  • Turn-based gameplay
  • ELO ranking system
  • Activity feed and notifications
  • User profiles and stats
  • Leaderboard
  • Friends system
  • 3-day free trial
  • Premium subscription

  Known issues:
  • None

  Coming soon:
  • Video editing features
  • Group battles
  • Live streaming
  • More performance categories
  ```

**9. Review and Publish:**
- Complete all required sections
- Click "Send for review"
- Wait for Google review (1-7 days typically)

---

## 🔧 CODE UPDATES NEEDED

### 1. Subscribe Screen (NEW FILE)

**Create:** `lib/screens/premium/subscribe_screen.dart`

**Features:**
- Show trial status
- Display premium benefits
- Stripe payment button
- Loading states
- Success/error handling

**I can build this for you!** (Estimate: 2-3 hours)

---

### 2. Version & Build Configuration

**Update:** `pubspec.yaml`
```yaml
version: 1.0.0+1  # Format: major.minor.patch+build
```

**Update:** `android/app/build.gradle`
```gradle
android {
    defaultConfig {
        applicationId "com.beatyourrival.app"  // Your package name
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

---

### 3. App Signing Configuration

**Create:** `android/key.properties` (KEEP THIS SECRET!)
```properties
storePassword=your-secure-password
keyPassword=your-secure-password
keyAlias=beatrivals
storeFile=../beatrivals-release.jks
```

**Update:** `android/app/build.gradle`
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

### 4. Remove Debug Code

**Search and remove:**
- `print()` statements (use proper logging)
- Test API keys
- Debug flags
- Console.log equivalents

---

### 5. Optimize Performance

**Check:**
- [ ] Images optimized (compress with TinyPNG)
- [ ] Video upload limits (max 50 MB recommended)
- [ ] Network error handling
- [ ] Offline mode graceful degradation

---

## 📱 TESTING CHECKLIST

### Functional Testing
- [ ] User registration works
- [ ] Login/logout works
- [ ] Video recording works
- [ ] Video upload completes
- [ ] Video playback works
- [ ] Battle creation works
- [ ] Battle acceptance works
- [ ] Turn flipping works
- [ ] Voting works
- [ ] ELO updates correctly
- [ ] Trial expires correctly
- [ ] Premium access works
- [ ] Payment processing works

### Device Testing
- [ ] Test on Android 8.0 (API 26)
- [ ] Test on Android 10.0 (API 29)
- [ ] Test on Android 13.0 (API 33)
- [ ] Test on small screen (5")
- [ ] Test on large screen (6.5"+)
- [ ] Test on tablet

### Network Testing
- [ ] WiFi connection
- [ ] Mobile data connection
- [ ] Slow network (3G simulation)
- [ ] Network interruption handling
- [ ] Offline mode behavior

### Edge Cases
- [ ] No internet connection
- [ ] Low storage space
- [ ] Camera permission denied
- [ ] Microphone permission denied
- [ ] User logs out mid-battle
- [ ] App killed during upload
- [ ] Multiple users on same device

---

## 🐛 KNOWN ISSUES TO FIX

### Before Publishing:
- [ ] iOS build (currently failing - Ruby FFI issue)
  - **Decision:** Launch Android first, fix iOS later
- [ ] Camera preview aspect ratio on some devices
  - **Priority:** Medium (works but not perfect)

### Future Updates:
- [ ] Video compression (reduce file size)
- [ ] Video thumbnails (preview before watching)
- [ ] Better upload progress indicator
- [ ] Offline video recording (upload later)

---

## 📊 METRICS TO TRACK

**After launch, monitor:**
- Downloads (Google Play Console)
- Active users (Firebase Analytics)
- Trial conversions (% who subscribe)
- Battle completion rate
- Video upload success rate
- Crash rate (Firebase Crashlytics)
- User retention (1-day, 7-day, 30-day)

---

## 🎯 LAUNCH PLAN

### Day 1-2: Subscribe Screen
- Build subscribe UI
- Add Stripe payment flow
- Test payments (use Stripe test mode)

### Day 3-4: App Signing & Build
- Generate release keystore
- Configure signing
- Build release AAB
- Test release build

### Day 5: Legal & Assets
- Write Privacy Policy
- Write Terms of Service
- Create store assets
- Prepare screenshots

### Day 6: Google Play Console
- Setup developer account
- Create app listing
- Upload assets
- Fill out all required sections

### Day 7: Submit & Launch
- Upload AAB
- Submit for review
- Monitor review status
- Launch! 🚀

---

## ✅ FINAL CHECKLIST BEFORE SUBMISSION

- [ ] All features tested and working
- [ ] No crashes or critical bugs
- [ ] Privacy Policy URL active
- [ ] Terms of Service URL active
- [ ] Release AAB built and tested
- [ ] App icon looks good
- [ ] Screenshots are clear and compelling
- [ ] Store description is accurate
- [ ] Content rating completed
- [ ] Data safety section filled
- [ ] Pricing set correctly (Free with IAP)
- [ ] All Google Play Console sections complete
- [ ] Test account provided (if needed)
- [ ] Payment flow tested end-to-end

---

## 🎉 POST-LAUNCH

**After approval:**
1. **Monitor reviews** - Respond within 24 hours
2. **Track metrics** - Watch Firebase Analytics
3. **Fix bugs** - Release updates as needed
4. **Gather feedback** - Listen to users
5. **Plan updates** - Roadmap for v1.1, v1.2, etc.

**Update frequency:**
- Critical bugs: Same day
- Minor bugs: Weekly
- New features: Monthly

---

## 📞 SUPPORT

**Questions during setup?**
- Google Play Console Help: https://support.google.com/googleplay/android-developer
- Flutter Release Docs: https://docs.flutter.dev/deployment/android
- Stripe Docs: https://stripe.com/docs/payments/accept-a-payment

---

**Ready to start?** Let's build the subscribe screen first! 🚀
