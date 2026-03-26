# Livelihood Loss Compensation Estimator

**Automated Disaster Compensation System**
Rajiv Gandhi University of Knowledge and Technologies — Department of Computer Science and Engineering

> Transforming how communities recover from natural disasters through intelligent automation and mobile-first technology.

**Team:** M Revanth (B201490) · J Raghuram (B210897) · R Naresh (B210057)
**Guide:** Govardhini mam

---

## Problem Statement

Existing disaster compensation systems fail communities through:

- **Manual Review Bottlenecks** — weeks/months of delay when families need immediate support
- **Inconsistent Decisions** — subjective assessments leading to unequal compensation for similar damage
- **Administrative Dependency** — every claim requires human intervention, impossible to scale during mass disasters
- **Lack of Proof Standards** — no standard method for documenting or calculating damage

---

## Solution

A Flutter-based mobile application that automates the entire compensation workflow — from disaster loss reporting to final report generation — **without any administrative review or manual intervention**.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        User (Mobile App)                            │
│   Login  ──►  Disaster Loss Form  ──►  Upload After Photos         │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ HTTP Request
                       ▼
┌──────────────────────────────────┐
│          Backend Server          │
│   Python FastAPI                 │
│   • Data Processing              │
│   • API Request Routing          │
└──────────┬───────────────────────┘
           │ API Call
           ▼
┌──────────────────────────────────┐       ┌──────────────────────────┐
│     Image Verification API       │       │   Google Earth Engine    │
│   • Analyze Before & After Photos│◄──────│  Satellite Image Source  │
│   • Damage Detection             │       │  (Before Images)         │
└──────────┬───────────────────────┘       └──────────────────────────┘
           │ Similarity Score
           ▼
┌──────────────────────────────────┐
│       Compatibility Scoring      │
│   • Calculate Similarity Score   │
│   • Assess Loss Percentage       │
│   • Map to Damage Tier           │
│     (Minor / Moderate / Severe   │
│      / Total Loss)               │
└──────────┬───────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│      Compensation Report         │
│   • Estimate Compensation Amount │
│   • Generate PDF/JSON Report     │
│   • Instant Delivery to User     │
└──────────────────────────────────┘
```

### Flow Summary

| Step | Component | Action |
|------|-----------|--------|
| 1 | Mobile App | User submits loss form + after-disaster photo |
| 2 | Backend (FastAPI) | Processes data, calls Image Verification API |
| 3 | Google Earth Engine | Provides pre-disaster satellite images |
| 4 | Computer Vision API | Compares before/after images, detects damage |
| 5 | Scoring Engine | Computes similarity score → loss percentage |
| 6 | Report Generator | Maps score to compensation tier, generates report |

---

## App Screen Flow

```
SplashScreen
    │
    └──► LoginScreen ◄──► RegisterScreen
              │
              └──► HomeScreen (Dashboard)
                       │
                       ├──► NewClaimScreen
                       │         │
                       │         └──► ReportScreen (after AI verification)
                       │
                       └──► ClaimDetailScreen
                                   │
                                   └──► ReportScreen (existing verified claim)
