from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import connect_to_mongo, close_mongo_connection
from app.routes import tickets_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    yield
    await close_mongo_connection()


def create_app() -> FastAPI:
    app = FastAPI(
        title="Mini AI Support Ticket System",
        description="A simple support ticket management API",
        version="1.0.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://localhost:3000",
            "http://localhost:5000",
            "http://frontend:3000",
            "http://backend:8000",
            "http://127.0.0.1:3000",
            "http://127.0.0.1:5000",
            # EC2 Public IP and hostname
            "http://13.233.109.44:3000",
            "http://13.233.109.44:5000",
            "http://ec2-13-233-109-44.ap-south-1.compute.amazonaws.com:3000",
            "http://ec2-13-233-109-44.ap-south-1.compute.amazonaws.com:5000",
        ],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization", "*"],
    )

    app.include_router(tickets_router)

    @app.get("/health")
    async def health_check():
        return {"status": "ok"}

    return app


app = create_app()
