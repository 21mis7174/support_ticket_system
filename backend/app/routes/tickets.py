from datetime import datetime, timezone
from bson import ObjectId
from bson.errors import InvalidId
from fastapi import APIRouter, HTTPException, status

from app.database import get_database
from app.schemas.ticket import CreateTicketRequest, TicketResponse, TicketListResponse

router = APIRouter(prefix="/tickets", tags=["tickets"])


def _serialize_ticket(doc: dict) -> TicketResponse:
    """Convert a MongoDB document to a TicketResponse."""
    return TicketResponse(
        id=str(doc["_id"]),
        title=doc["title"],
        description=doc["description"],
        priority=doc["priority"],
        status=doc["status"],
        created_at=doc["created_at"],
        resolved_at=doc.get("resolved_at"),
    )


@router.post("", response_model=TicketResponse, status_code=status.HTTP_201_CREATED)
async def create_ticket(payload: CreateTicketRequest) -> TicketResponse:
    """Create a new support ticket."""
    db = get_database()
    ticket_doc = {
        "title": payload.title,
        "description": payload.description,
        "priority": payload.priority.value,
        "status": "open",
        "created_at": datetime.now(timezone.utc),
        "resolved_at": None,
    }
    result = await db["tickets"].insert_one(ticket_doc)
    created = await db["tickets"].find_one({"_id": result.inserted_id})
    if created is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create ticket",
        )
    return _serialize_ticket(created)


@router.get("", response_model=TicketListResponse)
async def list_tickets() -> TicketListResponse:
    """List all support tickets, newest first."""
    db = get_database()
    cursor = db["tickets"].find({}).sort("created_at", -1)
    docs = await cursor.to_list(length=None)
    tickets = [_serialize_ticket(doc) for doc in docs]
    return TicketListResponse(tickets=tickets, total=len(tickets))


@router.patch("/{ticket_id}/resolve", response_model=TicketResponse)
async def resolve_ticket(ticket_id: str) -> TicketResponse:
    """Mark a ticket as resolved."""
    try:
        oid = ObjectId(ticket_id)
    except (InvalidId, Exception):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid ticket ID: {ticket_id!r}",
        )

    db = get_database()
    result = await db["tickets"].find_one_and_update(
        {"_id": oid},
        {"$set": {"status": "resolved", "resolved_at": datetime.now(timezone.utc)}},
        return_document=True,
    )
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ticket {ticket_id!r} not found",
        )
    return _serialize_ticket(result)
