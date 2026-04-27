# Mini AI Support Ticket System

A full-stack support ticket management application built with **FastAPI**, **MongoDB**, and **Next.js**.

> **Assignment:** Full Stack Developer – Mini AI Support Ticket System  
> **Status:** ✅ Complete & Deployed

---

## 🚀 Live Demo

**Frontend:** https://13.233.109.44:3000  
**Backend API:** https://13.233.109.44:8000  
**Swagger API Docs:** https://13.233.109.44:8000/docs  
**GitHub Repository:** https://github.com/21mis7174/support_ticket_system

---

## Tech Stack

| Layer      | Technology                          |
|------------|-------------------------------------|
| Backend    | FastAPI + Pydantic + Motor (async MongoDB driver) |
| Database   | MongoDB                              |
| Frontend   | Next.js 15 (App Router) + TypeScript + Tailwind CSS |
| Container  | Docker + Docker Compose             |

---

## Project Structure

```
project/
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI app factory + lifespan
│   │   ├── config.py        # Settings (env vars)
│   │   ├── database/        # MongoDB connection
│   │   ├── models/          # Document models
│   │   ├── routes/          # API route handlers
│   │   └── schemas/         # Pydantic request/response schemas
│   ├── requirements.txt
│   ├── run.py               # Dev entry point
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── app/             # Next.js App Router pages + layout
│   │   ├── components/      # UI components
│   │   ├── lib/             # API client
│   │   └── types/           # TypeScript types
│   ├── Dockerfile
│   └── next.config.ts
└── docker-compose.yml
```

---

## API Endpoints

| Method  | Endpoint                      | Description              |
|---------|-------------------------------|--------------------------|
| `POST`  | `/tickets`                    | Create a new ticket      |
| `GET`   | `/tickets`                    | List all tickets         |
| `PATCH` | `/tickets/{id}/resolve`       | Mark a ticket as resolved|
| `GET`   | `/health`                     | Health check             |

### POST `/tickets` — Request Body

```json
{
  "title": "Login page is broken",
  "description": "Users cannot log in after the latest deployment.",
  "priority": "high"
}
```

Priority values: `"low"` | `"medium"` | `"high"`

### Ticket Response Schema

```json
{
  "id": "64b1f2...",
  "title": "Login page is broken",
  "description": "Users cannot log in after the latest deployment.",
  "priority": "high",
  "status": "open",
  "created_at": "2024-01-01T10:00:00Z",
  "resolved_at": null
}
```

---

## Setup Instructions

### Option A — Docker Compose (Recommended)

**Prerequisites:** Docker + Docker Compose

```bash
# Clone / navigate to the project root
cd project/

# Start all services (FastAPI + Next.js + MongoDB)
docker compose up --build

# Access:
#   Frontend → http://localhost:3000
#   Backend API → http://localhost:8000
#   API Docs (Swagger) → http://localhost:8000/docs
```

To stop:

```bash
docker compose down
```

---

### Option B — Local Development

#### Backend

**Prerequisites:** Python 3.11+, MongoDB running locally

```bash
cd backend/

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate   # Linux/macOS
# .venv\Scripts\activate    # Windows

# Install dependencies
pip install -r requirements.txt

# Copy env file
cp .env.example .env
# Edit .env if your MongoDB URL is different

# Run development server
python run.py
# API: http://localhost:8000
# Swagger UI: http://localhost:8000/docs
```

#### Frontend

**Prerequisites:** Node.js 20+

```bash
cd frontend/

# Install dependencies
npm install

# Copy env file
cp .env.local.example .env.local
# Edit NEXT_PUBLIC_API_URL if needed

# Run development server
npm run dev
# App: http://localhost:3000
```

---

## Features

- **Create Ticket** — Form with Title, Description, and Priority (Low/Medium/High)
- **View All Tickets** — Live-updating list with status indicators and priority badges
- **Filter by Status** — Filter tickets by All / Open / Resolved
- **Resolve Ticket** — One-click resolve button updates status in real time
- **Loading skeletons** — Animated shimmer placeholders while data loads
- **Error handling** — User-friendly error messages with retry option
- **Dark/Light theme tokens** — CSS custom properties from the design system

