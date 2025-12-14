# 📖 How to View Moves in Firebase Console

## Step-by-Step Guide

### 1. Navigate to Firestore
Go to: https://console.firebase.google.com/project/beatrivals-d8d2c/firestore/data/~2Fbattles

### 2. Find Your Battle
- Look for the battle document (sort by `lastActivity` to find recent ones)
- Battle ID example: `BFgUNEmwMFTmDiySacCS`

### 3. Click on the Battle Document
Click the battle document ID to open it.

### 4. Look for Subcollections
After clicking the battle, you'll see:
- **Fields tab** (status, currentTurnUid, movesCount, etc.)
- **Subcollections** section at the bottom

### 5. Click "moves" Subcollection
In the subcollections section, you should see:
```
📁 moves
```

Click on `moves` to view all the move documents.

### 6. View Move Details
Each move document contains:
- `id`: Unique move ID
- `link`: Video URL from Firebase Storage
- `submittedByUid`: User who submitted the move
- `title`: "[Category] Genre - Round X"
- `round`: Battle round number
- `submittedAt`: Timestamp
- `performedAt`: Timestamp
- `votes`: Map of user votes (optional)

---

## 🔍 Visual Guide

```
Firestore Database
  └── battles (collection)
      └── BFgUNEmwMFTmDiySacCS (document)
          ├── 📄 Fields
          │   ├── status: "active"
          │   ├── currentTurnUid: "HNcv4Q..."
          │   ├── movesCount: {}  ← IGNORE THIS (legacy/unused)
          │   └── ... other fields
          │
          └── 📁 Subcollections
              └── moves (subcollection)  ← CLICK HERE!
                  ├── abc123 (move document)
                  │   ├── link: "https://firebasestorage..."
                  │   ├── submittedByUid: "kGhza..."
                  │   └── title: "[Freestyle] Hip Hop - Round 1"
                  │
                  └── def456 (move document)
                      ├── link: "https://firebasestorage..."
                      ├── submittedByUid: "HNcv4..."
                      └── title: "[Singing] Pop - Round 1"
```

---

## ❓ Common Confusion

### Q: Why is `movesCount` empty?
**A:** It's a legacy field from old code. The app doesn't use it anymore. The REAL move count comes from counting documents in the `moves` subcollection.

### Q: Where are the actual moves?
**A:** In the **subcollection** called `moves`, not in the `movesCount` field.

### Q: Why can't I see moves?
**A:** You need to:
1. Click the battle document
2. Scroll down to "Subcollections"
3. Click the `moves` folder icon

### Q: What if there's no `moves` subcollection?
**A:** It means no one has submitted a move yet for that battle.

---

## 🧪 Quick Test

To verify moves are being saved:

1. **Record a video** in a battle
2. **Wait for upload** to complete
3. **Go to Firebase Console:**
   - Navigate to `battles` collection
   - Find your battle (sort by `lastActivity`)
   - **Click the battle document**
   - **Scroll down** to "Subcollections"
   - **Click `moves`**
4. **You should see** a move document with:
   - `link` field containing Firebase Storage URL
   - `submittedByUid` matching your user ID
   - `title` with your performance title

---

## 🎯 Key Takeaway

**`movesCount` ≠ Moves Data**

- `movesCount`: Empty map field (legacy, unused)
- `moves`: **Subcollection** containing actual move documents

**Always look in the `moves` SUBCOLLECTION!**
