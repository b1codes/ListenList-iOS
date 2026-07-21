from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum
from app.routes import auth, list_routes, search

app = FastAPI(
    title="ListenList Serverless API",
    description="Backend API for managing Spotify media queue, completions, and user mapping in GCP.",
    version="1.0.0"
)

# CORS configuration for local development and client consumption
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust in production to allow only specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(list_routes.router, prefix="/list", tags=["Queue and Completions"])
app.include_router(search.router, prefix="/search", tags=["Spotify Search"])

@app.get("/")
def read_root():
    return {"message": "Welcome to the ListenList API!", "status": "healthy"}

# ASGI handler for AWS Lambda
handler = Mangum(app)
