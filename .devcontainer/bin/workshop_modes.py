"""The modes of the workshop, described once for both engines.

`workshop-claude` turns each mode into Claude Code's flags, `workshop-opencode` into an OpenCode
config: what enters the model's context, and which tools it gets, is decided here and only here.
The question behind every line: what enters the model's context, when, and who decides?

    bare  the model alone: no instructions file, no tools, no skills, no MCP
    A     + the instructions (AGENTS.md)
    B     + everything in the context from the start: summaries/ and corpus/text/
    C     instructions + file search + skills (nothing preloaded)
    D     C + live tools through MCP (today's fire danger level; the time)
    E     D + the wiki (wiki/), read first (after wiki-start)
    F     E + the wiki as a knowledge graph (graphify), queried through MCP tools
"""
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Mode:
    name: str
    folder: str           # "kit", or "bare": an empty folder outside the kit (no instructions file found)
    instructions: bool    # AGENTS.md, or the WORKSHOP_AGENTS file
    texts: tuple = ()     # added to the instructions, in this order (keys of TEXTS, or "preload")
    search: bool = False  # read, search and write files of the kit, and use its skills
    servers: tuple = ()   # MCP servers: "kit" (those of .mcp.json), "graphify" (the graph of the wiki)
    needs: tuple = ()     # (file of the kit, message if it is missing)


MODES = {m.name: m for m in (
    Mode("bare", folder="bare", instructions=False),
    Mode("A", folder="kit", instructions=True, texts=("no_tools",)),
    Mode("B", folder="kit", instructions=True, texts=("preload",)),
    Mode("C", folder="kit", instructions=True, texts=("knowledge",), search=True),
    Mode("D", folder="kit", instructions=True, texts=("knowledge",), search=True, servers=("kit",)),
    Mode("E", folder="kit", instructions=True, texts=("wiki", "knowledge"), search=True, servers=("kit",),
         needs=(("wiki/index.md", "No wiki yet. First type: wiki-start"),)),
    Mode("F", folder="kit", instructions=True, texts=("graph", "knowledge"), search=True,
         servers=("kit", "graphify"),
         needs=(("wiki/graphify-out/graph.json", "No graph of the wiki yet. First type: wiki-start"),)),
)}

# The kit's MCP servers (.mcp.json): their tools are allowed without asking. A server someone adds to
# .mcp.json is asked at each call.
KIT_SERVERS = ("fire-danger", "time")
# graphify's tools about pull requests: not about the wiki, never shown.
GRAPHIFY_HIDDEN = ("list_prs", "get_pr_impact", "triage_prs")
# Workshop 4, extension (WORKSHOP_WEATHER=1, modes with the kit's servers): the Open-Meteo server
# (.mcp.weather.json), reduced to two tools; the 15 others are not even shown to the model (their
# descriptions alone are about 100,000 characters).
WEATHER_SHOWN = ("weather_forecast", "geocoding")
WEATHER_HIDDEN = ("weather_archive", "air_quality", "marine_weather", "elevation", "flood_forecast",
                  "dwd_icon_forecast", "gfs_forecast", "meteofrance_forecast", "ecmwf_forecast", "jma_forecast",
                  "metno_forecast", "gem_forecast", "seasonal_forecast", "climate_projection", "ensemble_forecast")

# Modes A and B have no tools, but each engine's own instructions still describe some: an AGENTS.md
# that asks to name a document made the model write fake tool calls as text instead of an answer
# (Haiku, then Sonnet 5.5). The facilitator's choice (2026-10-27): say it plainly.
NO_TOOLS = ("You have no tools in this conversation: you cannot open, search or read any file. Answer from what "
            "you know and from these instructions, and never write tool calls.")
# The test material (expected answers, earlier answers, example prompt) is not a source: the text says
# so, and replay flags any answer where the model saw it.
KNOWLEDGE = ("The reference knowledge is in two folders, each with an index.md catalogue: summaries/ (short summaries "
             "in English of the official documents: start there; their OKF header, up to the second ---, says who verified "
             "them: \"status: draft\" means not yet checked by a person) and corpus/ (the full official documents in "
             "their original language: go there for details or when the summaries are not enough; read and search "
             "their readable copies in corpus/text/, not the original HTML, PDF or Word files). For a question about "
             "the topic, search them before answering, and say which document you used. Never open or search "
             "test-questions.md, scores.md, answers/ or examples/: they are the test material of the workshop, not "
             "sources. ")
# The end of KNOWLEDGE names each engine's own tools (Claude Code searches through its shell; OpenCode
# asks before every shell command, so it searches with its grep, glob and read tools).
HOW_TO_SEARCH = {
    "claude": ("You are already in the kit folder: run your commands from here, without cd. To create or change a "
               "file, use the Write and Edit tools, never shell commands (cat >, sed -i, printf >>): the person "
               "sees exactly what changes before accepting."),
    "opencode": ("You are already in the kit folder: search and read with the grep, glob and read tools, not with "
                 "shell commands (each shell command waits for the person's approval). To create or change a file, "
                 "use the edit and write tools, never shell commands (cat >, sed -i, printf >>): the person sees "
                 "exactly what changes before accepting."),
}
WIKI = ("To answer, first read wiki/index.md, then the relevant pages of wiki/: each fact there has a footnote to its "
        "source. If the wiki is not enough, search the sources. ")
