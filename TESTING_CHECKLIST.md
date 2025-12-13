# BeatYourRival Testing Checklist

**Purpose**: Comprehensive testing guide for Android + iOS cross-platform functionality  
**Status**: Both apps successfully deployed and running  
**Date Started**: December 13, 2025

---

## 📱 **Test Environment**

- ✅ **Android Device**: Connected and app installed
- ✅ **iPhone Device**: Connected and app installed
- ✅ **Firebase**: beatrivals-d8d2c project
- ✅ **Network**: Both devices on internet

---

## 🎯 **Testing Strategy**

We'll test in this order:
1. **Core Features** (basic functionality on each device)
2. **Cross-Platform Sync** (Android ↔ iOS communication)
3. **Battle System** (the main feature!)
4. **Edge Cases** (error handling, offline, etc.)

---

## ✅ **PHASE 1: Basic Functionality Tests**

### **Test 1.1: Registration & Authentication**

#### **On Android:**
- [ ] Open app
- [ ] Tap "Register" / "Sign Up"
- [ ] Enter email: `android.user@test.com`
- [ ] Enter password: `TestPass123!`
- [ ] Enter display name: `AndroidWarrior`
- [ ] Submit registration
- [ ] **Expected**: Account created, logged in, see home screen
- [ ] **Note**: Check if email verification is sent

#### **On iPhone:**
- [ ] Open app
- [ ] Tap "Register" / "Sign Up"
- [ ] Enter email: `ios.user@test.com`
- [ ] Enter password: `TestPass123!`
- [ ] Enter display name: `iOSChampion`
- [ ] Submit registration
- [ ] **Expected**: Account created, logged in, see home screen

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 1.2: Login & Logout**

#### **On Android:**
- [ ] Log out
- [ ] Log back in with `android.user@test.com`
- [ ] **Expected**: Successfully logs in, see home screen
- [ ] **Check**: User data loads (profile, stats)

#### **On iPhone:**
- [ ] Log out
- [ ] Log back in with `ios.user@test.com`
- [ ] **Expected**: Successfully logs in, see home screen
- [ ] **Check**: User data loads (profile, stats)

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 1.3: Profile Setup**

#### **On Android (AndroidWarrior):**
- [ ] Navigate to Profile screen
- [ ] Check current data displays
- [ ] Tap edit profile (if available)
- [ ] Update bio/description
- [ ] **Expected**: Profile updates save correctly

#### **On iPhone (iOSChampion):**
- [ ] Navigate to Profile screen
- [ ] Check current data displays
- [ ] Tap edit profile (if available)
- [ ] Update bio/description
- [ ] **Expected**: Profile updates save correctly

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 1.4: Search & Friends**

#### **On Android (Search for iOS user):**
- [ ] Navigate to Search screen
- [ ] Search for: `iOSChampion`
- [ ] **Expected**: iOS user appears in results
- [ ] Tap user to view profile
- [ ] **Expected**: Profile loads correctly
- [ ] Add as friend (if feature exists)

#### **On iPhone (Search for Android user):**
- [ ] Navigate to Search screen
- [ ] Search for: `AndroidWarrior`
- [ ] **Expected**: Android user appears in results
- [ ] Tap user to view profile
- [ ] **Expected**: Profile loads correctly
- [ ] Accept friend request (if feature exists)

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

## 🎮 **PHASE 2: Battle System Tests**

### **Test 2.1: Create Battle Challenge**

#### **On Android (AndroidWarrior creates challenge):**
- [ ] Navigate to "New Battle" / "Create Challenge"
- [ ] Select opponent: `iOSChampion`
- [ ] Select genre: (e.g., "Hip Hop", "Rock", etc.)
- [ ] Set rounds: (e.g., 3 rounds)
- [ ] **Additional settings**: (note any other options)
- [ ] Submit challenge
- [ ] **Expected**: Challenge created successfully
- [ ] **Expected**: Challenge appears in "Battles" or "Pending" list

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 2.2: Receive & Accept Challenge**

#### **On iPhone (iOSChampion receives challenge):**
- [ ] Check "Challenges" / "Notifications" screen
- [ ] **Expected**: Challenge from `AndroidWarrior` appears
- [ ] **Check**: All challenge details display correctly
  - [ ] Opponent name
  - [ ] Genre
  - [ ] Number of rounds
