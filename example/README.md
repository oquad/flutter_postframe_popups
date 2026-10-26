Run `flutter pub get`, then `flutter run -d chrome` from this directory.

Start with the small usage demos:

- [Callback](lib/demos/callback_demo.dart)
- [Dialog](lib/demos/dialog_demo.dart)
- [Bottom sheet](lib/demos/bottom_sheet_demo.dart)
- [Explicit focus recipe](lib/demos/focus_demo.dart)
- [Spotlight](lib/demos/spotlight_demo.dart)

Dialog/sheet content lives in `lib/content/`. Feedback callbacks and custom
presenters live in `lib/support/`. `app.dart` and `demo_home.dart` contain the
application scaffolding and navigation.
