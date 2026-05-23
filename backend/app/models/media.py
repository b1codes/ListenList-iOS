from pydantic import BaseModel, Field
from typing import List, Optional

class ImageSchema(BaseModel):
    url: str
    height: Optional[int] = None
    width: Optional[int] = None

class ArtistSchema(BaseModel):
    id: str
    name: str
    popularity: Optional[int] = None
    images: Optional[List[ImageSchema]] = None
    genres: Optional[List[str]] = None
    showOnList: Optional[bool] = None
    rating: Optional[int] = None
    comment: Optional[str] = None
    isCompleted: Optional[bool] = False

class AlbumSchema(BaseModel):
    id: str
    name: str
    releaseDate: str = Field(..., alias="release_date")
    images: List[ImageSchema]
    artists: List[ArtistSchema]
    albumType: str = Field(..., alias="album_type")
    isExplicit: Optional[bool] = False
    genres: Optional[List[str]] = None
    label: Optional[str] = None
    rating: Optional[int] = None
    comment: Optional[str] = None
    isCompleted: Optional[bool] = False

    class Config:
        populate_by_name = True

class SongSchema(BaseModel):
    id: str
    name: str
    album: AlbumSchema
    artists: List[ArtistSchema]
    durationMs: int = Field(..., alias="duration_ms")
    popularity: int
    explicit: bool
    rating: Optional[int] = None
    comment: Optional[str] = None
    isCompleted: Optional[bool] = False

    class Config:
        populate_by_name = True

class PodcastSchema(BaseModel):
    id: str
    name: str
    publisher: str
    images: List[ImageSchema]
    explicit: bool
    description: str
    totalEpisodes: int = Field(..., alias="total_episodes")
    rating: Optional[int] = None
    comment: Optional[str] = None
    isCompleted: Optional[bool] = False

    class Config:
        populate_by_name = True

class AuthorSchema(BaseModel):
    name: str

class NarratorSchema(BaseModel):
    name: str

class AudiobookSchema(BaseModel):
    id: str
    name: str
    authors: List[AuthorSchema]
    images: List[ImageSchema]
    explicit: bool
    description: str
    edition: str
    narrators: List[NarratorSchema]
    publisher: str
    totalChapters: Optional[int] = Field(None, alias="total_chapters")
    rating: Optional[int] = None
    comment: Optional[str] = None
    isCompleted: Optional[bool] = False

    class Config:
        populate_by_name = True

class QueueItemCreate(BaseModel):
    id: str
    entity_type: str  # song, album, artist, podcast, audiobook
    metadata: dict

class CompletionLogRequest(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = ""
