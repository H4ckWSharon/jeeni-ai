# Jeeni AI — Flutter Project

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── theme/
│   └── app_theme.dart               # Colors, gradients, ThemeData
├── models/
│   └── chat_message.dart            # ChatMessage data model
├── screens/
│   ├── splash_screen.dart           # 1. Animated splash (1.5s)
│   ├── intro_screen.dart            # 2. Intro "Learn anything with AI"
│   ├── onboarding_screen.dart       # 3. 3-page swipeable onboarding
│   ├── get_started_screen.dart      # 4. Get Started / Email CTA
│   └── chat_screen.dart             # 5. Main AI chat experience
└── widgets/
    ├── chat_bubble.dart             # User + AI message bubbles
    ├── typing_indicator.dart        # Animated "Thinking…" dots
    ├── chat_input_bar.dart          # Input field + send button
    ├── empty_chat_state.dart        # Empty state with suggestions
    └── common_widgets.dart          # GradientButton, JeeniLogo, etc.
```

---

## Setup Instructions

### Prerequisites
- Flutter SDK ≥ 3.0.0 ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio / VS Code with Flutter extension
- Android SDK or Xcode (for iOS)

### 1. Install Dependencies

```bash
flutter pub get
```

> **Fonts:** The app uses `google_fonts` which downloads Inter automatically over the network. No local font files needed.

### 3. Run the App

```bash
# Android emulator or connected device
flutter run

# iOS simulator
flutter run -d iPhone

# Check available devices
flutter devices
```

### 4. Build for Release

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

---

## Dependencies Used

| Package | Purpose |
|---|---|
| `google_fonts` | Inter-style typography |
| `animated_text_kit` | Text animations (optional) |
| `smooth_page_indicator` | Pagination dots (optional) |
| `flutter_animate` | Micro-animations (optional) |
| `gap` | Clean spacing widgets (optional) |

> **Note:** The core UI works without optional packages. The app uses Flutter's built-in animation controllers for all effects.

---

## Color Palette

| Token | Hex | Use |
|---|---|---|
| `background` | `#0B1020` | Main background |
| `backgroundSecondary` | `#0F172A` | Gradient end |
| `surface` | `#1E293B` | Cards, bubbles |
| `surfaceElevated` | `#263348` | Borders, inputs |
| `primary` | `#6366F1` | Buttons, accents |
| `primaryLight` | `#818CF8` | Highlights |
| `accent` | `#22D3EE` | Cyan highlights |
| `textPrimary` | `#F1F5F9` | Main text |
| `textSecondary` | `#94A3B8` | Subtitles |
| `textMuted` | `#64748B` | Placeholders |
| `userBubble` | `#4F46E5` | User chat bubble |
| `success` | `#10B981` | Online status |

---

## App Flow

```
SplashScreen (1.5s)
    ↓ fade
IntroScreen
    ↓ slide
OnboardingScreen (3 pages, swipeable)
    ↓ slide
GetStartedScreen
    ↓ fade
ChatScreen (main experience)
```

---

## Key Features Implemented

- ✅ **Splash Screen** — Neural logo + glow animation + fade transition
- ✅ **Intro Screen** — AI orb + ambient background glows + slide-in text
- ✅ **Onboarding** — 3 custom illustrations, animated dots, skip button, accent colors per page
- ✅ **Get Started** — Feature chips, primary + secondary CTA buttons
- ✅ **Chat Screen** — Full message list, AI response simulation, auto-scroll
- ✅ **Chat Bubbles** — Slide/fade entrance, bold text parsing, timestamps
- ✅ **Typing Indicator** — Staggered bouncing dots + "Thinking…" label
- ✅ **Input Bar** — Animated send button, glow on focus, keyboard-aware
- ✅ **Empty State** — Pulsing orb, staggered suggestion cards, subject pills
- ✅ **Dark Theme** — Full Material 3 dark theme, no harsh contrasts
- ✅ **SafeArea** — Respected on all screens (notch + bottom gestures)
- ✅ **Haptic Feedback** — Light impact on send + button presses
- ✅ **Press Animations** — Scale-down on all tappable elements

---

## Customization

### Change AI Responses
Edit `_aiResponses` and `_generateResponse()` in `chat_screen.dart`.

### Change Onboarding Content
Edit the `_pages` list in `onboarding_screen.dart`.

### Change Colors
All colors are centralized in `lib/theme/app_theme.dart` → `AppColors`.