```

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | Flutter (Dart) | Cross-platform mobile app (iOS & Android) |
| State Management | Riverpod 3.x | `Notifier` providers for auth & claims |
| Navigation | GoRouter 17.x | Declarative routing with `extra` data passing |
| Backend | Python — FastAPI | REST API, image processing, report logic |
| Intelligence | PIL + NumPy | Image similarity & damage detection |
| Auth | JWT (python-jose) | Stateless Bearer token authentication |
| Database | Firebase Firestore | Users, claims, reports (auto-increment IDs) |
| File Storage | Firebase Storage | After-disaster image hosting |
| PDF Reports | ReportLab | Auto-generated PDF compensation reports |
| Satellite Source | Google Earth Engine | Pre-disaster "before" image (optional) |

---

## Project Structure

> Legend: ✅ complete · ❌ not yet created

```
mob app/
├── README.md                                    ✅
│
├── backend/                                     # Python FastAPI backend
│   ├── main.py                                  ✅ FastAPI app + all routers + CORS
│   ├── requirements.txt                         ✅ All dependencies (Firebase, JWT, PIL…)
│   ├── config.py                                ✅ Env vars via python-dotenv
│   ├── database.py                              ✅ Firebase Firestore + Storage client
│   ├── .env                                     ✅ Secrets template (fill in your keys)
│   ├── firebase_service_account.json            ❌ Add your own (from Firebase Console)
│   │
│   ├── models/                                  ✅ Pydantic request/response models
│   │   ├── user.py                              ✅ UserCreate, UserLogin, UserResponse
│   │   ├── claim.py                             ✅ ClaimResponse
│   │   └── report.py                            ✅ ReportResponse
│   │
│   ├── routes/                                  ✅ API route handlers
│   │   ├── deps.py                              ✅ JWT auth dependency (get_current_user)
│   │   ├── auth.py                              ✅ POST /auth/register, POST /auth/login
│   │   ├── claims.py                            ✅ GET /claims, POST /claims, GET /claims/{id}
│   │   ├── images.py                            ✅ POST /images/verify
│   │   └── reports.py                           ✅ GET /reports/{id}, GET /reports/{id}/pdf
│   │
│   └── services/                                ✅ Business logic
│       ├── auth_service.py                      ✅ bcrypt hashing + JWT encode/decode
│       ├── image_service.py                     ✅ PIL/NumPy similarity + damage analysis
│       ├── gee_service.py                       ✅ Google Earth Engine (optional)
│       ├── scoring_service.py                   ✅ Damage tier mapping + compensation
│       └── report_service.py                    ✅ ReportLab PDF generation
│
└── frontend/                                    # Flutter mobile app
    ├── pubspec.yaml                             ✅ All dependencies declared
    ├── analysis_options.yaml                    ✅
    │
    └── lib/
        ├── main.dart                            ✅ ProviderScope + MaterialApp.router
        │
        ├── core/
        │   ├── theme.dart                       ✅ Material 3 theme (Poppins, green)
        │   ├── constants.dart                   ✅ Base URL, disaster types, tier config
        │   └── routes.dart                      ✅ GoRouter — 7 named routes + extra passing
        │
        ├── models/
        │   ├── user_model.dart                  ✅ id, name, email, token
        │   ├── claim_model.dart                 ✅ id, disasterType, location, status, etc.
        │   └── report_model.dart                ✅ similarityScore, damageTier, amount, etc.
        │
        ├── providers/
        │   ├── auth_provider.dart               ✅ AuthNotifier — login, register, logout
        │   └── claim_provider.dart              ✅ ClaimNotifier — load, submit, reports map
        │
        ├── services/                            # Ready for backend wiring
        │   ├── api_service.dart                 ✅ Dio client with auth token management
        │   ├── auth_service.dart                ✅ POST /auth/login & /register stubs
        │   ├── claim_service.dart               ✅ GET/POST /claims stubs
        │   ├── image_service.dart               ✅ Image picker + multipart upload stub
        │   └── report_service.dart              ✅ GET /reports/{claimId} stub
        │
        ├── features/
        │   ├── splash/
        │   │   └── splash_screen.dart           ✅ Animated green gradient → /login
        │   │
        │   ├── auth/
        │   │   ├── login_screen.dart            ✅ Form validation + AuthNotifier
        │   │   └── register_screen.dart         ✅ Form validation + AuthNotifier
        │   │
        │   ├── home/
        │   │   └── home_screen.dart             ✅ Stats card, shimmer, claim list, refresh
        │   │
        │   ├── claims/
        │   │   ├── new_claim_screen.dart        ✅ Full form + ImagePickerCard + AI overlay
        │   │   └── claim_detail_screen.dart     ✅ Dynamic ClaimModel display + timeline
        │   │
        │   └── reports/
        │       └── report_screen.dart           ✅ Gauge + compensation + breakdown card
        │
        └── widgets/
            ├── custom_button.dart               ✅ Reusable ElevatedButton with loading state
            ├── custom_text_field.dart           ✅ Reusable TextFormField with validation
            └── image_picker_card.dart           ✅ Gallery/camera picker with preview