---

## Error Handling

| Scenario                | HTTP Status | Response                                   |
|-------------------------|-------------|---------------------------------------------|
| Missing required fields | `422`       | Pydantic validation error details            |
| Ticket not found        | `404`       | `{"detail": "Ticket '...' not found"}`      |
| Invalid ticket ID       | `400`       | `{"detail": "Invalid ticket ID: '...'"}`    |
| Server error            | `500`       | `{"detail": "..."}`                         |

---

## Environment Variables

### Backend (`.env`)

| Variable        | Default                      | Description              |
|-----------------|------------------------------|--------------------------|
| `MONGODB_URL`   | `mongodb://localhost:27017`  | MongoDB connection string |
| `DATABASE_NAME` | `support_tickets`            | MongoDB database name     |

### Frontend (`.env.local`)

| Variable              | Default                   | Description           |
|-----------------------|---------------------------|-----------------------|
| `NEXT_PUBLIC_API_URL` | `http://localhost:8000`   | FastAPI backend URL   |

---

## Screenshots

### Tickets List (with create form)

```
┌─────────────────────────────────────────────────────────────────┐
│  ST  Support Tickets                          2 Open  1 Resolved │
├─────────────────────────────────────────────────────────────────┤
│  NEW TICKET              │  ALL TICKETS (3)    [all][open][res]  │
│  ┌───────────────────┐   │  ┌─────────────────────────────────┐ │
│  │ Title *           │   │  │ Login page broken        OPEN   │ │
│  │ [                ]│   │  │ Users cannot log in...          │ │
│  │ Description *     │   │  │ HIGH            Jan 1, 10:00 AM │ │
│  │ [                ]│   │  │            [✓ Mark as Resolved] │ │
│  │ Priority          │   │  └─────────────────────────────────┘ │
│  │ [Medium      ▼]  │   │  ┌─────────────────────────────────┐ │
│  │ [Create Ticket]   │   │  │ API timeout errors      OPEN   │ │
│  └───────────────────┘   │  │ Endpoints timing out...         │ │
│                           │  │ MEDIUM          Jan 1, 09:00 AM │ │
│                           │  │            [✓ Mark as Resolved] │ │
│                           │  └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ Assignment Completion Checklist

### PART 1 ✅ Backend (FastAPI)
- [x] `POST /tickets` — Create ticket with title, description, priority
- [x] `GET /tickets` — List all tickets, newest first
- [x] `PATCH /tickets/{id}/resolve` — Mark ticket as resolved
- [x] MongoDB integration with Motor (async driver)
- [x] Pydantic models for validation (request/response)
- [x] Clean folder structure (models/, routes/, database/, schemas/)
- [x] Error handling: missing fields (422), ticket not found (404), invalid ID (400)

### PART 2 ✅ Frontend (Next.js)
- [x] Create Ticket page with form (Title, Description, Priority)
- [x] Submit → POST to FastAPI backend
- [x] Tickets List page displaying all tickets
- [x] Each card shows: Title, Description, Priority, Status
- [x] Resolve button → PATCH endpoint
- [x] Fetch API integration
- [x] Tailwind CSS styling
- [x] Loading states & error handling
- [x] Filter tickets by status (All / Open / Resolved)

### PART 3 ✅ Docker & Deployment
- [x] Dockerfile for FastAPI backend (multi-stage, optimized)
- [x] Dockerfile for Next.js frontend (multi-stage, 267MB)
- [x] docker-compose.yml with FastAPI + Next.js + MongoDB
- [x] Health checks for all services
- [x] Non-root user execution (security)
- [x] BuildKit optimizations (npm/pip cache mounts)
- [x] Proper dependency management (mongo → backend → frontend)

### PART 4 ✅ Cloud Deployment
- [x] AWS EC2 deployment (Amazon Linux 2023, ap-south-1)
- [x] Public IP: 13.233.109.44
- [x] All services running and healthy
- [x] 10 seeded test tickets in MongoDB
- [x] CORS properly configured
- [x] Timezone display fixed (UTC)
- [x] Database persistence with volumes
- [x] Auto-restart on failure (unless-stopped)

### PART 5 ✅ Submission Requirements
- [x] GitHub repository: https://github.com/21mis7174/support_ticket_system
- [x] README.md with setup instructions
- [x] API endpoint documentation
- [x] Live demo link: http://13.233.109.44:3000
- [x] Environment configuration examples
- [x] Deployment instructions
- [x] Error handling documentation

---

## 🔧 Troubleshooting

### MongoDB Connection Issues
```bash
# Verify MongoDB container is running
docker ps | grep mongo

