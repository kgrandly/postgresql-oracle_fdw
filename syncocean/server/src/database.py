from psycopg import connect

from config import Config


class Database:
    def __init__(self, config: Config):
        self._conn_string = f"postgresql://{config.db_user}:{config.db_password}@{config.db_host}/{config.db_name}"

    def connect(self):
        return connect(self._conn_string)