```

---

## Screens

| Screen | File | Description |
|--------|------|-------------|
| Splash | `features/splash/splash_screen.dart` | Green gradient, app logo, auto-nav after 2.5s |
| Login | `features/auth/login_screen.dart` | Email + password with validation, forgot password |
| Register | `features/auth/register_screen.dart` | Name, email, password, confirm password |
| Dashboard | `features/home/home_screen.dart` | Stats card, shimmer loading, claim list, pull-to-refresh |
| New Claim | `features/claims/new_claim_screen.dart` | 7-field form, date picker, photo upload, AI overlay |
| Claim Detail | `features/claims/claim_detail_screen.dart` | Status header, info card, photo, 3-step timeline |
| Report | `features/reports/report_screen.dart` | Damage gauge, compensation card, breakdown, PDF button |

---

## State Management

```
authProvider (NotifierProvider<AuthNotifier, AuthState>)
  └── AuthState { user?, isLoading, error? }
      ├── login(email, password)
      ├── register(name, email, password)
      └── logout()

claimProvider (NotifierProvider<ClaimNotifier, ClaimState>)
  └── ClaimState { claims[], reports{id→ReportModel}, isLoading, error? }
      ├── loadClaims()          — fetch/refresh claims list
      ├── submitClaim(...)      — AI verify + generate report, returns ReportModel
      ├── getReport(claimId)    — look up report for a claim
      ├── verifiedCount         — computed getter
      └── totalCompensation     — computed getter (sum of all reports)
```

---

## Compensation Logic

```
similarityScore (0.0–1.0, from CV API)
    │
    ▼
lossPercentage = (1 − similarityScore) × 100
    │
    ▼
Damage Tier mapping:
  loss < 25%  →  Minor       →  25% of property value
  loss < 50%  →  Moderate    →  50% of property value
  loss < 80%  →  Severe      →  75% of property value
  loss ≥ 80%  →  Total Loss  → 100% of property value
    │
    ▼
compensationAmount = declaredPropertyValue × tierMultiplier
```

---

## Getting Started

### Backend

```bash
cd backend

# 1. Install dependencies
pip install -r requirements.txt

# 2. Add Firebase credentials
#    - Go to Firebase Console → Project Settings → Service Accounts
#    - Click "Generate new private key" → save as firebase_service_account.json
#    - Copy it into the backend/ folder

# 3. Configure environment
#    - Edit .env and set:
#        FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
#        SECRET_KEY=any-long-random-string

# 4. Start the server
uvicorn main:app --reload
# API docs available at http://localhost:8000/docs
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
# Runs on Android emulator (baseUrl: http://10.0.2.2:8000)
# Change baseUrl in lib/core/constants.dart for physical device
```

---

## Key Flutter Packages

| Package | Version | Use |
|---------|---------|-----|
| flutter_riverpod | ^3.3.1 | State management |
| go_router | ^17.1.0 | Navigation |
| google_fonts | ^8.0.2 | Poppins typography |
| animate_do | ^4.2.0 | FadeIn/FadeOut animations |
| shimmer | ^3.0.0 | Loading skeleton UI |
| image_picker | ^1.2.1 | Camera & gallery access |
| dio | ^5.9.2 | HTTP client |
| intl | ^0.20.2 | Date & currency formatting |

---

## Future Enhancements

- **ML-Based Classification** — Deep learning for specific damage types (structural, water, fire)
- **Government Integration** — Direct API connections to official compensation policy rules
- **Real-Time Alerts** — Push notifications for disaster warnings and claim status
- **GIS Mapping** — Geographic visualization of disaster impact zones
- **Multilingual Support** — Localized UI for diverse regional communities
- **PDF Export** — Downloadable compensation report with digital signature

---

## Conclusion

This project demonstrates how intelligent automation solves critical humanitarian challenges:

- **Fully Automated** — claim submission to report delivery with zero manual intervention
- **Zero Admin Dependency** — scales during mass disasters with no human bottlenecks
- **Fast & Transparent** — instant reports with clear damage assessment logic
- **Real-World Impact** — faster community recovery when it matters most
