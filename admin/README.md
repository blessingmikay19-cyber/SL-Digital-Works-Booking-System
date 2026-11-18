# Admin app (Flutter)

It is structured as MVVM architecture:

```
lib/
  main.dart            loads config, starts Supabase
  app.dart             providers and MaterialApp.router
  core/                env.dart, app_router.dart (go_router), formatters.dart
  data/
    models/            Booking, Client, Service, BlockedTime
    repositories/      the only code that talks to Supabase
  ui/
    auth/ login/       sign-in, admin check, session state
    bookings/ calendar/ clients/ services/ time_off/
                       each screen = view + view model
    shell/ widgets/    navigation frame and shared widgets
assets/env.example     copy to assets/env and fill in your values
```

## Run

```
flutter pub get
cp assets/env.example assets/env      # then edit the two values
flutter run -d chrome
```

`assets/env` holds only the project URL and publishable key and is git-ignored. In a web build the file is bundled with the app and can be downloaded, which is fine for these two values because security comes from Row Level Security. **Never put the `service_role` key here.**

The config file is named `env` rather than `.env` because some static hosts do not serve files whose names start with a dot.

## Build and deploy (web)

```
flutter build web --release
```

Deploy `build/web` to any static host. Routing uses hash URLs, so no server rewrite rules are needed. Add `<meta name="robots" content="noindex">` to `web/index.html` so the login page is not indexed.

## Packages

`supabase_flutter`, `flutter_dotenv`, `go_router`, `provider`, `table_calendar`.
