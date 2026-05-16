# LabTrack — Lightweight LIMS Built with Perl

A Laboratory Information Management System (LIMS) built to learn full-stack Perl development. Tracks samples, tests, results, and lab workflows through a clean web interface.

## Why This Project?

This project is purpose-built to demonstrate the skills from a Full-Stack Perl Developer role:

| JD Requirement | How LabTrack Covers It |
|---|---|
| Complex applications using Perl | Mojolicious web framework, DBI/DBD for Postgres, OOP modules |
| JavaScript framework experience | React frontend with Vite, communicating via REST API |
| LIMS experience (plus) | The entire domain — samples, tests, results, workflows |
| Project management tools | Organized with GitHub Issues + Projects (Kanban board) |
| AI-powered tools | Built with Copilot/Claude assistance, documented in commit messages |

---

## Architecture

```
labtrack/
├── backend/                  # Perl (Mojolicious)
│   ├── lib/
│   │   ├── LabTrack.pm              # Main app class
│   │   ├── LabTrack/
│   │   │   ├── Controller/
│   │   │   │   ├── Sample.pm        # CRUD for lab samples
│   │   │   │   ├── Test.pm          # Test definitions & assignments
│   │   │   │   ├── Result.pm        # Test results entry & approval
│   │   │   │   ├── Auth.pm          # Login/session management
│   │   │   │   └── Dashboard.pm     # Stats & overview data
│   │   │   ├── Model/
│   │   │   │   ├── DB.pm            # Database connection (DBI)
│   │   │   │   ├── Sample.pm        # Sample business logic
│   │   │   │   ├── Test.pm          # Test business logic
│   │   │   │   └── User.pm          # User/auth logic
│   │   │   └── Util/
│   │   │       ├── Validator.pm     # Input validation
│   │   │       └── CSV.pm           # CSV import/export
│   ├── script/
│   │   └── labtrack               # App entry point
│   ├── t/                         # Perl tests
│   │   ├── 01-sample.t
│   │   ├── 02-test.t
│   │   └── 03-result.t
│   ├── migrations/                # SQL migration files
│   │   ├── 001_initial_schema.sql
│   │   └── 002_seed_data.sql
│   ├── cpanfile                   # Perl dependencies
│   └── labtrack.conf              # App config
│
├── frontend/                 # React + Vite
│   ├── src/
│   │   ├── components/
│   │   │   ├── Layout/
│   │   │   ├── Dashboard/
│   │   │   ├── Samples/
│   │   │   ├── Tests/
│   │   │   └── Results/
│   │   ├── hooks/
│   │   ├── services/
│   │   │   └── api.js             # Axios client for Perl API
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── package.json
│   └── vite.config.js
│
├── docker-compose.yml        # Perl app + Postgres + React dev
├── Dockerfile.backend        # Perl container
├── .github/
│   └── ISSUE_TEMPLATE/       # Templates for GitHub Issues
└── README.md
```

---

## Database Schema

```sql
-- Core tables
CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(50) UNIQUE NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,  -- bcrypt hash
    role        VARCHAR(20) DEFAULT 'technician',  -- technician | analyst | admin
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE samples (
    id            SERIAL PRIMARY KEY,
    sample_code   VARCHAR(30) UNIQUE NOT NULL,  -- auto-generated: LAB-2026-0001
    client_name   VARCHAR(100) NOT NULL,
    sample_type   VARCHAR(50) NOT NULL,         -- water, soil, blood, food, etc.
    status        VARCHAR(20) DEFAULT 'received', -- received | in_testing | completed | rejected
    received_at   TIMESTAMP DEFAULT NOW(),
    received_by   INTEGER REFERENCES users(id),
    notes         TEXT,
    created_at    TIMESTAMP DEFAULT NOW(),
    updated_at    TIMESTAMP DEFAULT NOW()
);

CREATE TABLE test_definitions (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,         -- pH Test, Bacterial Count, etc.
    category      VARCHAR(50),                   -- chemistry, microbiology, physical
    unit          VARCHAR(30),                   -- pH, CFU/mL, mg/L
    min_range     DECIMAL,                       -- acceptable range lower bound
    max_range     DECIMAL,                       -- acceptable range upper bound
    method        VARCHAR(100),                  -- testing method/standard
    created_at    TIMESTAMP DEFAULT NOW()
);

CREATE TABLE sample_tests (
    id              SERIAL PRIMARY KEY,
    sample_id       INTEGER REFERENCES samples(id) ON DELETE CASCADE,
    test_id         INTEGER REFERENCES test_definitions(id),
    assigned_to     INTEGER REFERENCES users(id),
    status          VARCHAR(20) DEFAULT 'pending', -- pending | in_progress | completed | failed
    result_value    DECIMAL,
    result_text     TEXT,
    pass_fail       VARCHAR(10),                   -- pass | fail | inconclusive
    tested_at       TIMESTAMP,
    approved_by     INTEGER REFERENCES users(id),
    approved_at     TIMESTAMP,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE audit_log (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id),
    action      VARCHAR(50) NOT NULL,
    entity_type VARCHAR(30),
    entity_id   INTEGER,
    details     JSONB,
    created_at  TIMESTAMP DEFAULT NOW()
);
```

---

## Key Perl Concepts You'll Learn

