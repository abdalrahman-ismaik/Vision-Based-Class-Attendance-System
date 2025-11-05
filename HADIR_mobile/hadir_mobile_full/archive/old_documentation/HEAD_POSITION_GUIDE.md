# Head Position Visual Guide

**Quick Reference: How to Hold Your Head for Pose Capture**

---

## ✅ CORRECT: Head Upright (Roll = 0°)

```
    📱 Phone Vertical
    
       👤
      /|\\
     / | \\
    ← Head is UPRIGHT
    
    Both ears level
    Head not tilted
    ✅ Roll ≈ 0°
```

**What you should feel:**
- Both ears at same height
- Head feels "straight"
- Like you're standing at attention
- Natural, comfortable posture

---

## ❌ WRONG: Head Tilted Right (Roll = +25°)

```
    📱 Phone Vertical
    
        👤 ← Head tilted!
       / \\
      /   \\
    
    Right ear closer to shoulder
    Head tilted to the right
    ❌ Roll = +25° (TOO MUCH!)
```

**What the app shows:**
```
❌ INVALID: Head tilted too much (Roll=25.0°, need ≤20°)
```

---

## ❌ WRONG: Head Tilted Left (Roll = -25°)

```
    📱 Phone Vertical
    
    👤 ← Head tilted!
     \\ /
      \\ /
    
    Left ear closer to shoulder
    Head tilted to the left
    ❌ Roll = -25° (TOO MUCH!)
```

**What the app shows:**
```
❌ INVALID: Head tilted too much (Roll=-25.0°, need ≤20°)
```

---

## 🔄 Understanding the 3 Angles

### 1. YAW (Left/Right Turn)
```
Looking Left     Looking Straight     Looking Right
    👤              👤                    👤
   ← 🔄            ↕                    🔄 →
  -45° Yaw        0° Yaw               +45° Yaw
```
**What to do:** Turn your head left or right (for profile poses)

---

### 2. PITCH (Up/Down Tilt)
```
Looking Up       Looking Straight     Looking Down
    👤              👤                    👤
     ↑              ↕                     ↓
  -30° Pitch      0° Pitch             +30° Pitch
```
**What to do:** Tilt your head up or down (for looking up/down poses)

---

### 3. ROLL (Head Tilt) ⚠️ THIS WAS THE PROBLEM!
```
Tilted Left      Upright             Tilted Right
    👤              👤                    👤
   ↖               ↕                    ↗
  -25° Roll       0° Roll              +25° Roll
   ❌              ✅                    ❌
```
**What to do:** Keep your head UPRIGHT - don't tilt ear to shoulder!

---

## 🎯 For Each Pose Type

### 📸 Frontal Pose
```
    Correct:              Wrong:
    
       👤                   👤 ← Tilted!
      /|\\                  / \\
     / | \\                /   \\
    ← Upright            ← Don't tilt!
    
    Yaw: ±15°            Same Yaw ✅
    Pitch: ±15°          Same Pitch ✅
    Roll: ≤20° ✅        Roll: 25° ❌
    
    ✅ VALID             ❌ INVALID
```

### 📸 Left Profile
```
    Correct:              Wrong:
    
      👤                    👤 ← Tilted!
     ←|                    ← \\
      |                      \\
    ← Upright              ← Don't tilt!
    
    Yaw: 25-50° ✅       Same Yaw ✅
    Pitch: ±15° ✅       Same Pitch ✅
    Roll: ≤20° ✅        Roll: 25° ❌
    
    ✅ VALID             ❌ INVALID
```

### 📸 Right Profile
```
    Correct:              Wrong:
    
    👤                  👤 ← Tilted!
     |→                 / →
     |                 /
    ← Upright        ← Don't tilt!
    
    Yaw: -25 to -50° ✅  Same Yaw ✅
    Pitch: ±15° ✅       Same Pitch ✅
    Roll: ≤20° ✅        Roll: 25° ❌
    
    ✅ VALID             ❌ INVALID
```

---

## 💡 Quick Tips

### ✅ DO:
- **Stand/sit straight** - like you're at attention
- **Keep both ears level** - imagine a line connecting them is horizontal
- **Think "military posture"** - head upright, shoulders back
- **Hold phone at eye level** - reduces need to tilt head

