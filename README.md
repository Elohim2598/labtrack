# LabTrack

Full-stack Laboratory Information Management System (LIMS) for nicotine product testing. Built with Perl (Mojolicious) on the backend and React on the frontend.

Tracks samples, test assignments, results entry, and analyst approvals with role-based access control and full audit logging.

## Tech Stack

- **Backend:** Perl 5.38, Mojolicious, DBI, DBD::Pg, Crypt::Bcrypt
- **Frontend:** React, Vite, Axios, React Router
- **Database:** PostgreSQL 16
- **Deployment:** Docker, Railway

## Features

- Sample registration with auto-generated codes (LAB-YYYY-NNNN)
- 20 nicotine product test definitions (ISO 10315, ISO 4387, ICP-MS, LC-MS/MS, etc.)
- Test assignment and result entry with auto pass/fail calculation
- Role-based access: Technician → enters results, Analyst → approves, Admin → full access
- Four-eyes approval principle (cannot approve your own results)
- Automatic sample status transitions (received → in_testing → completed)
- Dashboard with real-time lab statistics
- CSV import for bulk sample uploads
- Full audit trail on every action

## Architecture

```
labtrack/
├── backend/
│   ├── lib/
│   │   ├── LabTrack.pm                    # App entry, routing, CORS, middleware
│   │   └── LabTrack/
│   │       ├── Controller/
│   │       │   ├── Auth.pm                # Login, registration, session management
│   │       │   ├── Sample.pm              # Sample CRUD, CSV import, pagination
│   │       │   ├── Test.pm                # Test definition CRUD
│   │       │   ├── Result.pm              # Test assignment, results, approval
│   │       │   └── Dashboard.pm           # Aggregated stats and activity feed
│   │       └── Model/
│   │           └── DB.pm                  # DBI connection, query helpers, transactions
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   └── 002_seed_data.sql
│   ├── t/                                 # Test suite
│   ├── cpanfile                           # Perl dependencies
│   └── script/labtrack                    # App entry point
│
├── frontend/
│   └── src/
│       ├── services/api.js                # Axios API client
│       ├── components/Layout.jsx          # App shell with sidebar navigation
│       └── pages/
│           ├── Login.jsx
│           ├── Dashboard.jsx
│           ├── Samples.jsx
│           ├── SampleDetail.jsx
│           └── Tests.jsx
│
├── Dockerfile
├── docker-compose.yml
└── railway.toml
```

## Database Schema

Five tables: `users`, `samples`, `test_definitions`, `sample_tests`, and `audit_log`. Indexes on status, type, and audit log columns for query performance.

Sample types: cigarette, e-liquid, smokeless, snus, nicotine patch, heated tobacco.

Test categories: chemistry (nicotine, tar, CO, TSNAs, carbonyls), physical (moisture, puff count, draw resistance, filter ventilation), toxicology (heavy metals via ICP-MS).

## Quick Start

### Prerequisites

- Perl 5.32+
- PostgreSQL 14+
- Node.js 18+
- cpanm

### Local Development

```bash
# Database
createdb labtrack
psql labtrack < backend/migrations/001_initial_schema.sql
psql labtrack < backend/migrations/002_seed_data.sql

# Backend
cd backend
cpanm --installdeps .
DB_PASS=devpassword perl script/labtrack daemon -l http://*:3000

# Frontend (separate terminal)
cd frontend
pnpm install
pnpm dev
```

### Docker

```bash
docker-compose up --build
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/login | Authenticate user |
| POST | /api/auth/register | Create new user |
| GET | /api/samples | List samples (paginated, filterable) |
| POST | /api/samples | Register new sample |
| GET | /api/samples/:id | Sample detail with assigned tests |
| PUT | /api/samples/:id | Update sample |
| POST | /api/samples/import | Bulk CSV import |
| GET | /api/tests | List test definitions |
| POST | /api/tests | Create test definition |
| GET | /api/samples/:id/tests | List tests for a sample |
| POST | /api/samples/:id/tests | Assign test to sample |
| PUT | /api/sample-tests/:id | Enter test result |
| POST | /api/sample-tests/:id/approve | Approve test result |
| GET | /api/dashboard/stats | Lab overview statistics |
| GET | /api/dashboard/recent | Recent audit activity |

## License

MIT