# Check logs
docker logs support_tickets_mongo
```

### Frontend Not Connecting to Backend
- Ensure `NEXT_PUBLIC_API_URL` is set to `http://13.233.109.44:8000` (or your backend URL)
- Check browser console for CORS errors
- Verify backend is running: `curl http://13.233.109.44:8000/health`

### Tickets Not Showing
- Check database connection: `docker exec support_tickets_mongo mongosh -u root`
- Verify collection has data: `db.support_tickets_db.tickets.countDocuments()`
- Check backend logs: `docker logs support_tickets_backend`

---

## 📝 API Usage Examples

### Create a Ticket
```bash
curl -X POST http://13.233.109.44:8000/tickets \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Login page broken",
    "description": "Users cannot log in after deployment",
    "priority": "high"
  }'
```

### List All Tickets
```bash
curl http://13.233.109.44:8000/tickets | python3 -m json.tool
```

### Resolve a Ticket
```bash
curl -X PATCH http://13.233.109.44:8000/tickets/69ef9cee62fdf1ae2cf1267f/resolve
```

---

## 📂 Repository Structure

```
support_ticket_system/
 backend/
   ├── app/
   │   ├── main.py              # FastAPI application
   │   ├── config.py            # Settings & environment
   │   ├── database/
   │   │   └── connection.py    # MongoDB async client
   │   ├── models/
   │   │   └── ticket.py        # Document schemas
   │   ├── routes/
   │   │   └── tickets.py       # API endpoints
   │   └── schemas/
   │       └── ticket.py        # Request/response models
   ├── requirements.txt
   ├── .env                     # Environment variables
   ├── Dockerfile               # Multi-stage build
   └── run.py                   # Development entry point
 frontend/
   ├── src/
   │   ├── app/                 # Next.js pages & layout
   │   ├── components/
   │   │   ├── TicketList.tsx   # Tickets display
   │   │   └── TicketCard.tsx   # Single ticket card
   │   ├── lib/
   │   │   └── api.ts           # API client
   │   ├── types/
   │   │   └── ticket.ts        # TypeScript types
   │   └── styles/              # Global styles
   ├── public/
   ├── package.json
   ├── Dockerfile               # Multi-stage build (267MB)
   ├── next.config.ts
   └── tsconfig.json
 docker-compose.yml           # Service orchestration
 .gitignore
 README.md                    # This file
```

---

## 🎓 Technologies Used

| Category | Technologies |
|----------|---|
| **Backend** | Python 3.11, FastAPI, Pydantic, Motor (async MongoDB), Uvicorn |
| **Frontend** | Next.js 15, TypeScript, React 19, Tailwind CSS |
| **Database** | MongoDB 7.0, Motor async driver |
| **DevOps** | Docker, Docker Compose, Docker BuildKit |
| **Cloud** | AWS EC2 (Amazon Linux 2023), SSH, Git |
| **Quality** | Error handling, Type hints, CORS setup, Health checks |

---

## 📧 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review backend logs: `docker logs support_tickets_backend`
3. Review frontend browser console (F12)
4. Open an issue on GitHub

---

**Last Updated:** April 27, 2026  
**Status:** ✅ Production Ready  
**Deployment:** AWS EC2 (ap-south-1)  
**GitHub:** https://github.com/21mis7174/support_ticket_system