### ❌ DON'T:
- **Rest your head** - on hand or shoulder
- **Tilt casually** - the way you might when relaxed
- **Lean** - keep torso and head aligned
- **Hold phone at waist** - you'll tilt head down to see it

---

## 🔍 What You'll See in the App

### When Head is Upright (Correct)
```
✅ Frame 156: 1 face(s) detected (took 48ms)
   Face 1:
      Angles: Yaw=-9.0°, Pitch=13.1°, Roll=8.0°
                                        ↑
                                    Within ±20° ✅
   🎯 Validating for pose: PoseType.frontal
      ✅ VALID POSE!
      ⏱️  Holding: 500ms / 2000ms
```

### When Head is Tilted (Wrong)
```
✅ Frame 172: 1 face(s) detected (took 37ms)
   Face 1:
      Angles: Yaw=5.9°, Pitch=21.1°, Roll=25.4°
                                        ↑
                                    Too high! ❌
   🎯 Validating for pose: PoseType.frontal
      ❌ INVALID: Head tilted too much (Roll=25.4°, need ≤20°)
```

---

## 🎬 Step-by-Step

1. **Hold phone vertically** at eye level
2. **Stand/sit straight** like you're posing for a formal photo
3. **Check your ears** - both at same height?
4. **Look at camera** (or turn head for profiles)
5. **Stay upright** - don't tilt head left or right!

**Think of it like this:**
- You can **turn** your head (Yaw) ✅
- You can **nod** your head (Pitch) ✅
- But don't **tilt** your head (Roll) ❌

---

## 📏 Angle Tolerances

| Pose Type | Yaw Range | Pitch Range | **Roll Limit** |
|-----------|-----------|-------------|----------------|
| Frontal   | ±15°      | ±15°        | **±20°** ⚠️   |
| Left      | 25-50°    | ±15°        | **±20°** ⚠️   |
| Right     | -50 to -25°| ±15°       | **±20°** ⚠️   |
| Up        | ±15°      | -35 to -10° | **±20°** ⚠️   |
| Down      | ±15°      | 10-35°      | **±20°** ⚠️   |

**Key Point:** All poses require **Roll ≤ 20°** (head upright)!

---

## 🧪 Test Yourself

**Before starting capture:**

1. Hold phone vertically in front of you
2. Stand straight, shoulders back
3. Check in mirror or front camera:
   - Are both ears level? ✅
   - Is your head tilted? ❌
4. This is your "base position"
5. For each pose, maintain this upright head!

**Remember:** 
- **Turn** (Yaw) = Yes, for profiles ✅
- **Nod** (Pitch) = Yes, for up/down ✅  
- **Tilt** (Roll) = No, stay upright! ❌

---

## 🎯 Common Mistakes

### Mistake #1: "Casual Phone Use" Position
```
❌ Head tilted because phone is held low
   Solution: Hold phone at eye level
```

### Mistake #2: "Resting Head" Position
```
❌ Head leaning to one side naturally
   Solution: Sit/stand straight, military posture
```

### Mistake #3: "Confused Turn with Tilt"
```
❌ Tilting head when asked to "turn"
   Solution: Turn = rotate neck, don't bend it
```

### Mistake #4: "Trying Too Hard"
```
❌ Overcorrecting and creating tension
   Solution: Relax but stay upright
```

---

## ✅ Success Checklist

Before each pose capture:

- [ ] Phone held vertically at eye level
- [ ] Standing/sitting straight (not slouching)
- [ ] Both ears at same height
- [ ] Head feels upright and natural
- [ ] Can see yourself in preview without straining
- [ ] Ready to hold position for 2 seconds

**If all checked:** You're ready! The app should detect your pose consistently.

---

## 📞 Still Having Issues?

If you're keeping your head upright (Roll < 20°) but still getting errors:

1. **Check the logs** - what's the actual Roll value?
   ```
   Angles: Yaw=X°, Pitch=Y°, Roll=Z°
                              ↑
                         This should be <20°
   ```

2. **Try these positions:**
   - Roll = 0-10° ✅✅✅ Perfect!
   - Roll = 10-20° ✅ Acceptable
   - Roll = 20-30° ❌ Too much
   - Roll > 30° ❌❌ Way too much

3. **Ask someone to check** - sometimes we don't notice our own tilt

---

**Remember: You can TURN and NOD your head, but keep it UPRIGHT (don't tilt)!**
