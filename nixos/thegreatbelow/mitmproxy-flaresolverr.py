import json
import os
import urllib.request
import uuid

from mitmproxy import http
from mitmproxy import addonmanager


class Flaresolverr:
    def __init__(self) -> None:
        host = os.getenv("FLARESOLVERR_HOST", "127.0.0.1")
        port = int(os.getenv("FLARESOLVERR_PORT", "8191"))
        self.url = f"http://{host}:{port}/v1"

    def _post_json(self, data):
        r = urllib.request.Request(self.url)
        r.add_header("Content-Type", "application/json; charset=utf-8")
        return urllib.request.urlopen(r, json.dumps(data).encode("utf-8"))

    def load(self, loader: addonmanager.Loader) -> None:
        self.session = str(uuid.uuid1())
        self._post_json(
            {
                "cmd": "sessions.create",
                "session": self.session,
            }
        )

    async def done(self):
        self._post_json(
            {
                "cmd": "sessions.destroy",
                "session": self.session,
            }
        )

    async def request(self, flow: http.HTTPFlow) -> None:
        body: dict[str, str] = {
            "url": flow.request.url,
            "cmd": f"request.{flow.request.method.lower()}",
        }
        if flow.request.method == "POST" and flow.request.text:
            body["postData"] = flow.request.text

        flow.request = http.Request.make(
            "POST",
            self.url,
            json.dumps(body),
            {"Content-Type": "application/json"},
        )

    async def response(self, flow: http.HTTPFlow) -> None:
        if flow.response and flow.response.status_code == 200:
            data = flow.response.json()["solution"]
            flow.response = http.Response.make(
                data["status"],
                data["response"],
                data["headers"],
            )


addons = [Flaresolverr()]
