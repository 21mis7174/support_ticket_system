import motor.motor_asyncio
from app.config import settings

client: motor.motor_asyncio.AsyncIOMotorClient | None = None
db = None


async def connect_to_mongo() -> None:
    global client, db
    client = motor.motor_asyncio.AsyncIOMotorClient(settings.mongodb_url)
    db = client[settings.database_name]


async def close_mongo_connection() -> None:
    global client
    if client is not None:
        client.close()


def get_database():
    return db
