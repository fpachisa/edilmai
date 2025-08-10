from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    env: str = "dev"
    auth_stub: bool = True
    llm_provider: str = "openai"
    llm_model: str = "gpt-4o-mini"
    regex_enabled: bool = True
    cas_enabled: bool = True
    max_hint_level: int = 3
    enable_llm: bool = False
    vertex_project_id: str | None = None
    vertex_location: str = "asia-southeast1"

    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
