<p align="center">
  <img src="assets/images/logo.jpg" width="160" alt="Quick Marble & Granite logo" />
</p>

<h1 align="center">Quick Marble & Granite — Management System</h1>
<p align="center"><em>"A Service On Your Time"</em></p>

<p align="center">
  A production-grade, multi-office business management platform for Clients, Quotations, and Contracts —
  built with Flutter, Firebase, and Clean Architecture.
</p>

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Roles & Permissions](#roles--permissions)
- [Offices](#offices)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Data Model](#data-model)
- [Development Roadmap](#development-roadmap)
- [Coding Standards](#coding-standards)
- [License](#license)

---

## Overview

Quick Marble & Granite operates multiple branches — **Nansana (Main), Kajjansi, Buloba, and Bulenga** — and needs one system that lets staff at every office manage their own clients, quotations, and contracts, while ownership retains full visibility and control across all branches, in real time.

This app is built mobile-first (Android & iOS), works offline for viewing data, and syncs automatically the moment connectivity returns — so a sales officer visiting a client site with a weak signal never loses productivity.

Desktop and web support are planned as a future phase; the architecture is deliberately platform-agnostic so that expansion doesn't require a rewrite.

## Key Features

- 🔐 **Secure, role-based authentication** — Administrator, Manager, Sales Officer
- 🏢 **Multi-office support** — each branch owns its own clients, quotations, and contracts; new offices can be added anytime
- 📊 **Real-time dashboard** — company-wide summary plus a dedicated tab per office
- 👤 **Client management** — full profiles, search, and filtering
- 📄 **Quotation builder** — itemized pricing, labour/transport/discount/tax, PDF generation, approval workflow
- 📑 **Contract management** — generate from an approved quotation, upload signed copies, track status
- 📶 **Offline-first** — view data anytime; writes queue and sync automatically once online
- 🔔 **Notifications & activity log** — a full audit trail of who did what, and when
- 📈 **Reports** — daily, weekly, monthly, and yearly, exportable to PDF

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Android, iOS — Windows planned) |
| Design | Material 3 |
| State Management | Riverpod |
| Routing | GoRouter |
| Backend | Firebase (Auth, Firestore, Storage, Cloud Functions) |
| Local Storage | Hive / SharedPreferences |
| PDF | `pdf` + `printing` packages |

## Architecture

The app follows **Clean Architecture**, separating UI, business logic, and data access so that no widget ever talks to Firestore directly.

```
Presentation  →  screens/, widgets/            (Flutter UI, Riverpod consumers)
Domain        →  controllers/, providers/      (business rules, state)
Data          →  repositories/, services/      (Firestore, Storage, local cache)
```

**Offline strategy:** Firestore's native offline persistence handles cached reads and queued writes for business data (clients, quotations, contracts). Hive is used only for lightweight local state — session info, last-viewed office, and user preferences — not as a second source of truth.

## Roles & Permissions

| Capability | Administrator | Manager | Sales Officer |
|---|:---:|:---:|:---:|
| View all offices | ✅ | ✅ (view-only outside own office) | ✅ (view-only outside own office) |
| Create/edit within own office | ✅ | ✅ | ✅ (own quotations only) |
| Create/edit in **other** offices | ✅ | ❌ | ❌ |
| Approve quotations | ✅ | ✅ | ❌ |
| Create contracts | ✅ | ✅ | ❌ |
| Delete records | ✅ | ❌ | ❌ |
| Manage users & offices | ✅ | ❌ | ❌ |

Every account belongs to exactly one office (`assignedOfficeId`), except Administrators, who operate globally. This is enforced both in the UI and in Firestore Security Rules.

## Offices

| Office | Location |
|---|---|
| Nansana (Main) | Nansana |
| Kajjansi Branch | Kajjansi |
| Buloba Branch | Buloba |
| Bulenga Branch | Bulenga |

Administrators can add new offices at any time as the business grows — nothing is hardcoded beyond this initial seed list.

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── config/          # environment & Firebase config
│   ├── themes/          # brand colors, Material 3 theme
│   ├── utils/           # validators, formatters, currency helpers
│   └── errors/          # shared error/exception types
├── models/              # AppUser, Office, Client, Quotation, Contract...
├── services/            # AuthService, FirestoreService, StorageService, PdfService
├── repositories/        # repository interfaces + implementations
├── controllers/         # Riverpod StateNotifiers per module
├── providers/           # DI wiring, derived state
├── routes/              # GoRouter config + role-based guards
├── screens/             # one folder per module (auth, dashboard, clients, quotations, contracts, reports, settings)
└── widgets/             # shared, reusable UI components
```

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio or VS Code with the Flutter/Dart extensions
- An Android/iOS device or emulator

### Setup

```bash
git clone <your-repo-url>
cd quick_marble_app
flutter pub get
flutter run
```

> **Note:** Firebase has not been wired in yet by design — the app currently runs against a `MockAuthService` so the full UI can be built and tested first.

### Demo Accounts

| Email | Password | Role | Office |
|---|---|---|---|
| `admin@quickmarble.ug` | `admin123` | Administrator | All offices |
| `manager.nansana@quickmarble.ug` | `manager123` | Manager | Nansana |
| `sales.kajjansi@quickmarble.ug` | `sales123` | Sales Officer | Kajjansi |

### Connecting Firebase Later

Everything depends on the `AuthService` interface (`lib/services/auth_service.dart`) — never directly on `MockAuthService`. To go live:

1. Run `flutterfire configure` to generate `firebase_options.dart`
2. Call `Firebase.initializeApp()` in `main.dart`
3. Implement `FirebaseAuthService implements AuthService`
4. Update one line in `lib/providers/auth_provider.dart` (`authServiceProvider`) to return it

No screens or controllers need to change.

## Data Model

Core Firestore collections: `offices`, `users`, `clients`, `quotations`, `contracts`, `activity_logs`, `notifications`, `settings`. Each client, quotation, and contract carries an `officeId` establishing ownership; quotations use a single globally sequential number (`QM0001`, `QM0002`, ...) assigned server-side at sync time to guarantee uniqueness even when created offline.

Full schema, indexes, and security rule design live in the project's architecture document (shared separately with the team).

## Development Roadmap

- [x] **Module 1 — Foundation:** project scaffold, theming, routing, auth wiring, role/office guards
- [ ] **Module 2 — Offices & Users:** admin management screens
- [ ] **Module 3 — Clients:** full CRUD, search, filtering
- [ ] **Module 4 — Quotations:** builder, numbering, PDF, approval workflow
- [ ] **Module 5 — Contracts:** creation from quotation, document upload
- [ ] **Module 6 — Dashboard:** cards, per-office tabs, charts
- [ ] **Module 7 — Notifications & Activity Log**
- [ ] **Module 8 — Reports & PDF export**
- [ ] **Module 9 — Offline polish, security rules, performance pass**

## Coding Standards

- Clean Architecture — no Firestore/UI code mixed together
- Meaningful, descriptive naming for classes and methods
- Reusable widgets over duplicated UI code
- All user input validated before it reaches the data layer
- Every screen designed for real daily use — loading states, empty states, and error handling are not optional

## License

Proprietary — internal use for Quick Marble & Granite only.