### Week 1-2: Perl Fundamentals
- [ ] Scalars, arrays, hashes
- [ ] References and dereferencing (`$ref`, `@{$ref}`, `%{$ref}`)
- [ ] Regular expressions (Perl's superpower)
- [ ] Subroutines, `my`/`local`/`our` scoping
- [ ] File I/O and CSV parsing
- [ ] CPAN and module installation

### Week 3-4: Mojolicious Framework
- [ ] Routes and controllers
- [ ] Request/response handling
- [ ] JSON API responses
- [ ] Middleware (CORS, auth)
- [ ] Template rendering (for admin fallback pages)
- [ ] Testing with `Test::Mojo`

### Week 5-6: Database & ORM
- [ ] DBI and DBD::Pg for PostgreSQL
- [ ] Parameterized queries (prevent SQL injection)
- [ ] Transaction handling
- [ ] Connection pooling
- [ ] Optional: DBIx::Class ORM

### Week 7-8: Advanced Features
- [ ] Session management & authentication (bcrypt)
- [ ] Role-based access control
- [ ] CSV import/export for bulk sample data
- [ ] Audit logging
- [ ] API pagination and filtering
- [ ] Deployment with Docker

---

## Learning Roadmap (8 Weeks)

### Phase 1 — Foundation (Weeks 1-2)
**Goal:** Get a running Perl API that returns JSON

1. Install Perl + Mojolicious locally or via Docker
2. Build a "Hello World" Mojolicious app
3. Create the `/api/samples` GET endpoint (hardcoded data)
4. Connect to PostgreSQL with DBI
5. Run the migration SQL, return real data
6. Add POST/PUT/DELETE for samples

**Milestone:** `curl localhost:3000/api/samples` returns JSON array of samples

### Phase 2 — Full CRUD + React (Weeks 3-4)
**Goal:** Working frontend talking to Perl backend

7. Scaffold React app with Vite
8. Build sample list table component
9. Add sample creation form
10. Wire up test definitions CRUD (Perl + React)
11. Implement sample → test assignment flow
12. Add status workflow (received → in_testing → completed)

**Milestone:** Can create a sample, assign tests, update status through the UI

### Phase 3 — Auth & Business Logic (Weeks 5-6)
**Goal:** Multi-user system with real lab workflows

13. User registration + bcrypt password hashing
14. Session-based auth with Mojolicious sessions
15. Role-based access (technician can enter results, analyst can approve)
16. Results entry with pass/fail auto-calculation (compare to test ranges)
17. Audit log — every action tracked
18. Dashboard stats endpoint (samples by status, tests by result, etc.)

**Milestone:** Login as different roles, enter results, approve them, see dashboard

### Phase 4 — Polish & Deploy (Weeks 7-8)
**Goal:** Portfolio-ready, interview-ready

19. CSV import for bulk sample upload
20. CSV export for completed results
21. API pagination + search/filter
22. Docker Compose setup (Perl + Postgres + React)
23. Write Perl tests with Test::Mojo
24. Deploy to a VPS or Render
25. Write up README with screenshots

**Milestone:** Live demo URL, clean GitHub repo, can walk through architecture in an interview

---

## Quick Start

### Prerequisites
- Perl 5.32+ (`perl -v`)
- PostgreSQL 14+
- Node.js 18+ (for React frontend)
- cpanm (`curl -L https://cpanmin.us | perl - --sudo App::cpanminus`)

### Install & Run

```bash
# Clone the repo
git clone https://github.com/Elohim2598/labtrack.git
cd labtrack

# Backend setup
cd backend
cpanm --installdeps .
# Create database
createdb labtrack
psql labtrack < migrations/001_initial_schema.sql
psql labtrack < migrations/002_seed_data.sql
# Run the Perl server
perl script/labtrack daemon -l http://*:3000

# Frontend setup (new terminal)
cd frontend
npm install
npm run dev
# Opens at http://localhost:5173
```

### With Docker (recommended)
```bash
docker-compose up --build
# API at http://localhost:3000
# Frontend at http://localhost:5173
```

---

## Interview Talking Points

When discussing this project in interviews, emphasize:

1. **"I chose Perl + Mojolicious because..."** — Modern Perl is clean and expressive. Mojolicious is a real-time web framework with built-in WebSocket support, non-blocking I/O, and zero non-core dependencies.

2. **"The LIMS domain taught me..."** — Data integrity matters (audit logs, status workflows), role-based access is critical in regulated environments, and traceability from sample receipt to approved result.

3. **"I structured the backend with..."** — MVC separation (Controller/Model/Util), parameterized queries for security, proper error handling with try/catch.

4. **"For the frontend I used React because..."** — Component-based architecture, easy state management for complex forms (sample → test → result flow), and it's the JS framework most Perl shops pair with.

5. **"I used AI tools by..."** — Claude/Copilot for boilerplate generation, debugging regex patterns, and generating test data. Always reviewed and understood generated code before committing.

---

## Resources

- [Mojolicious Docs](https://docs.mojolicious.org)
- [Modern Perl Book (free)](http://modernperlbooks.com/books/modern_perl_2016/)
- [DBI Documentation](https://metacpan.org/pod/DBI)
- [Perl Maven Tutorials](https://perlmaven.com)
- [Learn Perl in Y Minutes](https://learnxinyminutes.com/docs/perl/)
