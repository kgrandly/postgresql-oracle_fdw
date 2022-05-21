import imp
from json import JSONEncoder
from uuid import UUID


class UUIDEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, UUID):
            return obj.hex
        return JSONEncoder.default(self, obj)