- [ ] Tap "Accept" / "Start Battle"
- [ ] **Expected**: Battle starts, navigates to battle screen

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 2.3: Battle Round 1 (Android's Turn)**

#### **On Android (AndroidWarrior's turn):**
- [ ] Navigate to active battle (if not already there)
- [ ] **Expected**: Shows "Your Turn" indicator
- [ ] **Expected**: Battle info displayed:
  - [ ] Round 1 of X
  - [ ] Current scores (0-0)
  - [ ] Opponent name
- [ ] Submit move/play
- [ ] **Expected**: Move recorded successfully
- [ ] **Expected**: Shows "Waiting for opponent" or similar

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 2.4: Battle Round 1 (iOS Response)**

#### **On iPhone (iOSChampion sees Android's move):**
- [ ] Refresh or check battle screen
- [ ] **Expected**: Android's move appears
- [ ] **Expected**: Shows "Your Turn" indicator
- [ ] Submit counter-move/response
- [ ] **Expected**: Move recorded successfully
- [ ] **Expected**: Round 1 score updated
- [ ] **Expected**: Shows Round 2 started (or Android's turn)

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 2.5: Complete Full Battle**

#### **Continue alternating turns:**

**Round 2:**
- [ ] Android plays
- [ ] iPhone responds
- [ ] Scores update correctly

**Round 3 (final):**
- [ ] Android plays
- [ ] iPhone responds
- [ ] Battle completes
- [ ] **Expected**: Winner declared
- [ ] **Expected**: Final scores shown
- [ ] **Expected**: ELO ratings updated for both players

#### **On Android:**
- [ ] Check profile
- [ ] **Expected**: Battle appears in history
- [ ] **Expected**: Win/loss record updated
- [ ] **Expected**: ELO rating changed

#### **On iPhone:**
- [ ] Check profile
- [ ] **Expected**: Battle appears in history
- [ ] **Expected**: Win/loss record updated
- [ ] **Expected**: ELO rating changed

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

## 🔥 **PHASE 3: Live Battle Tests (LiveKit)**

### **Test 3.1: Start Live Battle**

#### **Setup:**
- [ ] Android creates live battle challenge
- [ ] iPhone accepts
- [ ] **Expected**: LiveKit video call initiates

#### **On Android:**
- [ ] Camera activates
- [ ] **Expected**: See own video feed
- [ ] **Expected**: See opponent's video feed (iPhone)
- [ ] **Check**: Audio works (can hear opponent)
- [ ] **Check**: Video quality acceptable

#### **On iPhone:**
- [ ] Camera activates
- [ ] **Expected**: See own video feed
- [ ] **Expected**: See opponent's video feed (Android)
- [ ] **Check**: Audio works (can hear opponent)
- [ ] **Check**: Video quality acceptable

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 3.2: Live Battle Interaction**

#### **During Live Battle:**
- [ ] Android performs (speak/rap/sing into mic)
- [ ] **Expected**: iPhone hears clearly
- [ ] iPhone performs (speak/rap/sing into mic)
- [ ] **Expected**: Android hears clearly
- [ ] Complete rounds while video calling
- [ ] **Expected**: Battle completes successfully
- [ ] **Expected**: Video call ends cleanly

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

## 💰 **PHASE 4: Payment Tests (Stripe)**

### **Test 4.1: View Premium Features**

#### **On Android:**
- [ ] Navigate to premium/shop screen
- [ ] **Expected**: Premium features listed
- [ ] **Expected**: Prices displayed
- [ ] Note available options: _______________

#### **On iPhone:**
- [ ] Navigate to premium/shop screen
- [ ] **Expected**: Same features as Android
- [ ] **Expected**: Prices match Android

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 4.2: Stripe Payment Flow (TEST MODE ONLY)**

⚠️ **Use Stripe test card: `4242 4242 4242 4242`, any future date, any CVC**

#### **On Android:**
- [ ] Select premium feature
- [ ] Tap "Purchase" / "Buy"
- [ ] **Expected**: Stripe payment sheet appears
- [ ] Enter test card details
- [ ] Submit payment
- [ ] **Expected**: Payment succeeds (test mode)
- [ ] **Expected**: Feature unlocks

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

## 📊 **PHASE 5: Leaderboard & Activity Tests**

### **Test 5.1: Leaderboard**

#### **On Both Devices:**
- [ ] Navigate to Leaderboard
- [ ] **Expected**: Shows ranked users
- [ ] **Expected**: Both test users appear
- [ ] **Expected**: ELO ratings displayed
- [ ] **Expected**: Win/loss records shown

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 5.2: Activity Feed**

#### **On Android:**
- [ ] Navigate to Activity feed
- [ ] **Expected**: Recent battles shown
- [ ] **Expected**: Friend activity shown
- [ ] **Expected**: Updates are recent

#### **On iPhone:**
- [ ] Navigate to Activity feed
- [ ] **Expected**: Same activities as Android
- [ ] **Expected**: Real-time sync working

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

## 🌐 **PHASE 6: Edge Cases & Error Handling**

### **Test 6.1: Offline Handling**

#### **On Android:**
- [ ] Turn off WiFi and cellular data
- [ ] Try to create battle
- [ ] **Expected**: Error message shown
- [ ] **Expected**: App doesn't crash
- [ ] Turn network back on
- [ ] **Expected**: App reconnects automatically

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 6.2: App Backgrounding**

#### **On iPhone:**
- [ ] Start a battle
- [ ] Press home button (background app)
- [ ] Wait 1 minute
- [ ] Return to app
- [ ] **Expected**: Battle state preserved
- [ ] **Expected**: Can continue playing

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 6.3: Simultaneous Actions**

#### **On Both Devices (at same time):**
- [ ] Android and iPhone both try to play in battle simultaneously
- [ ] **Expected**: Proper turn management (one waits)
- [ ] **Expected**: No data corruption
- [ ] **Expected**: Correct player gets turn

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

### **Test 6.4: Battle Decline/Cancel**

#### **On Android:**
- [ ] Create new battle challenge
- [ ] iPhone receives challenge

#### **On iPhone:**
- [ ] Tap "Decline" / "Reject"
- [ ] **Expected**: Challenge rejected

#### **On Android:**
- [ ] Check battle status
- [ ] **Expected**: Shows as "Declined" or removed

**✅ PASS / ❌ FAIL**  
**Notes**: _______________________________________________

---

## 🐛 **PHASE 7: Bug & Issue Documentation**

### **Visual Issues**
| Screen | Device | Issue | Severity |
|--------|--------|-------|----------|
| | | | |
| | | | |

### **Functional Issues**
| Feature | Device | Issue | Severity |
|---------|--------|-------|----------|
| | | | |
| | | | |

### **Performance Issues**
| Action | Device | Issue | Severity |
|--------|--------|-------|----------|
| | | | |
| | | | |

### **Crash Logs**
```
(Paste any crash logs here)
```

---

## 📈 **PHASE 8: Performance Metrics**

### **App Startup Time**
- Android: _______ seconds
- iPhone: _______ seconds

### **Battle Creation Time**
- Time to create challenge: _______ seconds
- Time for opponent to receive: _______ seconds

### **Real-time Sync Latency**
- Android makes move → iPhone sees it: _______ seconds
- iPhone responds → Android sees it: _______ seconds

### **Video Call Quality (LiveKit)**
- Connection time: _______ seconds
- Video quality: Excellent / Good / Fair / Poor
- Audio quality: Excellent / Good / Fair / Poor
- Latency: Low / Medium / High

---

## 🎯 **Critical Features Status**

| Feature | Working? | Android | iOS | Notes |
|---------|----------|---------|-----|-------|
| Registration | ☐ Yes ☐ No | ☐ | ☐ | |
| Login/Logout | ☐ Yes ☐ No | ☐ | ☐ | |
| Profile View | ☐ Yes ☐ No | ☐ | ☐ | |
| Search Users | ☐ Yes ☐ No | ☐ | ☐ | |
| Create Battle | ☐ Yes ☐ No | ☐ | ☐ | |
| Accept Battle | ☐ Yes ☐ No | ☐ | ☐ | |
| Play Rounds | ☐ Yes ☐ No | ☐ | ☐ | |
| Complete Battle | ☐ Yes ☐ No | ☐ | ☐ | |
| ELO Updates | ☐ Yes ☐ No | ☐ | ☐ | |
| Live Video (LiveKit) | ☐ Yes ☐ No | ☐ | ☐ | |
| Payments (Stripe) | ☐ Yes ☐ No | ☐ | ☐ | |
| Leaderboard | ☐ Yes ☐ No | ☐ | ☐ | |
| Activity Feed | ☐ Yes ☐ No | ☐ | ☐ | |
| Friends System | ☐ Yes ☐ No | ☐ | ☐ | |

---

## 🚀 **Priority Issues to Fix**

After testing, rank issues by priority:

### **P0 - Critical (Blocks Launch)**
1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### **P1 - High (Must fix before launch)**
1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### **P2 - Medium (Should fix, but can launch)**
1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### **P3 - Low (Nice to have, post-launch)**
1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

---

## ✅ **Launch Readiness Checklist**

Before submitting to App Store / Play Store:

- [ ] All P0 issues fixed
- [ ] All P1 issues fixed
- [ ] Cross-platform battles work reliably
- [ ] LiveKit video calls work on both platforms
- [ ] Stripe payments work (at least in test mode)
- [ ] No crashes during normal usage
- [ ] Firebase backend stable
- [ ] ELO calculations correct
- [ ] Leaderboard accurate
- [ ] Performance acceptable (<2s startup)
- [ ] UI looks good on both platforms
- [ ] Privacy policy completed
- [ ] Terms of service completed
- [ ] App icons finalized
- [ ] Screenshots prepared for stores

---

## 📝 **Testing Session Log**

### **Session 1: [Date/Time]**
**Tester**: _______________  
**Duration**: _______________  
**Tests Completed**: _______________  
**Issues Found**: _______________  
**Notes**: _______________________________________________

### **Session 2: [Date/Time]**
**Tester**: _______________  
**Duration**: _______________  
**Tests Completed**: _______________  
**Issues Found**: _______________  
**Notes**: _______________________________________________

### **Session 3: [Date/Time]**
**Tester**: _______________  
**Duration**: _______________  
**Tests Completed**: _______________  
**Issues Found**: _______________  
**Notes**: _______________________________________________

---

## 🎉 **Testing Complete**

- **Total Tests**: _______
- **Passed**: _______
- **Failed**: _______
- **Pass Rate**: _______%

**Overall Assessment**:
- [ ] Ready for beta testing
- [ ] Ready for production launch
- [ ] Needs more work (see priority issues)

**Next Steps**:
1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

---

**Document Created**: December 13, 2025  
**Last Updated**: _______________________  
**Version**: 1.0  
**Status**: Testing in Progress
