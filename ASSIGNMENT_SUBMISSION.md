# Mini AI Support Ticket System

## Assignment Submission - Mindtide.ai
**Full Stack Developer Position**

---

## GitHub Repository

**https://github.com/21mis7174/support_ticket_system**

---

## Live Demo

- **Frontend:** http://13.233.109.44:3000
- **Backend API:** http://13.233.109.44:8000
- **API Documentation:** http://13.233.109.44:8000/docs

---

## Project Overview

A full-stack web application for managing support tickets. Users can create tickets with priority levels, view all tickets, filter by status, and mark tickets as resolved with real-time updates.

### Key Features

- Create tickets with title, description, and priority (Low/Medium/High)
- View all tickets in organized list format
- Filter tickets by status (All / Open / Resolved)
- Mark tickets as resolved with automatic timestamp
- Real-time UI updates and status indicators
- Responsive design compatible with desktop and mobile
- Production-ready Docker deployment on AWS EC2

### Technology Stack

- **Backend:** Python 3.11, FastAPI, Pydantic, Motor (async MongoDB), Uvicorn
- **Frontend:** Next.js 16, TypeScript, React 19, Tailwind CSS
- **Database:** MongoDB 7.0
- **DevOps:** Docker, Docker Compose, AWS EC2 (t2.micro, ap-south-1)

---

## API Endpoints

### 1. Create Ticket (POST /tickets)

**Request:**
```bash
curl -X POST http://13.233.109.44:8000/tickets \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Login page broken",
    "description": "Users cannot log in after deployment",
    "priority": "high"
  }'
```

**Response (201 Created):**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "title": "Login page broken",
  "description": "Users cannot log in after deployment",
  "priority": "high",
  "status": "open",
  "created_at": "2026-04-27T18:09:46.484000Z"
}
```

### 2. List All Tickets (GET /tickets)

**Request:**
```bash
curl http://13.233.109.44:8000/tickets | python3 -m json.tool
```

**Response (200 OK):**
- Returns array of all tickets with total count
- Tickets sorted by creation date (newest first)

### 3. Resolve Ticket (PATCH /tickets/{id}/resolve)

**Request:**
```bash
curl -X PATCH http://13.233.109.44:8000/tickets/507f1f77bcf86cd799439011/resolve
```

**Response (200 OK):**
- Returns updated ticket with resolved status and timestamp

### Error Responses

| Status Code | Meaning |
|-------------|---------|
| 422 | Missing required fields |
| 404 | Ticket not found |
| 400 | Invalid ticket ID |

### Test API

Interactive Swagger documentation: http://13.233.109.44:8000/docs

---

## Application Screenshots

### Figure 1: Main Tickets List Page

The main dashboard displaying all support tickets with:
- Status indicators (Open/Resolved)
- Priority badges (Low/Medium/High) with color coding
- Ticket titles and descriptions
- Relative timestamps ("2 minutes ago", "just now", etc.)
- Filter tabs (All / Open / Resolved)
- One-click "Mark as Resolved" button for each ticket
- Loading states and error handling

### Figure 2: Create New Ticket Form

Form for creating new support tickets with:
- Title input field
- Description textarea
- Priority level dropdown selector (Low/Medium/High)
- Submit button
- Input validation and error messages

---

## Assignment Completion Checklist

### PART 1: Backend (FastAPI) ✓

| Requirement | Status |
|-------------|--------|
| POST /tickets endpoint | Complete |
| GET /tickets endpoint | Complete |
| PATCH /tickets/{id}/resolve | Complete |
| MongoDB integration with Motor | Complete |
| Pydantic models and validation | Complete |
| Error handling (422/404/400) | Complete |
| Clean folder structure | Complete |

### PART 2: Frontend (Next.js) ✓

| Requirement | Status |
|-------------|--------|
| Create Ticket page with form | Complete |
| Tickets List page | Complete |
| Resolve button functionality | Complete |
| Filter by status (All/Open/Resolved) | Complete |
| Fetch API integration | Complete |
| Tailwind CSS styling | Complete |
| Loading and error states | Complete |

### PART 3: Docker & Containerization ✓

| Requirement | Status |
|-------------|--------|
| Backend Dockerfile (multi-stage) | Complete |
| Frontend Dockerfile (multi-stage) | Complete |
| docker-compose.yml orchestration | Complete |
| Health checks for all services | Complete |
| Non-root user execution | Complete |
| Service dependency management | Complete |

### PART 4: Cloud Deployment ✓

| Requirement | Status |
|-------------|--------|
| AWS EC2 instance (t2.micro, ap-south-1) | Complete |
| Public IP: 13.233.109.44 | Complete |
| MongoDB with 10 seeded test tickets | Complete |
| CORS configuration | Complete |
| Auto-restart on failure | Complete |
| UTC timezone handling | Complete |

### PART 5: Submission Requirements ✓

| Requirement | Status |
|-------------|--------|
| GitHub repository link | Complete |
| README with setup instructions | Complete |
| API endpoints documentation | Complete |
| Screenshots | Complete |
| Live demo link (running 24/7) | Complete |

---

## Quick Start Guide

### Option 1: Docker Compose (Recommended)

```bash
# Clone repository
git clone https://github.com/21mis7174/support_ticket_system.git
cd support_ticket_system

