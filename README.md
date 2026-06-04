# CareerHub

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=flat&logo=supabase&logoColor=white)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-00D9FF?style=flat)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-Academic%20%2F%20Portfolio-lightgrey)](LICENSE)

Cross-platform mobile application for **career orientation**, **professional assessment**, and **user profile management**. Built with **Flutter** and **Supabase** (PostgreSQL, Auth, Storage).

> **Thesis / portfolio project** — demonstrates full-stack mobile development, cloud backend integration, and secure data access with Row Level Security (RLS).

---

## Table of contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation & setup](#installation--setup)
- [Project structure](#project-structure)
- [Main screens](#main-screens)
- [Database overview](#database-overview)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Repository contents](#repository-contents)
- [License](#license)
- [Author](#author)

---

## Features

- **Authentication** — Email sign-up and sign-in via Supabase Auth
- **User profile** — Education, career interests, and profile photo (Storage bucket `avatars`)
- **Career assessment** — Multi-step questionnaire with field-specific questions
- **Recommendations** — Career suggestions based on assessment answers (`RecommendationEngine`)
- **Saved careers** — Save, view, and remove recommended careers
- **Dashboard & discover** — User overview and aggregated popular saved careers
- **Skills to improve** — Learning paths derived from assessment results and saved careers

---

## Tech stack

| Layer | Technology |
|-------|------------|
| **UI** | Flutter (Material 3) |
| **Language** | Dart (SDK `>=3.4.0 <4.0.0`) |
| **State management** | [Riverpod](https://riverpod.dev) |
| **Backend** | [Supabase](https://supabase.com) — PostgreSQL, Auth, Storage |
| **Client SDK** | `supabase_flutter` |
| **Media** | `image_picker` |

---

## Prerequisites

Before you begin, ensure you have:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel recommended)
- A [Supabase](https://supabase.com) account and project
- [Google Chrome](https://www.google.com/chrome/) (for web development)
- Android/iOS emulator or physical device with platform tooling configured (`flutter doctor`)

---

## Installation & setup

### 1. Clone the repository and install dependencies

```bash
git clone https://github.com/gresabruqi-git/CareerHub.git
cd CareerHub
flutter pub get
```

### 2. Configure Supabase

1. Create a project at [supabase.com/dashboard](https://supabase.com/dashboard).
2. Go to **Project Settings → API** and copy:
   - **Project URL** — e.g. `https://your-project-id.supabase.co` (**do not** include `/rest/v1/`)
   - **`anon` `public` key**
3. In `lib/main.dart`, set `supabaseUrl` and `supabaseAnonKey` to your values.

> **Security:** Use only the **anon** public key in the client app. Never expose the **service_role** key in Flutter or any client-side code.

### 3. Apply the database schema

1. In Supabase, open **SQL Editor → New query**.
2. Paste and run the full contents of [`supabase_schema.sql`](supabase_schema.sql).
3. In **Table Editor**, confirm these tables exist: `profiles`, `career_paths`, `saved_careers`.

### 4. Enable authentication

1. Open **Authentication → Providers → Email**.
2. Enable **Email** sign-in.
3. For local testing, you may disable **Confirm email** until sign-in is verified end-to-end.

### 5. Configure storage (profile photos)

1. Create a Storage bucket named **`avatars`** (if it does not already exist).
2. Set Storage policies in the Supabase dashboard so authenticated users can upload and read their own files (see notes at the end of `supabase_schema.sql`).

### 6. Run the application

```bash
flutter devices
flutter run -d chrome
```

**Other targets:**

```bash
flutter run -d windows
flutter run -d <device-id>
```

After updating Supabase credentials, perform a **hot restart** (`R` in the terminal) or restart the app.

---

## Project structure

```
lib/
├── main.dart                          # App entry point, Supabase initialization
├── data/
│   ├── models/                        # QuestionnaireAnswers, CareerFieldConfig
│   └── repositories/                  # Auth and profile repositories
├── presentation/
│   ├── screens/                       # UI screens (auth, home, assessment, etc.)
│   └── widgets/                       # AppSidebar and shared widgets
├── providers/
│   └── user_provider.dart             # User profile and Riverpod providers
└── services/
    ├── supabase_service.dart          # Database and API operations
    └── recommendation_engine.dart     # Local career recommendation logic

supabase_schema.sql                    # PostgreSQL schema, RLS policies, indexes
```

---

## Main screens

| Screen | Description |
|--------|-------------|
| `AuthWrapper` / Sign in / Sign up | Session-based routing |
| `HomeScreen` | Landing page with links to assessment and skills modules |
| `CareerAssessmentTestScreen` | Multi-step career questionnaire |
| `CareerRecommendationsScreen` | Recommendation results and save actions |
| `DashboardScreen` | User overview and saved careers |
| `ProfileScreen` | Profile editing and photo upload |
| `SavedCareersScreen` | List of saved careers |
| `DiscoverScreen` | Explore popular careers |
| `SkillsToImproveScreen` | Skills and learning suggestions |

---

## Database overview

| Table | Purpose |
|-------|---------|
| `profiles` | User profile data, `questionnaire_answers` (JSONB), optional embeddings |
| `career_paths` | Career catalog (read access for authenticated users) |
| `saved_careers` | Per-user saved career recommendations |

**Row Level Security (RLS)** ensures users can only access their own rows in `profiles` and `saved_careers`.

---

## Troubleshooting

| Issue | Suggested fix |
|-------|----------------|
| Login or sign-up fails | Verify Email provider is enabled; confirm Project URL and anon key; check email confirmation settings |
| `User not authenticated` when saving answers | Sign in before completing the assessment; refresh the app after changing credentials |
| Missing tables or RLS errors | Re-run `supabase_schema.sql`; review errors in Supabase **Logs** |
| Profile photo upload fails | Confirm the `avatars` bucket exists and Storage policies are configured |

---

## Development

```bash
flutter analyze
flutter test
```

---

## Repository contents

**Included in this repository:**

| Path | Description |
|------|-------------|
| `lib/` | Application source code |
| `android/`, `ios/`, `web/`, `windows/` | Flutter platform runners |
| `pubspec.yaml`, `pubspec.lock` | Dependency definitions |
| `supabase_schema.sql` | Database schema and RLS policies |
| `README.md`, `analysis_options.yaml`, `.gitignore` | Documentation and tooling |

**Excluded (generated locally):** `build/`, `.dart_tool/`, IDE settings, and local thesis drafts.

---

## License

This project is intended for **academic and portfolio use** unless otherwise specified.

---

## Author

**Gresa Bruqi**

Software Engineering Student | Full-Stack Developer
