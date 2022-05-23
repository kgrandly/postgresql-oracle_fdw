from json import dumps
from uuid_encoder import UUIDEncoder

from bottle import post, request, response, run
from psycopg import sql

from config import Config
from database import Database

config = Config()
database = Database(config)


def to_json(obj):
    response.content_type = 'application/json'
    return dumps(obj, cls=UUIDEncoder)


@post("/request/list")
def get_request_list():
    try:
        with database.connect() as conn:
            args = (dumps(request.json),)
            cur = conn.execute("select syncocean.get_request_list(%s)", args)
            return to_json({"Status": True, "Payload": cur.fetchone()[0]})
    except Exception as ex:
        return to_json({"Status": False, "Error": str(ex)})


@post("/request/nu")
def upd_request():
    try:
        with database.connect() as conn:
            args = (dumps(request.json),)
            cur = conn.execute("select syncocean.nu_request(%s)", args)
            return to_json({"Status": True, "Payload": cur.fetchone()[0]})
    except Exception as ex:
        return to_json({"Status": False, "Error": str(ex)})


@post("/request/del")
def del_request():
    try:
        with database.connect() as conn:
            args = (dumps(request.json),)
            conn.execute("select syncocean.del_request(%s)", args)
            return to_json({"Status": True})
    except Exception as ex:
        return to_json({"Status": False, "Error": str(ex)})


@post("/log/list")
def get_log_list():
    try:
        with database.connect() as conn:
            args = (dumps(request.json),)
            cur = conn.execute("select syncocean.get_log_list(%s)", args)
            return to_json({"Status": True, "Payload": cur.fetchone()[0]})
    except Exception as ex:
        return to_json({"Status": False, "Error": str(ex)})


@post("/gateway/<schema>/<function>")
def call_gateway(schema: str, function: str):
    try:
        with database.connect() as conn:
            query = sql.SQL("select {schema}.{function}(%s)").format(
                schema=sql.Identifier(schema), function=sql.Identifier(function))
            args = (dumps(request.json),)
            cur = conn.execute(query, args)
            return to_json({"Status": True, "Payload": cur.fetchone()[0]})
    except Exception as ex:
        return to_json({"Status": False, "Error": str(ex)})


@post("/data/upload/<schema>/<table>")
def upload_data(schema: str, table: str):
    try:
        with database.connect() as conn:
            query = sql.SQL("copy {schema}.{table} from stdin").format(
                schema=sql.Identifier(schema), table=sql.Identifier(table))
            with conn.cursor().copy(query) as copy:
                with request.files.data.file as file:
                    while data := file.read():
                        copy.write(data)
            return to_json({"Status": True})
    except Exception as ex:
        return to_json({"Status": False, "Error": str(ex)})


@post("/data/download/<schema>/<table>")
def download_data(schema: str, table: str):
    try:
        with database.connect() as conn:
            query = sql.SQL("copy {schema}.{table} to stdout").format(
                schema=sql.Identifier(schema), table=sql.Identifier(table))
            buffer = bytearray()
            with conn.cursor().copy(query) as copy:
                for data in copy:
                    buffer.extend(data)
            return to_json({"Status": True, "Payload": buffer.decode()})
    except Exception as ex:
        return to_json({"Status": False, "Error": str(ex)})


run(server="bjoern", host=config.srv_host, port=config.srv_port, debug=True)
