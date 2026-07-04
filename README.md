
<p align="center">
  <img src="quick_marble/assets/images/logo.jpg" width="160" alt="Quick Marble & Granite logo" />
</p>

# Quick Marble & Granite Management System
## Software Requirements Specification & Architecture (v1.0)

**Tagline:** "A Service On Your Time"

---

## 1. Overview

A mobile-first (Android + iOS), multi-office business management system for Quick Marble & Granite, covering Clients, Quotations, and Contracts, with real-time sync, offline viewing, and per-office data ownership. Desktop/Web are future phases — architecture must not block them.

**Offices (branches):** Nansana (Main), Kajjansi, Buloba, Bulenga — admin can add more anytime.

**Currency:** UGX. **Tax:** VAT 18% (configurable in Settings).
**Numbering format:** `QM0001` sequential, company-wide, zero-padded, auto-incrementing.

---

## 2. Roles & Permissions

| Capability | Administrator (Owner) | Manager | Sales Officer |
|---|---|---|---|
| View all offices | ✅ | ✅ (view-only outside own office) | ✅ (view-only outside own office) |
| Edit/create in own office | ✅ | ✅ | ✅ (own quotations only) |
| Edit/create in **other** offices | ✅ | ❌ | ❌ |
| Approve quotations | ✅ | ✅ (own office) | ❌ |
| Create contracts | ✅ | ✅ (own office) | ❌ |
| Delete records | ✅ | ❌ | ❌ |
| Manage users / assign offices | ✅ | ❌ | ❌ |
| View reports (all offices) | ✅ | ✅ (own office + summary) | ❌ |

Every user has exactly one `assignedOfficeId` (nullable for Administrator, who is global). Firestore Security Rules enforce office-scoping at the database level, not just in UI.

---

## 3. System Architecture (text diagram)

```
┌───────────────────────────────────────────────────────────┐
│                      Presentation Layer                    │
│  Flutter (Android/iOS) — Material 3 — Riverpod — GoRouter  │
│  Screens / Widgets  (per-office tabs, dashboard, modules)  │
└───────────────────────────┬─────────────────────────────────┘
                             │ (Controllers/Providers)
┌───────────────────────────▼─────────────────────────────────┐
│                      Domain Layer                            │
│  Entities, UseCases, Repository Interfaces                   │
└───────────────────────────┬─────────────────────────────────┘
                             │
┌───────────────────────────▼─────────────────────────────────┐
│                      Data Layer                               │
│  Repository Impl → Firestore Service / Local Cache (Hive)     │
│  Offline queue for pending writes (sync when online)          │
└───────────────────────────┬─────────────────────────────────┘
                             │
┌───────────────────────────▼─────────────────────────────────┐
│                        Firebase Backend                       │
│  Auth │ Firestore (streams) │ Storage │ Cloud Functions        │
│  (counters, PDF triggers, notifications, activity logging)     │
└───────────────────────────────────────────────────────────────┘
```

**Offline strategy:** Firestore's native offline persistence (enabled) handles cached reads/writes automatically; Hive is used only for user settings, last-selected office, and auth session — not as a second source of truth for business data. This avoids a fragile custom sync engine while still giving true offline viewing.

---

## 4. Firestore Collections & Schema

