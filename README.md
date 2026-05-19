# Support Ticket System

**Enterprise-grade support ticket management platform** for handling customer issues efficiently. A full-stack application featuring real-time ticket tracking, intelligent prioritization, and seamless cloud deployment.

> **Status:** ✅ Complete & Deployed  
> **Live Demo:** https://13.233.109.44:3000  
> **API Docs:** https://13.233.109.44:8000/docs

---

## 🎯 Project Highlights

- **Real-time Updates** — Instant ticket status changes across all connected users
- **Smart Prioritization** — Low/Medium/High priority filtering and sorting  
- **Cloud Ready** — Fully containerized and deployed on AWS EC2
- **Production Grade** — Error handling, validation, and security best practices
- **API First** — RESTful API with comprehensive Swagger documentation
- **Responsive UI** — Modern Next.js frontend with loading states and dark/light theme
- **Database Persistence** — MongoDB with async drivers for high performance

---

## ⚡ Quick Start (2 minutes)

### Using Docker (Recommended)

```bash
# Clone and navigate
git clone https://github.com/21mis7174/support_ticket_system.git
cd support_ticket_system

# Start everything with one command
docker compose up --build

# Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

### Local Development

**Backend:**
```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python run.py  # http://localhost:8000
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev  # http://localhost:3000
```

---

## 🚀 Live Demo

| Component | URL |
|-----------|-----|
| **Frontend** | https://13.233.109.44:3000 |
| **Backend API** | https://13.233.109.44:8000 |
| **Swagger Docs** | https://13.233.109.44:8000/docs |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | FastAPI + Pydantic + Motor (async MongoDB) |
| **Frontend** | Next.js 15 + TypeScript + Tailwind CSS |
| **Database** | MongoDB 7.0 |
| **DevOps** | Docker + Docker Compose |
| **Cloud** | AWS EC2 (Amazon Linux 2023) |

---

## 📋 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/tickets` | Create a new ticket |
| `GET` | `/tickets` | List all tickets |
| `PATCH` | `/tickets/{id}/resolve` | Resolve a ticket |
| `GET` | `/health` | Health check |

### Example: Create Ticket
```bash
curl -X POST http://localhost:8000/tickets \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Login page broken",
    "description": "Users cannot log in after deployment",
    "priority": "high"
  }'
```

---

## ✨ Features

- ✅ **Create Tickets** — Title, Description, Priority (Low/Medium/High)
- ✅ **View All Tickets** — Live-updating list with status indicators
- ✅ **Filter by Status** — All / Open / Resolved
- ✅ **Resolve Tickets** — One-click resolution with real-time updates
- ✅ **Loading States** — Animated shimmer placeholders
- ✅ **Error Handling** — User-friendly error messages with retry option
- ✅ **Dark/Light Theme** — CSS custom properties for both modes
- ✅ **Responsive Design** — Works on desktop, tablet, and mobile

---

## 📁 Project Structure

```
support_ticket_system/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI app factory
│   │   ├── config.py            # Settings & environment
│   │   ├── database/            # MongoDB connection
│   │   ├── models/              # Document schemas
│   │   ├── routes/              # API endpoints
│   │   └── schemas/             # Request/response models
│   ├── requirements.txt
│   ├── Dockerfile
│   └── run.py                   # Dev entry point
├── frontend/
│   ├── src/
│   │   ├── app/                 # Next.js pages & layout
│   │   ├── components/          # UI components
│   │   ├── lib/                 # API client
│   │   └── types/               # TypeScript types
│   ├── Dockerfile
│   ├── package.json
│   └── next.config.ts
├── docker-compose.yml           # Service orchestration
└── README.md
```

---

## 🛠️ Setup Instructions

### Option A — Docker Compose (Recommended)

```bash
docker compose up --build

# Services will be available at:
# Frontend: http://localhost:3000
# Backend: http://localhost:8000
# MongoDB: localhost:27017
```

### Option B — Local Development

