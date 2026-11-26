# Hamzet Wasl (همزة وصل): Flutter app + .NET backend

One repo, two parts, already connected.

```
app/       Flutter app (Android, iOS, web). Every screen that has a backend endpoint is wired.
backend/   ASP.NET Core (.NET 10) API, SQL Server. Original backend README inside.
```

## Quick start (nothing to set up)

The app points to the hosted backend by default:
`https://hamzet-wasl-backend.onrender.com/api/v1`

```bash
cd app
flutter pub get
flutter run            # pick a device, or: flutter run -d chrome
```

Notes:
- The hosted backend is on Render free tier. After idle it sleeps, so the first request can take about 50 seconds.
- Demo mode: the OTP code for sign-up and verification is fixed at `123456` on the hosted backend. Remove `Otp__FixedCode` before real users.
- Interview slots are seeded (next 5 days) and an admin account exists on the hosted backend.

## Point the app at another backend (local or your own)

The base URL is a compile-time setting, no code change needed:

```bash
# Android emulator talking to a backend on your machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
# iOS simulator / web / desktop
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Default lives in `app/lib/core/api/api_client.dart` (`ApiClient.defaultBaseUrl`).

## Run the backend yourself

See `backend/README.md` for full details. Short version:

```bash
cd backend
docker build -t hamzet-wasl .
```
or `dotnet run --project src/HamzetWasl.Api` with a SQL Server connection string.
Required settings (environment variables, `__` = nested key):
`ConnectionStrings__DefaultConnection`, `Jwt__SigningKey`, `Storage__SigningKey`, `Otp__HashKey`.
Optional demo helpers: `Otp__FixedCode=123456`, `Seed__AdminEmail`, `Seed__AdminPassword` (admin is created on first start; slots are seeded only when an admin exists).
Swagger: `Swagger__Enabled=true`, then open `/swagger`.

## What is wired

Auth (sign up with OTP, login, session, logout), home screen, profile, accessibility, need and help type, location (real GPS),
selfie and document upload, social links, email/phone verification, interview slots, and the organization flow
(company/association: details, logo, documents, submit, review notes).

## Platform permissions already added

Android: internet, location, camera (`android/app/src/main/AndroidManifest.xml`, cleartext allowed for local HTTP testing).
iOS: location, camera, photo library usage texts (`ios/Runner/Info.plist`).

## Tests

```bash
cd app
flutter test                                   # unit + widget tests
RUN_LIVE_API=1 flutter test test/live_profile_test.dart test/live_org_test.dart   # hits the hosted backend
```
Live tests create dummy `@example.com` accounts on the backend they run against.

## Known gaps

- Google sign-in: backend returns `GOOGLE_NOT_CONFIGURED` until a Google client ID is set (`Google__ClientId`) and the app gets a Google client setup.
- `app/assets/map_preview.png` is a placeholder (the original repo referenced it but did not contain it).
- Screens without a backend endpoint (notifications, training, admin dashboard) are not in the app.
