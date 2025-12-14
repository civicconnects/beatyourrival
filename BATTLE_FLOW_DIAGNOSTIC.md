# Battle Flow Diagnostic Guide

**Issue:** Battle disappears from tester1's active battles after iosuser finishes performing

---

## 🔍 What to Check in Firebase

### Step 1: Open Firestore Console
Go to: https://console.firebase.google.com/project/beatrivals-d8d2c/firestore/data/~2Fbattles

### Step 2: Find Your Battle
Look for the battle between iosuser and tester1 (sort by `createdAt` descending)

### Step 3: Check These Fields

**Critical Fields:**
```
status: ?           ← Should be "active", NOT "completed"
maxRounds: ?        ← How many rounds total?
currentRound: ?     ← What round are we on?
currentTurnUid: ?   ← Whose turn is it? (should be tester1's UID)
```

**Move Counting:**
```
movesCount: {
  "1": ?  ← How many moves in round 1?
}
```

### Step 4: Check Moves Subcollection
1. Click on the battle document
2. Look for `moves` subcollection
3. Count the documents inside

**Expected:**
- After iosuser finishes: Should have **1 move** in round 1
- Status should be: **"active"**
- currentTurnUid should be: **tester1's UID**

**If you see:**
- Status: "completed" ← **BUG!** Battle ended too early
- 2 moves in round 1 ← Something submitted twice
- 0 moves ← Move didn't save

---

## 🐛 Possible Causes

### Cause #1: Battle Marked Completed Too Early
**Why:** Logic thinks both players have moved when only one has

**Fix:** Check move counting logic in `battle_service.dart` line 209

---

### Cause #2: maxRounds = 1, and Logic is Wrong
**Why:** With 1 round, after first player moves, logic might think battle is done

**Current Logic:**
```dart
if (movesThisRoundIncludingCurrent == 2) {  // Both players moved?
  if (battle.currentRound < battle.maxRounds) {
    // Advance to next round
  } else {
    updates['status'] = 'completed';  // ← Mark as done
  }
}
```

**The Bug:** This should only mark completed after BOTH players have moved in the FINAL round.

But if `maxRounds = 1` and `currentRound = 1`:
- After iosuser moves: `movesThisRoundIncludingCurrent = 1` → Don't mark completed ✅
- After tester1 moves: `movesThisRoundIncludingCurrent = 2` → Mark completed ✅

**This logic is CORRECT** if moves are counted right.

---

### Cause #3: Move Submitted Twice (Race Condition)
**Why:** `_finishPerformance()` might be called multiple times

**Check:**
- Did iosuser click "Finish Performance" twice?
- Did the timer auto-finish AND user clicked button?

**Evidence:** Check `moves` subcollection - if there are 2 moves from iosuser, this is the bug

---

### Cause #4: UI Filtering Bug
**Why:** Battle is still "active" but tester1's UI isn't showing it

**Check `streamUserActiveBattles()` in battle_service.dart line 102-117:**
```dart
.where('status', whereIn: ['active', 'pending'])
```

If battle status is "completed", it won't show in active battles list.

---

## 🎯 Quick Test Commands

### Check Battle Status in Firebase Console:
1. Copy the battle ID (e.g., `YbNIGORfC9u6OOKC9Lai`)
2. Paste this URL: `https://console.firebase.google.com/project/beatrivals-d8d2c/firestore/data/~2Fbattles~2FBATTLE_ID_HERE`

### What We Need to Know:
1. **Battle status:** pending / active / completed?
2. **Move count:** How many documents in `moves` subcollection?
3. **movesCount map:** What does it show?
4. **currentTurnUid:** Does it match tester1's UID?
5. **maxRounds:** How many rounds was this battle set for?

---

## 🔧 Temporary Fix (If Status is "completed" wrongly)

### Option 1: Manually Fix in Firebase Console
1. Open the battle document
2. Change `status` from "completed" to "active"
3. Verify `currentTurnUid` is set to tester1's UID
4. Save
5. tester1 should now see the battle in their active list

### Option 2: Create New Battle for Testing
- Make sure `maxRounds` is set to **3** (not 1)
- Test the full flow again

---

## 📊 What to Report Back

Please share screenshots or copy-paste of:

1. **Battle Document Fields:**
   ```
   status: ?
   maxRounds: ?
   currentRound: ?
   currentTurnUid: ?
   movesCount: { ... }
   ```

2. **Moves Subcollection:**
   - How many moves are there?
   - Who submitted each move?
   - What round is each move for?

3. **tester1's View:**
   - Does tester1 see the battle in "Active Battles"?
   - Or is it showing in "Completed Battles"?
   - Or is it completely missing?

4. **Console Logs:**
   - When iosuser clicks "Finish Performance", what does the console say?
   - Look for: `movesThisRoundIncludingCurrent = ?`

---

## 🚀 Next Steps

Once you provide the Firebase data, I can:
1. Confirm if it's a move counting bug
2. Confirm if it's a status update bug
3. Confirm if it's a UI filtering bug
4. Provide the exact code fix needed

The recording functionality is working perfectly! Now we just need to fix the battle flow so tester1 can respond to iosuser's performance. 🎯