**Backend Prerequisites:** Python 3.11+, MongoDB

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate  # Linux/macOS or .venv\Scripts\activate (Windows)
pip install -r requirements.txt
cp .env.example .env
python run.py
```

**Frontend Prerequisites:** Node.js 20+

```bash
cd frontend
npm install
cp .env.local.example .env.local
npm run dev
```

---

## 🔧 Environment Variables

### Backend (`.env`)
```
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=support_tickets
```

### Frontend (`.env.local`)
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## 📸 Screenshots

### Ticket Management Dashboard
```
┌─────────────────────────────────────────────────────────┐
│  Support Tickets Dashboard                              │
├─────────────────────────────────────────────────────────┤
│  [Create Ticket]  Filter: [All] [Open] [Resolved]       │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Login Page Broken                        🔴 OPEN   │ │
│  │ Users cannot log in after deployment               │ │
│  │ Priority: HIGH  | Created: Jan 1, 10:00 AM        │ │
│  │                    [✓ Mark as Resolved]           │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ API Timeout Errors                     🔴 OPEN   │ │
│  │ Endpoints timing out under load                     │ │
│  │ Priority: MEDIUM | Created: Jan 1, 09:00 AM       │ │
│  │                    [✓ Mark as Resolved]           │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### MongoDB Connection Failed
```bash
# Check if MongoDB container is running
docker ps | grep mongo

# View logs
docker logs support_tickets_mongo
```

### Frontend Not Connecting to Backend
- Verify `NEXT_PUBLIC_API_URL` in `.env.local`
- Check backend health: `curl http://localhost:8000/health`
- Check browser console for CORS errors

### Tickets Not Loading
```bash
# Check database connection
docker exec support_tickets_mongo mongosh -u root

# Count documents
db.support_tickets_db.tickets.countDocuments()
```

---

## 📊 API Response Examples

### Create Ticket Response
```json
{
  "id": "64b1f2a3c5d6e7f8g9h0i1j2",
  "title": "Login page broken",
  "description": "Users cannot log in after deployment",
  "priority": "high",
  "status": "open",
  "created_at": "2024-01-01T10:00:00Z",
  "resolved_at": null
}
```

### List Tickets Response
```json
[
  {
    "id": "64b1f2...",
    "title": "Login page broken",
    "status": "open",
    "priority": "high",
    "created_at": "2024-01-01T10:00:00Z"
  }
]
```

---

## ✅ Completion Checklist

### Backend (FastAPI)
- [x] POST `/tickets` — Create tickets
- [x] GET `/tickets` — List all tickets
- [x] PATCH `/tickets/{id}/resolve` — Resolve tickets
- [x] MongoDB integration with async Motor driver
- [x] Pydantic validation and error handling
- [x] Clean folder structure

### Frontend (Next.js)
- [x] Create Ticket form
- [x] Tickets List with filtering
- [x] Real-time updates
- [x] Resolve functionality
- [x] Tailwind CSS styling
- [x] Loading states & error handling

### DevOps
- [x] Multi-stage Docker builds
- [x] Docker Compose orchestration
- [x] AWS EC2 deployment
- [x] Health checks
- [x] Non-root user execution
- [x] Volume persistence

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/your-feature`
3. **Commit** your changes: `git commit -m "feat: add your feature"`
4. **Push** to the branch: `git push origin feature/your-feature`
5. **Open** a Pull Request with a clear description

### Code Style
- Backend: PEP 8 with type hints
- Frontend: ESLint + Prettier configuration
- Commit messages: Follow conventional commits (feat:, fix:, docs:, etc.)

---

## 📜 License

This project is licensed under the **MIT License** — see the LICENSE file for details.

---

## 📞 Support

- **Issues:** Please use GitHub Issues for bug reports
- **Questions:** Start a GitHub Discussion
- **Email:** dev@example.com

---

## 🎓 Technologies Used

| Category | Tools |
|----------|-------|
| **Backend** | Python 3.11, FastAPI, Pydantic, Motor, Uvicorn |
| **Frontend** | Next.js 15, TypeScript, React 19, Tailwind CSS |
| **Database** | MongoDB 7.0 |
| **DevOps** | Docker, Docker Compose, AWS EC2 |
| **Quality** | Type hints, Error handling, CORS, Health checks |

---

**Made with ❤️ as a full-stack engineering assignment**
