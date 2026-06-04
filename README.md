# CareerHub

Cross-platform mobile application for **career orientation**, **professional assessment**, and **user profile management**. Built with **Flutter** and **Supabase** (PostgreSQL, Auth, Storage).

## Features

- **Authentication** — Email sign-up and sign-in via Supabase Auth
- **User profile** — Education, career interests, profile photo (Storage bucket `avatars`)
- **Career assessment** — Multi-step questionnaire with field-specific questions
- **Recommendations** — Career suggestions based on assessment answers (`RecommendationEngine`)
- **Saved careers** — Save, view, and remove recommended careers
- **Dashboard & discover** — Overview and popular saved careers across users
- **Skills to improve** — Learning paths derived from assessment and saved careers

## Tech stack

| Layer | Technology |
|-------|------------|
| UI | Flutter (Material 3) |
| Language | Dart (SDK `>=3.4.0 <4.0.0`) |
| State management | [Riverpod](https://riverpod.dev) |
| Backend | [Supabase](https://supabase.com) — PostgreSQL, Auth, Storage |
| Client SDK | `supabase_flutter` |
| Media | `image_picker` |

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel recommended)
- A [Supabase](https://supabase.com) project
- For web: [Google Chrome](https://www.google.com/chrome/)
- For Android/iOS: emulator or physical device with platform tooling (`flutter doctor`)

## Getting started

### 1. Clone and install dependencies

```bash
cd MOBILE-APP
flutter pub get
```

### 2. Configure Supabase

1. Create a project at [supabase.com/dashboard](https://supabase.com/dashboard).
2. In **Project Settings → API**, copy:
   - **Project URL** (e.g. `https://your-project-id.supabase.co`) — **without** `/rest/v1/`
   - **`anon` `public` key**
3. Open `lib/main.dart` and set `supabaseUrl` and `supabaseAnonKey` to your values.

> **Security:** Use only the **anon** public key in the app. Never commit or ship the **service_role** key in client code.

### 3. Apply the database schema

1. In Supabase, open **SQL Editor → New query**.
2. Paste and run the contents of [`supabase_schema.sql`](supabase_schema.sql).
3. Confirm tables exist in **Table Editor**: `profiles`, `career_paths`, `saved_careers`.

### 4. Enable authentication

- **Authentication → Providers → Email** — enable Email sign-in.
- For local testing, you can disable **Confirm email** until login works reliably.

### 5. Storage (profile photos)

- Create a bucket named **`avatars`** (if not already created).
- Configure Storage policies in the Supabase dashboard so users can upload/read their own files (see comments at the end of `supabase_schema.sql`).

### 6. Run the app

```bash
flutter devices
flutter run -d chrome
```

Other targets:

```bash
flutter run -d windows
flutter run -d <device-id>
```

Use **hot restart** (`R` in the terminal) after changing Supabase credentials.

## Project structure

```
lib/
├── main.dart                          # App entry, Supabase init
├── data/
│   ├── models/                        # QuestionnaireAnswers, CareerFieldConfig
│   └── repositories/                  # Auth & profile repositories
├── presentation/
│   ├── screens/                       # UI screens (auth, home, assessment, etc.)
│   └── widgets/                       # AppSidebar and shared widgets
├── providers/
│   └── user_provider.dart             # User profile & Riverpod providers
└── services/
    ├── supabase_service.dart          # Database & API operations
    └── recommendation_engine.dart     # Local career recommendation logic

supabase_schema.sql                    # PostgreSQL schema, RLS, indexes
```

## Main screens

| Screen | Description |
|--------|-------------|
| `AuthWrapper` / Sign in / Sign up | Session-based routing |
| `HomeScreen` | Landing with links to assessment and skills |
| `CareerAssessmentTestScreen` | Career questionnaire |
| `CareerRecommendationsScreen` | Results and save careers |
| `DashboardScreen` | User overview and saved careers |
| `ProfileScreen` | Profile edit and photo upload |
| `SavedCareersScreen` | List of saved careers |
| `DiscoverScreen` | Explore popular careers |
| `SkillsToImproveScreen` | Skills and learning suggestions |

## Database overview

| Table | Purpose |
|-------|---------|
| `profiles` | User profile, `questionnaire_answers` (JSONB), optional embeddings |
| `career_paths` | Career catalog (read access for authenticated users) |
| `saved_careers` | Per-user saved career recommendations |

Row Level Security (RLS) restricts users to their own `profiles` and `saved_careers` rows.

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| Login / sign-up fails | Email provider enabled; correct URL and anon key; email confirmation settings |
| `User not authenticated` when saving answers | Sign in first; session active (refresh app after credential change) |
| Missing tables / RLS errors | Re-run `supabase_schema.sql`; check Supabase logs |
| Profile photo upload fails | `avatars` bucket and Storage policies configured |

## Development

```bash
flutter analyze
flutter test
```

## Repository contents

Tracked for GitHub:

- `lib/` — application source code
- `android/`, `ios/`, `web/`, `windows/` — Flutter platform runners
- `pubspec.yaml`, `pubspec.lock` — dependencies
- `supabase_schema.sql` — database schema and RLS
- `README.md`, `analysis_options.yaml`, `.gitignore`

Not included (local only): `build/`, `.dart_tool/`, IDE settings, thesis/PDF drafts.

## License

This project is for academic / portfolio use unless otherwise specified.

## Author

AAB — Faculty of Computer Sciences, Software Engineering program (thesis project).
