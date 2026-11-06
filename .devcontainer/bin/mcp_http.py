"""Serves the kit's fire-danger tool to Open WebUI (openwebui start, from workshop 4). Not a command.

    python -I -B mcp_http.py --server <kit>/mcp/fire_danger_server.py --port 8000 \
        --allowed-host <name>:8000 --tool fire_danger --tool territories

The same server as in Claude Code and OpenCode (mcp/fire_danger_server.py, loaded as it is: its mcp.run()
only runs as a script), over Streamable HTTP, the only transport of Open WebUI's MCP client (read in 0.12.4), instead
of stdio. It still reads mcp/fire-danger.json at each call.

--data PATH (class mode of openwebui, the Open WebUI guide): the server's code comes from the image, and its data
from the facilitator's mcp/fire-danger.json, mounted elsewhere; the server then reads PATH at each call instead of
the fire-danger.json next to it. Without --data (the workshop kit), nothing changes.

openwebui runs it in a container of its own (the Open WebUI image, which has the mcp package), on a Docker
network with no way out (--internal) shared with Open WebUI only, as a plain user, read-only.
Three locks on top of that:
  - a bearer token (MCP_TOKEN, from the environment, never on the command line): a request without it gets 401;
  - the Host header (DNS rebinding protection of the SDK): only --allowed-host;
  - only the tools named by --tool are served (the others are removed before serving): read-only tools only.
"""
import argparse
import hmac
import importlib.util
import logging
import os
import sys
from pathlib import Path


def bearer_only(app, token):
    """An ASGI app that answers 401 to any HTTP request without "Authorization: Bearer <token>"."""
    expected = f"Bearer {token}".encode()

    async def guarded(scope, receive, send):
        if scope["type"] == "http":
            given = dict(scope.get("headers") or []).get(b"authorization", b"")
            if not hmac.compare_digest(given, expected):
                await send({"type": "http.response.start", "status": 401,
                            "headers": [(b"content-type", b"text/plain"), (b"www-authenticate", b"Bearer")]})
                await send({"type": "http.response.body", "body": b"Unauthorized\n"})
                return
        await app(scope, receive, send)
    return guarded


def load_server(path, data=None):
    spec = importlib.util.spec_from_file_location("fire_danger_server", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)   # runs nothing: mcp.run() is under `if __name__ == "__main__"`
    if data:
        # fire_danger() and territories() read DATA at each call (load(DATA)): replacing it is enough.
        if not hasattr(module, "DATA"):
            sys.exit(f"mcp_http: {path} has no DATA to replace with --data")
        module.DATA = Path(data)
    return module.mcp


async def serve(args, token):
    import uvicorn
    from mcp.server.transport_security import TransportSecuritySettings

    server = load_server(args.server, args.data)
    # The SDK logs each session at INFO; warnings (a refused Host header) stay. No question is logged.
    logging.disable(logging.INFO)
    served = []
    for tool in await server.list_tools():
        if tool.name in args.tool:
            served.append(tool.name)
        else:
            server.remove_tool(tool.name)
    missing = sorted(set(args.tool) - set(served))
    if missing:
        sys.exit(f"mcp_http: no tool {', '.join(missing)} in {args.server}")
    security = TransportSecuritySettings(enable_dns_rebinding_protection=True, allowed_hosts=args.allowed_host,
                                         allowed_origins=[])
    app = server.streamable_http_app(transport_security=security, host=args.host)
    print(f"fire-danger: http://{args.host}:{args.port}/mcp, tools {', '.join(sorted(served))}, "
          f"hosts {', '.join(args.allowed_host)}", flush=True)
    config = uvicorn.Config(bearer_only(app, token), host=args.host, port=args.port, log_level="warning",
                            access_log=False)
    await uvicorn.Server(config).serve()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--server", required=True)
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--allowed-host", action="append", required=True)
    parser.add_argument("--tool", action="append", required=True)
    parser.add_argument("--data", help="the data file to read instead of the fire-danger.json next to --server")
    args = parser.parse_args()
    # The token leaves the environment before the kit's code is loaded.
    token = os.environ.pop("MCP_TOKEN", "")
    if len(token) < 32:
        sys.exit("mcp_http: MCP_TOKEN missing or too short")
    import anyio
    anyio.run(serve, args, token)


if __name__ == "__main__":
    main()
