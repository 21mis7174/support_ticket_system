from datetime import datetime
from pydantic import BaseModel, Field, field_validator
from app.models.ticket import Priority, TicketStatus


class CreateTicketRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(..., min_length=1, max_length=2000)
    priority: Priority

    @field_validator("title", "description")
    @classmethod
    def strip_whitespace(cls, v: str) -> str:
        return v.strip()


class TicketResponse(BaseModel):
    id: str
    title: str
    description: str
    priority: Priority
    status: TicketStatus
    created_at: datetime
    resolved_at: datetime | None = None

    model_config = {"populate_by_name": True}


class TicketListResponse(BaseModel):
    tickets: list[TicketResponse]
    total: int
