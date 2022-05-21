import os


class Config:
    @property
    def srv_host(self) -> str:
        value = os.getenv("SRV_HOST")
        if value is None:
            raise Exception("SRV_HOST could not be empty")

        return value

    @property
    def srv_port(self) -> str:
        value = os.getenv("SRV_PORT")
        if value is None:
            raise Exception("SRV_PORT could not be empty")

        return value

    @property
    def db_host(self) -> str:
        value = os.getenv("DB_HOST")
        if value is None:
            raise Exception("DB_HOST could not be empty")

        return value

    @property
    def db_name(self) -> str:
        value = os.getenv("DB_NAME")
        if value is None:
            raise Exception("DB_NAME could not be empty")

        return value

    @property
    def db_user(self) -> str:
        value = os.getenv("DB_USER")
        if value is None:
            raise Exception("DB_USER could not be empty")

        return value

    @property
    def db_password(self) -> str:
        value = os.getenv("DB_PASSWORD")
        if value is None:
            raise Exception("DB_PASSWORD could not be empty")

        return value
