# 🚴‍♂️ Branchr Phase 9.5 – Animated Launch Screen (Cyclists Riding Across Screen)

**Objective:**  
Create a dynamic **launch animation** where **3 bike riders** ride across the screen horizontally — resembling a bicycle traffic sign but in motion.  
The animation plays for about **3 seconds**, then transitions automatically into the app's **HomeView**.

---

## 🧠 Technical Goals
1. ✅ Replace the static Launch Screen with a **custom animated splash view**.
2. ✅ Animate 3 cyclist icons moving left → right in sequence.
3. ✅ Match the style of a **traffic sign** (minimalist silhouettes on a yellow background).
4. ✅ Keep total duration ~3 seconds before navigating to HomeView.
5. ✅ Comply with Apple's launch screen performance rules (fast startup, no delay logic in LaunchScreen.storyboard — use a transition view after launch).

---

## 📂 File Structure

~/Documents/branchr/
│
├── Views/
│   ├── Splash/
│   │   ├── LaunchAnimationView.swift
│   │   └── LaunchBikeRiderView.swift
│   └── HomeView.swift  (entry view)
│
└── Assets.xcassets/
├── bike_rider_1.svg
├── bike_rider_2.svg
└── bike_rider_3.svg

---

## ⚙️ Cursor Prompt Instructions

> Extend the **Branchr** SwiftUI app (iOS 18.2, Xcode 16.2) to include a professional animated splash screen before loading the HomeView.

### 1️⃣ **LaunchAnimationView.swift**
- A SwiftUI view with a solid **yellow background** (traffic-sign color: `Color(red: 1.0, green: 0.86, blue: 0.2)`).
- Displays 3 `LaunchBikeRiderView` icons spaced evenly across the screen.
- Each rider animates from **left to right**, slightly staggered:
  ```swift
  withAnimation(.easeInOut(duration: 2.5).delay(0.2 * index))
```
•    Optional wheel rotation animation (use small rotation effect).
    •    After 3 seconds → fades into HomeView using .transition(.opacity).

2️⃣ LaunchBikeRiderView.swift
    •    Each rider is an Image or SF Symbol ("bicycle.circle.fill" or custom asset).
    •    Black silhouette style to mimic traffic sign.
    •    Optional gradient glow for depth (Liquid Glass consistency).

3️⃣ StryVrApp.swift (or BranchrApp.swift)
    •    Set initial screen as LaunchAnimationView().
    •    Auto-navigate to HomeView() after animation ends:

@State private var showHome = false

After 3 seconds:

withAnimation { showHome = true }

4️⃣ LaunchScreen.storyboard
    •    Keep a static yellow background with centered Branchr text (no logic here).
This satisfies iOS launch compliance — the animated SwiftUI view runs right after app launch.

⸻

🎨 Design Guidelines
    •    Background color: #FFD83B (traffic sign yellow)
    •    Rider silhouettes: black
    •    Animation timing: ~2.8–3.0 seconds
    •    Use .easeInOut for natural pacing
    •    At the end, fade smoothly into HomeView

⸻

🧪 Test Checklist
    1.    Build and run app.
    2.    Launch screen appears instantly (static yellow → animated cyclists).
    3.    Three cyclists move smoothly across the screen.
    4.    After ~3 seconds, fade into HomeView.
    5.    No lag, crash, or black screen.

⸻

✅ Success Criteria
    •    Instant launch (no artificial delay in LaunchScreen.storyboard).
    •    Smooth animation at 60 fps.
    •    Transitions automatically to HomeView after 3 seconds.
    •    Visual theme matches Branchr's Liquid Glass and minimalist brand.

⸻

Save as:
~/Documents/branchr/phase9_5_branchr_launch_animation.md

Then open this file in Cursor and type:

"Generate all code for Phase 9.5 – Animated Launch Screen (Cyclists Riding Across Screen)."

⸻

🏁 Next Phase Preview

Next: Phase 10 – Advanced Safety Features & Emergency SOS, where Branchr adds automatic speed-based music ducking, wind noise detection, and a quick-access emergency button to alert contacts 🆘🏍️✨