# Start all services
docker compose up -d

# Access the application
# Frontend:  http://localhost:3000
# Backend:   http://localhost:8000
# API Docs:  http://localhost:8000/docs
```

### Option 2: Local Development

**Backend Setup:**
```bash
cd backend/

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run development server
python run.py
# API: http://localhost:8000
```

**Frontend Setup (new terminal):**
```bash
cd frontend/

# Install dependencies
npm install

# Run development server
npm run dev
# App: http://localhost:3000
```

### Stop Services

```bash
docker compose down
```

---

## Environment Configuration

### Backend (.env)

```
MONGODB_URL=mongodb://mongo:27017/support_tickets_db
DATABASE_NAME=support_tickets_db
```

### Frontend (.env.local)

```
NEXT_PUBLIC_API_URL=http://13.233.109.44:8000
```

---

## AWS EC2 Deployment Details

### Instance Configuration

- **Instance Type:** t2.micro (Free tier eligible)
- **Region:** ap-south-1 (Mumbai)
- **AMI:** Amazon Linux 2023
- **Public IP:** 13.233.109.44
- **Hostname:** ec2-13-233-109-44.ap-south-1.compute.amazonaws.com

### Running Services

- MongoDB 7.0 (Port 27017)
- FastAPI Backend (Port 8000)
- Next.js Frontend (Port 3000)

### Infrastructure

- All services in Docker containers
- Health checks configured for automatic restart
- Database persistence with Docker volumes
- Non-root user execution for security
- CORS configured for frontend-backend communication

---

## Testing the Application

Visit **http://13.233.109.44:3000** to test the following:

1. **Create a new ticket**
   - Click "Create Ticket"
   - Fill in title, description
   - Select priority level
   - Submit form
   - Verify ticket appears in list

2. **View all tickets**
   - 10 seeded test tickets should be visible
   - Tickets display title, description, priority, status
   - Timestamps show relative time

3. **Filter tickets by status**
   - Click "All" tab to see all tickets
   - Click "Open" tab to see only open tickets
   - Click "Resolved" tab to see only resolved tickets

4. **Resolve a ticket**
   - Click "Mark as Resolved" button on any ticket
   - Ticket status updates to "Resolved"
   - Ticket disappears from "Open" filter
   - Appears in "Resolved" filter

5. **Test API endpoints**
   - Visit http://13.233.109.44:8000/docs
   - Interactive Swagger documentation
   - Try creating, listing, and resolving tickets via API

---

## Troubleshooting

### Frontend Not Connecting to Backend

- Ensure `NEXT_PUBLIC_API_URL` is set to correct backend URL
- Check browser console (F12) for CORS errors
- Verify backend is running: `curl http://13.233.109.44:8000/health`
- Check firewall/network settings on EC2

