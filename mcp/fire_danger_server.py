"""Example MCP server for the workshop: "live" knowledge.

It gives the model two tools:
  - territories()           : the territories for which a fire danger level is available
  - fire_danger(territory)  : today's fire danger level for one territory, with its source and advice

The teaching point: the model cannot know today's level. Edit fire-danger.json during the
conversation and ask again: the answer follows, without restarting Claude Code.

Transport: stdio (Claude Code starts this script itself, see .mcp.json).
Dependency: the `mcp` package >= 2 (installed in /opt/workshop/venv by the server script).
"""

import json
from pathlib import Path

from mcp.server.mcpserver import MCPServer

DATA = Path(__file__).with_name("fire-danger.json")

mcp = MCPServer("fire-danger")


def load():
    return json.loads(DATA.read_text(encoding="utf-8"))


@mcp.tool()
def territories() -> str:
    """List the territories for which today's fire danger level is available."""
    try:
        data = load()
    except (FileNotFoundError, json.JSONDecodeError) as e:
        return f"fire-danger.json cannot be read ({e}). The facilitator must fix it."
    return "\n".join(data.get("territories", {})) or "No territory yet."


@mcp.tool()
def fire_danger(territory: str) -> str:
    """Today's wildfire danger level for a territory, with its official source and advice.
    Call it for any question about the current situation, today's level or the rules in force."""
    try:
        data = load()
    except FileNotFoundError:
        return "fire-danger.json not found: the facilitator must fill it in."
    except json.JSONDecodeError as e:
        return f"fire-danger.json is malformed ({e}). Fix it and try again."
    all_territories = data.get("territories", {})
    matches = {k: v for k, v in all_territories.items() if territory.lower() in k.lower()}
    if not matches:
        return f"No data for '{territory}'. Available territories: " + ", ".join(all_territories)
    return json.dumps({"date": data.get("date"), **matches}, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    mcp.run()