```
offices/{officeId}
  name: string
  location: string
  createdAt: timestamp
  isActive: bool

users/{uid}
  name, email, phone: string
  role: "admin" | "manager" | "sales_officer"
  assignedOfficeId: string | null   // null only for admin
  isActive: bool
  createdAt: timestamp

clients/{clientId}
  officeId: string          // ownership
  companyName, clientName, phone, altPhone, email: string
  address, district, country: string
  tin: string | null
  notes: string
  registrationDate: timestamp
  createdBy: uid

quotations/{quotationId}
  quotationNumber: string        // "QM0001"
  officeId: string
  clientId: string
  date: timestamp
  preparedBy: uid
  items: [ { description, material, dimensions, quantity, unitPrice, subtotal } ]
  labourCost, transportCost, discount, tax, grandTotal: number
  status: "draft" | "pending" | "approved" | "rejected" | "converted"
  createdAt, updatedAt: timestamp

contracts/{contractId}
  contractNumber: string
  officeId: string
  quotationId: string
  clientId: string
  contractValue: number
  projectLocation: string
  startDate, completionDate: timestamp
  status: "active" | "completed" | "cancelled"
  documentUrl: string | null      // Storage
  signedCopyUrl: string | null
  notes: string
  createdAt: timestamp

activity_logs/{logId}
  officeId: string
  userId: uid
  userName: string
  action: string          // "created quotation QM0001"
  targetType: "client"|"quotation"|"contract"
  targetId: string
  timestamp: timestamp

notifications/{notificationId}
  recipientUid: string | "all"
  officeId: string | null
  type: string
  message: string
  read: bool
  createdAt: timestamp

settings/company
  name, logoUrl, phone, email, tin, address: string
  currency: "UGX"
  taxPercent: number   // 18
  quotationPrefix: "QM"
  lastQuotationSeq: number   // maintained via Cloud Function transaction
```

**Indexes needed:** `quotations` on (`officeId`, `status`, `date`), `clients` on (`officeId`, `companyName`), `contracts` on (`officeId`, `status`).

---

## 5. Navigation Flow

```
Splash → Auth check
  ├─ Not logged in → Login → (Forgot Password)
  └─ Logged in → Home Shell (Bottom Nav / Drawer)
        ├─ Dashboard (company-wide summary + per-office tabs)
        │     └─ Office Tab (Nansana | Kajjansi | Buloba | Bulenga | +Add)
        ├─ Clients (list → profile → edit)
        ├─ Quotations (list → detail → PDF preview → convert to contract)
        ├─ Contracts (list → detail → upload signed copy)
        ├─ Reports
        ├─ Notifications
        └─ Settings (company profile, users, offices — admin only)
```

Dashboard's office tabs are horizontally swipeable; each shows that office's own cards/charts, while a "Company" tab aggregates all offices (visible to Admin/Manager; Sales Officer sees only their own office tab plus a read-only Company summary).

---

## 6. Folder Structure

```
lib/
  core/
    config/          (firebase_options, env)
    themes/          (brand colors, text styles)
    utils/           (validators, formatters, currency)
    errors/
  models/            (Client, Quotation, Contract, Office, AppUser, ActivityLog)
  services/          (firestore_service, storage_service, pdf_service, auth_service)
  repositories/      (interfaces + impl per module)
  controllers/       (Riverpod StateNotifiers per module)
  providers/         (riverpod providers, DI wiring)
  routes/            (go_router config, route guards by role)
  screens/
    auth/
    dashboard/
    clients/
    quotations/
    contracts/
    reports/
    settings/
  widgets/           (shared: office_tab_bar, status_chip, empty_state, etc.)
```

---

## 7. Development Roadmap (module-by-module, per your original instructions)

1. **Foundation** — Firebase project setup guidance, folder scaffold, theming (brand colors), routing skeleton, role-based route guards.
2. **Auth module** — login, password reset, session persistence, role/office claims.
3. **Offices + Users (admin)** — office CRUD, user management, office assignment.
4. **Client module** — full CRUD, office-scoped, search/filter.
5. **Quotation module** — CRUD, items builder, numbering via Cloud Function, PDF generation, status workflow.
6. **Contract module** — create-from-quotation, document upload, status tracking.
7. **Dashboard** — cards, per-office tabs, charts.
8. **Notifications + Activity Log**.
9. **Reports + PDF export**.
10. **Offline polish, security rules hardening, performance pass.**

Each step will follow: architecture explanation → models → UI → business logic → Firebase wiring → test → refactor, before moving on.

---