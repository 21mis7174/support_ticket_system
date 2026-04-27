# Mini AI Support Ticket System

A full-stack support ticket management application built with **FastAPI**, **MongoDB**, and **Next.js**.

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