### MongoDB Connection Issues

```bash
# Check MongoDB container status
docker ps | grep mongo

# View MongoDB logs
docker logs support_tickets_mongo

# Connect to MongoDB directly
docker exec -it support_tickets_mongo mongosh
```

### Tickets Not Showing

```bash
# Check database has data
docker exec support_tickets_mongo mongosh
# In mongosh: db.support_tickets_db.tickets.countDocuments()

# Check backend logs
docker logs support_tickets_backend

# Test API directly
curl http://13.233.109.44:8000/tickets
```

---

## Repository Structure

```
support_ticket_system/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI application
│   │   ├── config.py            # Settings & environment
│   │   ├── database/
│   │   │   └── connection.py    # MongoDB async client
│   │   ├── models/
│   │   │   └── ticket.py        # Document schemas
│   │   ├── routes/
│   │   │   └── tickets.py       # API endpoints
│   │   └── schemas/
│   │       └── ticket.py        # Request/response models
│   ├── requirements.txt
│   ├── .env
│   ├── Dockerfile
│   └── run.py
├── frontend/
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   │   ├── TicketList.tsx
│   │   │   └── TicketCard.tsx
│   │   ├── lib/
│   │   │   └── api.ts
│   │   └── types/
│   │       └── ticket.ts
│   ├── Dockerfile
│   ├── package.json
│   └── next.config.ts
├── screenshots/
│   ├── home_page.png
│   └── new_ticket.png
├── docker-compose.yml
├── README.md
└── ASSIGNMENT_SUBMISSION.md
```

---

## What's Included in Submission

### Part 1: Backend
- FastAPI with 3 REST endpoints (POST, GET, PATCH)
- MongoDB integration with Motor async driver
- Pydantic models for request/response validation
- Proper error handling with HTTP status codes
- Clean folder structure

### Part 2: Frontend
- Next.js application with TypeScript
- Create ticket page with form
- Tickets list page with filtering
- Resolve functionality
- Tailwind CSS styling
- React hooks for state management
- Loading and error states

### Part 3: Docker
- Multi-stage optimized Dockerfiles
- docker-compose.yml with 3 services
- Health checks for all services
- Non-root user execution
- Database persistence

### Part 4: Deployment
- AWS EC2 instance (t2.micro, free tier)
- All services running and healthy
- 10 seeded test tickets
- CORS properly configured
- Auto-restart on failure
- UTC timezone handling

### Part 5: Documentation
- GitHub repository with full source code
- Comprehensive README.md
- This assignment submission document
- API documentation (Swagger/OpenAPI)
- Application screenshots
- Live demo running 24/7

---

## Submission Summary

### Submitted Deliverables

✓ GitHub Repository: https://github.com/21mis7174/support_ticket_system
✓ Live Demo: http://13.233.109.44:3000 (running 24/7)
✓ Backend API: http://13.233.109.44:8000
✓ API Documentation: http://13.233.109.44:8000/docs
✓ Complete source code on GitHub
✓ Comprehensive README
✓ Application screenshots
✓ Docker configuration
✓ All 5 assignment parts implemented

### Submission Date

- **Submitted:** 28 April 2026
- **Deadline:** 29 April 2026
- **Status:** Complete and Ready for Review

---

## Contact & Support

For questions or issues:

1. Check GitHub repository for complete source code
2. Review README.md for detailed documentation
3. Test live demo at http://13.233.109.44:3000
4. Open issues on GitHub: https://github.com/21mis7174/support_ticket_system/issues

---

**All assignment requirements completed. Application is production-ready and deployed.**