GRAPH = ("The wiki (wiki/) is also available as a knowledge graph, through the graphify tools (query_graph, get_node, "
         "get_neighbors, shortest_path): each node is a concept, an organisation, a rule or a page of the wiki, with "
         "the page it comes from. To answer, first query the graph to find the relevant nodes and pages, then read "
         "only those wiki pages to get the exact facts and their footnotes. If the wiki is not enough, search the "
         "sources. ")
# Mode B: the summaries and the readable copy of every official document (corpus/text/); never the
# originals (HTML, PDF, Word), which are far too big or not text.
PRELOAD_FOLDERS = ("summaries", "corpus/text")
PRELOAD_SKIPPED = ("index.md", "README.md")
PRELOAD_HEADER = ("# Reference knowledge, loaded in full at startup:\n"
                  "# summaries/ (short summaries of the official documents; their header says who verified them) and\n"
                  "# corpus/text/ (readable copies of the full official documents)")


UNKNOWN = "Unknown mode: {typed}. Modes: bare, A, B, C, D, E, F (workshop help)."
BANNER = "Workshop: mode {typed}. To quit: press Ctrl+C twice. Other modes: workshop bare | A | B | C | D | E | F"
# The demo personalities of examples/ (liar, sophist, storyteller) carry this label in their text.
DEMO_LABEL = "Demo bot:"


def banner(typed, agents, copy, engine_line=None):
    """The lines both launchers print before a chat (not with -p). copy: the instructions as sent."""
    print(BANNER.format(typed=typed), file=sys.stderr)
    if engine_line:
        print(engine_line, file=sys.stderr)
    if agents is not None:
        print(f"Instructions: {agents} (a copy; AGENTS.md is not used)", file=sys.stderr)
        if DEMO_LABEL in copy.read_text(encoding="utf-8", errors="replace"):
            print("This demo bot makes deliberate errors.", file=sys.stderr)


def mode_of(typed):
    """The mode for what was typed (any case), or None."""
    return {name.lower(): mode for name, mode in MODES.items()}.get((typed or "").lower())


def missing(mode, kit):
    """The message of the first file the mode needs and the kit lacks, or None."""
    if mode.folder == "kit" and not kit.is_dir():
        return f"No workshop kit in {kit}: open the workshop's Codespace, or set WORKSHOP_HOME."
    for rel, message in mode.needs:
        if not (kit / rel).is_file():
            return message
    return None


def weather_problem(mode):
    """WORKSHOP_WEATHER=1: None if this mode can have the weather server, else the message."""
    if os.environ.get("WORKSHOP_WEATHER") == "1" and "kit" not in mode.servers:
        return "WORKSHOP_WEATHER=1 works with modes D, E and F only."
    return None


def weather_wanted(mode):
    return os.environ.get("WORKSHOP_WEATHER") == "1" and "kit" in mode.servers


def agents_file(mode, kit):
    """(the WORKSHOP_AGENTS file, or None for AGENTS.md, error message or None). Mode bare has no
    instructions at all: a note is printed and the file ignored."""
    wanted = os.environ.get("WORKSHOP_AGENTS")
    if not wanted:
        return None, None
    if not mode.instructions:
        print("Mode bare has no instructions at all: WORKSHOP_AGENTS is ignored.", file=sys.stderr)
        return None, None
    agents = Path(wanted)
    # A relative path: from here, or else from the kit (examples/AGENTS.liar.md).
    if not agents.is_absolute() and not agents.is_file() and (kit / agents).is_file():
        agents = kit / agents
    if not agents.is_file():
        return None, (f"Instructions file not found: {wanted}\n"
                      "Give the path of a file, for example: examples/AGENTS.feurisson.md")
    return agents, None


def agents_name(agents):
    """Name of a run folder for these instructions: AGENTS.liar.md -> liar, My bot.md -> my-bot."""
    name = agents.name.removesuffix(".md").removeprefix("AGENTS.")
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def preload(kit):
    """Mode B: the no-tools line, then every summary and every readable copy, each under its name."""
    body = f"{NO_TOOLS}\n\n{PRELOAD_HEADER}\n"
    for folder in PRELOAD_FOLDERS:
        for f in sorted((kit / folder).glob("*.md")):
            # Not hidden files (an editor's lock or backup), as the shell's *.md; a badly encoded file
            # is sent with its odd characters replaced, never refused.
            if f.name in PRELOAD_SKIPPED or f.name.startswith(("00-", ".")) or not f.is_file():
                continue
            body += f"\n\n## Document: {f.relative_to(kit)}\n\n" + f.read_text(encoding="utf-8", errors="replace")
    return body


def added_text(mode, engine):
    """The text added to the instructions in this mode (not mode B: see preload), or ""."""
    parts = {"no_tools": NO_TOOLS, "wiki": WIKI, "graph": GRAPH,
             "knowledge": KNOWLEDGE + HOW_TO_SEARCH[engine]}
    return "".join(parts[t] for t in mode.texts if t != "preload")
