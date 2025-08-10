from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    env: str = "dev"
    auth_stub: bool = True
    llm_provider: str = "gemini"
    llm_model: str = "gemini-2.5-flash-lite"
    regex_enabled: bool = False
    cas_enabled: bool = True
    max_hint_level: int = 3
    enable_llm: bool = True
    vertex_project_id: str | None = None
    vertex_location: str = "asia-southeast1"
    google_api_key: str | None = None

    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
