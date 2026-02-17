# RowTracker

```
                                          ~  ~
         ___                         ~~  ~    ~~
        /   \          __/)_____    ~  ~   ~
       | o o |    ____/         \~~~~    ~~   ~
       |  >  |   |  _     ___   |~  ~~    ~
        \___/    | | |   / _ \  |   ~  ~~
         /|\     | |_|  | (_) | |~~~~   ~  ~~
    ____/_|_\____|___/   \___/  |~  ~~     ~
   |______________|_____/______/~~~~  ~~ ~
   ~~  ~~~~  ~~~  ~~~ ~~ ~~~ ~~~  ~~~~  ~~
     ~~  ~~ ~~~~  ~~  ~~~~  ~~ ~~~~  ~~  ~~
   ~~~~  ~~   ~~  ~~~~  ~~ ~~~~  ~~~~  ~~
          ~~ ~~~~  ~~  ~~~~  ~~  ~~ ~~~~
```

An iOS app for tracking rowing sessions with an animated river scene. Set a monthly distance goal and watch your rower advance across the river as you log sessions.

## Features

- **Animated River Scene** — Canvas-drawn river with a rower, animated water ripples, oar movement, trees, clouds, and wake trails. The rower moves left to right as you progress toward your goal.
- **Session Logging** — Track date, duration, and distance (km) for each rowing session.
- **Monthly Goals** — Set a distance goal for the current month and track your progress with a visual progress bar.
- **Haptic Feedback** — Tactile feedback on session saves, goal milestones, and celebrations.
- **Confetti Celebration** — Hit 100% of your goal and get a confetti animation with a strong haptic burst.
- **History** — View all sessions grouped by month with swipe-to-delete.
- **Reset** — Clear your goal and sessions for the current month to start fresh.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Architecture

- **SwiftUI** + **SwiftData** for persistence
- **MVVM** with `@Observable` view models
- **Canvas** + **TimelineView** for the animated river scene
- No external dependencies

## Project Structure

```
RowTracker/
  App/            — App entry point and root TabView
  Models/         — SwiftData models (RowingSession, MonthlyGoal)
  ViewModels/     — DashboardViewModel
  Views/
    Dashboard/    — Main screen with river scene and progress
    Scene/        — Animated Canvas river and rower
    Sheets/       — Add session and goal setting sheets
    History/      — Session history list
  Resources/      — Asset catalog and app icon
```
