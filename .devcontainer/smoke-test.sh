#!/usr/bin/env bash
# Smoke-test du Codespace : prouve qu'un binôme peut travailler dans le conteneur tel qu'il est
# distribué. Lancé par le workflow devcontainer-publish (avant toute publication) et, à la main :
#   devcontainer exec --workspace-folder . .devcontainer/smoke-test.sh
# Il utilise une fausse clé : aucun appel payant, mais il faut le réseau.
set -euo pipefail

etape() { printf '\n→ %s\n' "$1"; }
echec() { printf '✗ %s\n' "$1" >&2; exit 1; }
KIT="${WORKSHOP_HOME:?WORKSHOP_HOME absent : remoteEnv du devcontainer.json}"

etape "Utilisateur vscode"
[[ "$(id -un)" == vscode ]] || echec "utilisateur courant : $(id -un)"

etape "Claude Code à la version figée"
attendu="$(cat "$KIT/.devcontainer/claude-version")"
claude --version
[[ "$(claude --version)" == "$attendu "* ]] || echec "version attendue : $attendu"

etape "Commandes de l'atelier"
for c in workshop workshop-claude workshop-opencode replay workshop-login corpus-add wiki-start wiki-graph wiki-explore chatbot-export openwebui score workshop-save workshop-start workshop-key; do command -v "$c" || echec "$c absent"; done

etape "zsh et oh-my-zsh pour vscode (shell par défaut des terminaux, réglage dans les métadonnées de l'image)"
command -v zsh || echec "zsh absent"
[[ -d "$HOME/.oh-my-zsh" && -f "$HOME/.zshrc" ]] || echec "oh-my-zsh absent pour $(id -un)"
h=$(mktemp -d); touch "$h/.zshrc"
sortie=$(env -u WORKSHOP_WELCOME HOME="$h" ZDOTDIR="$h" zsh -ic true 2>/dev/null)
[[ "$sortie" == *"Welcome! First, save your API key: workshop-login"* ]] || echec "accueil absent sous zsh : $sortie"
rm -rf "$h"

etape "Message d'accueil des terminaux : neutre par défaut, ou celui du dépôt (WORKSHOP_WELCOME)"
h=$(mktemp -d)
sortie=$(env -u WORKSHOP_WELCOME HOME="$h" bash -ic true 2>/dev/null)
[[ "$sortie" == *"Welcome! First, save your API key: workshop-login"* ]] || echec "accueil par défaut absent : $sortie"
[[ "$sortie" != *pair* ]] || echec "l'accueil parle encore de binôme"
touch "$h/.workshop-key"
[[ -z "$(env -u WORKSHOP_WELCOME HOME="$h" bash -ic true 2>/dev/null)" ]] || echec "accueil affiché alors que la clé est enregistrée"
sortie=$(WORKSHOP_WELCOME="Welcome! Start the chatbot of this guide with: chatbot" HOME="$h" bash -ic true 2>/dev/null)
[[ "$sortie" == "Welcome! Start the chatbot of this guide with: chatbot" ]] || echec "WORKSHOP_WELCOME ignoré : $sortie"
[[ -z "$(WORKSHOP_WELCOME= HOME="$h" bash -ic true 2>/dev/null)" ]] || echec "WORKSHOP_WELCOME vide n'efface pas l'accueil"
rm -rf "$h"

etape "Serveur MCP importable avec l'environnement de l'image"
(cd "$KIT/mcp" && /opt/workshop/venv/bin/python -c "import fire_danger_server as s; print(s.territories().splitlines()[0])") \
  || echec "le serveur MCP ne s'importe pas"
# Repli d'hiver : aucun niveau tant que le fichier n'est pas daté du jour et « live » ; jour enregistré
# (recorded_example) seulement avec FIRE_DANGER_RECORDED=1 ; pas d'indice EFFIS dans les données.
(cd "$KIT/mcp" && /opt/workshop/venv/bin/python - <<'PY') || echec "serveur MCP : repli d'hiver"
import asyncio, json
import fire_danger_server as s
r = json.loads(s.fire_danger("Antwerp"))
# The key of the territory ("Antwerp - Flanders, Belgium"), whatever its separator.
ANTWERP = next(k for k in r if k.startswith("Antwerp"))
entry = r[ANTWERP]
assert entry["level"] is None and "why_no_level" in entry, entry
assert not any("TO BE COMPLETED" in json.dumps(v) for v in entry.values()), entry
assert [t.name for t in asyncio.run(s.mcp.list_tools())] == ["territories", "fire_danger"]
# Daté du jour et « live », mais niveau encore « TO BE COMPLETED » : toujours pas de niveau.
data = json.load(open("fire-danger.json", encoding="utf-8"))
data["date"] = s.today()
data["territories"][ANTWERP]["status"] = "live"
s.load = lambda path: data
entry = json.loads(s.fire_danger("Antwerp"))[ANTWERP]
assert entry["level"] is None and entry["status"] == "live", entry
data["territories"][ANTWERP]["level"] = "groen"
assert json.loads(s.fire_danger("Antwerp"))[ANTWERP]["level"] == "groen"
assert "EFFIS" not in open("fire-danger.json", encoding="utf-8").read()
print("fire_danger : pas de niveau sans date du jour ni statut live ; recorded_example coupé")
PY
# Serveur Time (atelier 4) : installé dans son environnement, deux outils, sans réseau.
/opt/workshop/venv/bin/python - <<'PY' || echec "serveur MCP time"
import asyncio
from mcp import ClientSession
from mcp.client.stdio import stdio_client, StdioServerParameters
async def main():
    params = StdioServerParameters(command="/opt/workshop/mcp-time/bin/mcp-server-time",
                                   args=["--local-timezone", "Europe/Paris"])
    async with stdio_client(params) as (r, w), ClientSession(r, w) as s:
        await s.initialize()
        names = sorted(t.name for t in (await s.list_tools()).tools)
        assert names == ["convert_time", "get_current_time"], names
        print("time :", names)
asyncio.run(main())
PY
(cd "$KIT/mcp" && FIRE_DANGER_RECORDED=1 /opt/workshop/venv/bin/python -c "import asyncio, fire_danger_server as s; \
assert 'recorded_example' in [t.name for t in asyncio.run(s.mcp.list_tools())]") || echec "FIRE_DANGER_RECORDED=1 : recorded_example absent"

etape "OpenCode à la version figée (second moteur)"
attendu="$(cat "$KIT/.devcontainer/opencode-version")"
opencode --version
[[ "$(opencode --version)" == "opencode v$attendu" ]] || echec "OpenCode : version attendue $attendu"
command -v workshop-opencode || echec "workshop-opencode absent"

etape "ripgrep à la version figée, et les bibliothèques des commandes (importées, pas des commandes)"
attendu="$(cat "$KIT/.devcontainer/ripgrep-version")"
rg --version | head -1
[[ "$(rg --version | head -1)" == "ripgrep $attendu "* ]] || echec "ripgrep : version attendue $attendu"
for f in workshop_modes.py workshop_provider.py mcp_http.py; do
  [[ -r "$(dirname "$(realpath "$(command -v workshop-login)")")/$f" ]] || echec "$f absent à côté des commandes"
done

etape "Mod token-weather présent"
[[ -d /opt/workshop/claude-code-playground/claude-code/mods/token-weather ]] || echec "mod absent"

etape "Sans clé, workshop le dit (et son aide s'affiche quand même)"
rm -f "$HOME/.workshop-key" "$HOME/.claude/settings.json"
if workshop bare -p hi 2>/tmp/err; then echec "workshop a démarré sans clé"; fi
grep -q workshop-login /tmp/err || echec "message attendu : workshop-login"
for a in help -h --help; do
  sortie="$(workshop "$a")"; grep -q "Starts the workshop chatbot" <<< "$sortie" || echec "workshop $a : aide attendue"
done

etape "Une clé mal formée est refusée sans rien écrire"
if printf '%s\n' "not-a-key" | workshop-login --key - 2>/dev/null; then echec "clé mal formée acceptée"; fi
[[ ! -f "$HOME/.workshop-key" ]] || echec "clé mal formée enregistrée"
for a in "--key sk-ant-api03-SMOKETEST0000000000" sk-ant-api03-SMOKETEST0000000000 --key=sk-ant-api03-SMOKETEST0000000000 \
         "--engine sk-ant-api03-SMOKETEST0000000000" "--model sk-or-v1-SMOKETEST0000000000"; do
  # shellcheck disable=SC2086
  if workshop-login $a 2>/tmp/err; then echec "clé sur la ligne acceptée ($a)"; fi
  grep -q "Type workshop-login alone" /tmp/err || { cat /tmp/err; echec "clé sur la ligne : message attendu"; }
  if grep -q SMOKETEST /tmp/err; then echec "clé affichée par workshop-login"; fi
done
[[ ! -f "$HOME/.workshop-key" ]] || echec "clé sur la ligne enregistrée"

etape "Une clé OpenRouter est refusée avec --engine claude (Claude Code : Anthropic seulement)"
code=0; printf '%s\n' sk-or-v1-SMOKETEST0000000000 | workshop-login --engine claude --key - 2>/tmp/err || code=$?
[[ "$code" == 1 ]] || echec "clé OpenRouter avec --engine claude : code attendu 1, obtenu $code"
grep -q -- "type workshop-login without --engine claude" /tmp/err || echec "clé OpenRouter : message vers OpenCode attendu"
[[ ! -f "$HOME/.workshop-key" ]] || echec "clé OpenRouter enregistrée avec Claude Code"
printf '{"env":{"ANTHROPIC_AUTH_TOKEN":"x"}}' > "$HOME/.claude/settings.json" 2>/dev/null || { mkdir -p "$HOME/.claude"; printf '{"env":{"ANTHROPIC_AUTH_TOKEN":"x"}}' > "$HOME/.claude/settings.json"; }
if workshop bare -p hi 2>/tmp/err; then echec "workshop a démarré avec un ancien réglage OpenRouter"; fi
rm -f "$HOME/.claude/settings.json"

etape "corpus-add : une page web et un PDF s'importent, un PDF scanné est refusé (sur une copie du kit)"
copie="$(mktemp -d)"; cp -r "$KIT/." "$copie"; rm -rf "$copie/.git"
[[ ! -e "$copie/wiki" ]] || echec "wiki/ présent avant wiki-start"
WORKSHOP_HOME="$copie" corpus-add "$copie/corpus/50-catalunya-pla-alfa.html" --name test-page --language ca > /dev/null \
  || echec "corpus-add : la page web n'a pas été importée"
WORKSHOP_HOME="$copie" corpus-add "$copie/inbox/benevento-campagna-aib-2026.pdf" --name test-pdf > /dev/null \
  || echec "corpus-add : le PDF n'a pas été importé"
[[ -f "$copie/corpus/80-test-page.html" && -s "$copie/corpus/text/80-test-page.md" && -s "$copie/corpus/text/81-test-pdf.md" ]] \
  || echec "corpus-add : original ou copie lisible manquant"
grep -q "80-test-page" "$copie/corpus/index.md" || echec "corpus-add : corpus/index.md non mis à jour"
code=0; WORKSHOP_HOME="$copie" corpus-add "$copie/corpus/30-charente-maritime-arrete-26EB142.pdf" --name scanne > /dev/null 2>&1 || code=$?
[[ "$code" == 3 ]] || echec "corpus-add : un PDF scanné aurait dû être refusé (code 3), obtenu $code"
echo "corpus-add : OK"

etape "wiki-start : le wiki et ses skills arrivent dans la copie, une seule fois"
WORKSHOP_HOME="$copie" wiki-start || echec "wiki-start a échoué"
[[ -f "$copie/wiki/index.md" && -f "$copie/.claude/skills/ingest/SKILL.md" && -f "$copie/.claude/skills/lint/SKILL.md" ]] \
  || echec "wiki-start : wiki/ ou skills manquants"
WORKSHOP_HOME="$copie" wiki-start | grep -q "already there" || echec "wiki-start rejoué : message attendu"
[[ -f "$copie/wiki/AGENTS.md" ]] && grep -qx '@AGENTS.md' "$copie/wiki/CLAUDE.md" \
  || echec "wiki : schéma wiki/AGENTS.md et import wiki/CLAUDE.md attendus (lus par les deux moteurs)"

etape "wiki-explore : le graphe de graphify se lit sans modèle, sans installer de skill"
[[ -f "$copie/wiki/graphify-out/graph.html" && -f "$copie/wiki/graphify-out/GRAPH_REPORT.md" ]] \
  || echec "wiki-start : graphe de graphify absent"
WORKSHOP_HOME="$copie" wiki-explore path "Montoro protection strips" "Obligations légales de débroussaillement" \
  | grep -q "Shortest path" || echec "wiki-explore path"
WORKSHOP_HOME="$copie" wiki-explore explain pla_alfa_catalonia | grep -q "Connections" || echec "wiki-explore explain"
WORKSHOP_HOME="$copie" WORKSHOP_GRAPH_PORT=8799 wiki-explore > /dev/null || echec "wiki-explore : carte non lancée"
[[ "$(curl -s -o /dev/null -w '%{redirect_url}' http://127.0.0.1:8799/)" == */graph.html ]] \
  || echec "wiki-explore : la racine du port ne mène pas à la carte"
curl -sf -o /dev/null http://127.0.0.1:8799/graph.html || echec "wiki-explore : carte non servie"
WORKSHOP_HOME="$copie" WORKSHOP_GRAPH_PORT=8799 wiki-explore stop | grep -q closed || echec "wiki-explore stop"
# Un numéro resté dans le fichier PID (Codespace repris) ne tue pas un autre programme.
sleep 300 & p=$!; mkdir -p "$HOME/.workshop-run"; echo "$p" > "$HOME/.workshop-run/wiki-explore-8799.pid"
WORKSHOP_HOME="$copie" WORKSHOP_GRAPH_PORT=8799 wiki-explore stop > /dev/null
kill -0 "$p" 2>/dev/null || echec "wiki-explore stop : un autre programme a été arrêté"
kill "$p"
[[ ! -e "$HOME/.claude/skills/graphify" ]] || echec "graphify a installé sa skill dans ~/.claude (fausse les modes)"
echo "wiki-explore : OK"

etape "chatbot-export : le paquet du chatbot (instructions + connaissances)"
cp "$copie/examples/AGENTS.feurisson.md" "$copie/AGENTS.md"
# Une skill du binôme (atelier 3) part dans le paquet ; celles du kit (curation, wiki) non : elles écrivent des fichiers.
mkdir -p "$copie/.claude/skills/rumour-check"
printf -- '---\nname: rumour-check\ndescription: Checks a rumour.\n---\n\n# Checking a rumour\n' > "$copie/.claude/skills/rumour-check/SKILL.md"
avant="$(cd "$copie/wiki" && sha256sum ./*.md)"
WORKSHOP_HOME="$copie" chatbot-export --name "Smoke test" > /tmp/out || echec "chatbot-export"
grep -q "1 skill (rumour-check)" /tmp/out && grep -q "Not in the file: the kit's skills" /tmp/out || { cat /tmp/out; echec "chatbot-export : skills"; }
grep -q "wiki pages + their map" /tmp/out && grep -q "links between wiki pages name their files" /tmp/out \
  || { cat /tmp/out; echec "chatbot-export : carte du wiki et liens réécrits annoncés"; }
[[ "$(cd "$copie/wiki" && sha256sum ./*.md)" == "$avant" ]] || echec "chatbot-export : wiki/ modifié sur le disque"
rm -rf "$copie/.claude/skills/rumour-check"
/opt/workshop/venv/bin/python -c "
import re, sys, zipfile
z = zipfile.ZipFile(sys.argv[1]); n = z.namelist()
assert 'instructions.md' in n and 'README.md' in n, n[:5]
skills = sorted(x for x in n if x.startswith('skills/'))
assert skills == ['skills/rumour-check/SKILL.md'], skills
assert '<!--' not in z.read('instructions.md').decode(), 'commentaires dans les instructions'
for p in ('summaries__', 'wiki__', 'corpus-text__'):
    assert any(x.startswith('knowledge/' + p) for x in n), p
# Ni catalogues ni fichiers du wiki qui ne sont pas des connaissances (comme workshop B et openwebui) ; seule la
# carte du wiki vient, sous le nom wiki__index.md (atelier 5).
bad = [x for x in n if x.startswith('knowledge/') and x != 'knowledge/wiki__index.md' and x.split('__', 1)[1] in
       ('index.md', 'README.md', 'log.md', 'CLAUDE.md', 'AGENTS.md', 'graph.md') or '__00-' in x]
assert not bad, bad
carte = z.read('knowledge/wiki__index.md').decode()
assert '<!--' not in carte and '](file.md)' not in carte, 'commentaire de la carte gardé'
# Chaque lien entre pages du wiki porte le nom d'un fichier du paquet (Open WebUI ouvre un fichier par son nom trouvé).
noms = {x.split('/', 1)[1] for x in n if x.startswith('knowledge/')}
liens = [(x, c) for x in n if x.startswith('knowledge/wiki__')
         for c in re.findall(r'\]\(([^)\s#]+\.md)(?:#[^)]*)?\)', z.read(x).decode())]
assert liens and all(c in noms for _, c in liens), [l for l in liens if l[1] not in noms][:5]
assert 'Not in the file: the live tool of workshop 4' in z.read('README.md').decode(), 'README : outil MCP'
print(len(n), 'fichiers dans le paquet,', len(liens), 'liens du wiki, tous vers un fichier du paquet')
" "$copie/smoke-test.zip" || echec "chatbot-export : paquet incomplet"

etape "openwebui : Docker fonctionne dans le conteneur, la commande demande la clé d'abord"
# Pas de téléchargement d'Open WebUI ici (1,6 Go à télécharger) : le démarrage réel est vérifié à la main
# dans un Codespace (facilitator/SETUP.md).
docker info > /dev/null || echec "Docker ne répond pas (fonctionnalité docker-in-docker)"
openwebui help | grep -q "openwebui start" || echec "openwebui help"
code=0; openwebui start > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "workshop-login" /tmp/err || { cat /tmp/err; echec "openwebui sans clé : message attendu workshop-login"; }
# Atelier 2 : bases de deux tailles et query --size/--top-k (refus clairs sans clé et sur une taille inconnue).
openwebui help | grep -q "openwebui sizes" || echec "openwebui help : sizes"
code=0; openwebui sizes > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "workshop-login" /tmp/err || { cat /tmp/err; echec "openwebui sizes sans clé : message attendu workshop-login"; }
code=0; openwebui query --size 700 "x" > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "The sizes are 1000, 2000" /tmp/err || { cat /tmp/err; echec "openwebui query --size inconnue : refus attendu"; }
code=0; openwebui top-k abc > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "Usage: openwebui top-k N" /tmp/err || { cat /tmp/err; echec "openwebui top-k invalide : refus attendu"; }
# Le chatbot du binôme, en RAG (atelier 2) : --rag dans l'aide et dans le message d'usage ; sans clé, workshop-login.
openwebui help | grep -q -- "--rag" || echec "openwebui help : chatbot --rag"
code=0; openwebui chatbot --name > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "\[--rag\]" /tmp/err || { cat /tmp/err; echec "openwebui chatbot --name sans nom : usage attendu"; }
code=0; openwebui chatbot --name "Smoke test" --rag > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "workshop-login" /tmp/err || { cat /tmp/err; echec "openwebui chatbot --rag sans clé : message attendu workshop-login"; }
# Le partage demande des comptes : refusé dans l'instance de l'atelier (sans comptes).
code=0; openwebui share open > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "Never make its port public" /tmp/err || { cat /tmp/err; echec "openwebui share hors mode classe : refus attendu"; }
OPENWEBUI_MODE=class openwebui help | grep -q "share open" || echec "openwebui help (mode classe)"
OPENWEBUI_MODE=class openwebui help | grep -q "openwebui import FILE" || echec "openwebui help (mode classe) : export et import"
command -v qrencode > /dev/null || echec "qrencode absent (QR code de share open)"

etape "openwebui, atelier 4 : l'outil fire-danger (lecture seule, jeton) et la carte du wiki, sans Docker"
# Le démarrage réel (conteneurs, réseau interne) est essayé à part : facilitator/openwebui-prototypes/next-image/.
WORKSHOP_HOME="$copie" /opt/workshop/venv/bin/python -I - "$(command -v openwebui)" <<'PY' || echec "openwebui : outil MCP ou carte du wiki"
import contextlib, importlib.machinery, importlib.util, io, json, os, pathlib, sys
l = importlib.machinery.SourceFileLoader("owui", sys.argv[1]); m = importlib.util.module_from_spec(importlib.util.spec_from_loader("owui", l)); l.exec_module(m)
assert m.mcp_wanted(), "le kit a mcp/ et .mcp.json : l'outil est attendu"
c = m.mcp_connection("T" * 43)[0]
assert c["type"] == "mcp" and c["auth_type"] == "bearer" and c["key"] == "T" * 43 and c["url"].startswith("http://"), c
# Noms entiers (le filtre d'Open WebUI compare la fin du nom) ; jamais recorded_example, time ni Open-Meteo.
assert c["config"]["function_name_filter_list"] == "fire_danger,territories", c["config"]
assert m.mcp_token_of({"TOOL_SERVER_CONNECTIONS": json.dumps([c])}) == "T" * 43 and m.mcp_token_of({}) == ""
assert m.MCP_HELPER.is_file(), m.MCP_HELPER
m.CLASS = True; assert not m.mcp_wanted(), "jamais en mode classe"; m.CLASS = False
# Le chatbot natif reçoit l'outil, pas le chatbot RAG ; la phrase de la carte du wiki seulement avec la carte.
f = m.chatbot_forms("Smoke", "I", {"id": "k", "name": "K"}, [], m.PROVIDERS[0], "claude-sonnet-5-5", wiki=True,
                    tool_ids=[m.MCP_TOOL_ID])
natif, rag = f["chatbot-smoke"], f["chatbot-smoke--rag"]
assert natif["meta"]["toolIds"] == ["server:mcp:fire-danger"] and "toolIds" not in rag["meta"], (natif["meta"], rag["meta"])
assert "wiki__index.md, its map" in natif["params"]["system"] and "wiki__index.md" not in rag["params"]["system"]
f = m.chatbot_forms("Smoke", "I", {"id": "k", "name": "K"}, [], m.PROVIDERS[0], "claude-sonnet-5-5")
assert "toolIds" not in f["chatbot-smoke"]["meta"] and "wiki__index.md" not in f["chatbot-smoke"]["params"]["system"]
# Open WebUI lancé avant l'atelier 4 (sans l'outil) : openwebui chatbot demande openwebui start d'abord.
class Conteneur:
    returncode = 0
    stdout = json.dumps(["OPENAI_API_KEY=sk-ant-x", "OPENAI_API_CONFIGS=" + json.dumps({"0": {"model_ids": ["m"]}})]
                        + [f"{k}={v}" for k, v in m.HARDENED.items()])
m.docker = lambda *a, **k: Conteneur
err = io.StringIO()
try:
    with contextlib.redirect_stderr(err):
        m.check_same_key("sk-ant-x", "m")
    raise AssertionError("sans l'outil, check_same_key doit s'arrêter")
except SystemExit:
    assert "without the live tool of this workshop" in err.getvalue(), err.getvalue()
Conteneur.stdout = json.dumps(json.loads(Conteneur.stdout) + ["TOOL_SERVER_CONNECTIONS=" + json.dumps([c])])
m.check_same_key("sk-ant-x", "m")
print("openwebui : outil fire-danger (2 noms entiers, jeton), chatbot natif seulement, carte du wiki : OK")
PY
# Le serveur de l'outil (mcp_http.py, le même fire_danger_server.py) : jeton exigé, Host vérifié, deux outils seulement,
# même avec FIRE_DANGER_RECORDED=1 (recorded_example retiré par le serveur lui-même).
port=18199
MCP_TOKEN="$(/opt/workshop/venv/bin/python -I -c 'import secrets; print(secrets.token_urlsafe(32))')"
export MCP_TOKEN
FIRE_DANGER_RECORDED=1 /opt/workshop/venv/bin/python -I -B "$(dirname "$(command -v openwebui)")/mcp_http.py" \
  --server "$copie/mcp/fire_danger_server.py" --host 127.0.0.1 --port $port --allowed-host "127.0.0.1:$port" \
  --tool fire_danger --tool territories > /tmp/mcp-http.log 2>&1 &
serveur=$!
/opt/workshop/venv/bin/python -I - "$port" <<'PY' || { cat /tmp/mcp-http.log; echec "mcp_http.py : jeton, Host ou outils"; }
import json, os, sys, time, urllib.error, urllib.request
url, token = f"http://127.0.0.1:{sys.argv[1]}/mcp", os.environ["MCP_TOKEN"]
def post(body, headers):
    h = {"Content-Type": "application/json", "Accept": "application/json, text/event-stream", **headers}
    try:
        with urllib.request.urlopen(urllib.request.Request(url, json.dumps(body).encode(), h), timeout=5) as r:
            return r.status, dict(r.headers), r.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers), ""
init = {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18",
        "capabilities": {}, "clientInfo": {"name": "smoke", "version": "1"}}}
for _ in range(40):
    try:
        status = post(init, {})[0]
        break
    except (urllib.error.URLError, ConnectionError):
        time.sleep(0.5)
assert status == 401, f"sans jeton : {status}"
assert post(init, {"Authorization": "Bearer " + "x" * 43})[0] == 401, "mauvais jeton accepté"
assert post(init, {"Authorization": "Bearer " + token, "Host": "evil.example"})[0] == 421, "Host forgé accepté"
status, headers, _ = post(init, {"Authorization": "Bearer " + token})
assert status == 200, status
h = {"Authorization": "Bearer " + token, "mcp-session-id": headers.get("mcp-session-id", ""),
     "mcp-protocol-version": "2025-06-18"}
post({"jsonrpc": "2.0", "method": "notifications/initialized"}, h)
_, _, body = post({"jsonrpc": "2.0", "id": 2, "method": "tools/list"}, h)
tools = sorted(t["name"] for t in json.loads(body.split("data: ", 1)[1].splitlines()[0])["result"]["tools"])
assert tools == ["fire_danger", "territories"], tools
_, _, body = post({"jsonrpc": "2.0", "id": 3, "method": "tools/call",
                   "params": {"name": "fire_danger", "arguments": {"territory": "La Rochelle"}}}, h)
assert "why_no_level" in body, body[:300]   # fire-danger.json du kit : pas daté du jour
print("mcp_http.py : 401 sans jeton, 421 Host forgé, outils", tools, ", why_no_level rendu")
PY
kill "$serveur"; wait "$serveur" 2>/dev/null || true
unset MCP_TOKEN
grep -q "Rochelle" /tmp/mcp-http.log && echec "mcp_http.py : la question est dans le journal du serveur"

etape "replay RAG sans Open WebUI : un message clair, aucun fichier de réponses"
# answers/ peut ne pas exister encore : sous pipefail, l'échec de ls arrêterait le script.
compte_reponses() { { ls "$KIT/answers" 2>/dev/null || true; } | wc -l; }
avant=$(compte_reponses)
code=0; WORKSHOP_OPENWEBUI_PORT=3999 replay RAG 2 >/tmp/out 2>&1 || code=$?
[[ "$code" == 1 ]] || echec "replay RAG sans Open WebUI : code attendu 1, obtenu $code"
grep -q "openwebui start" /tmp/out || echec "replay RAG sans Open WebUI : il doit dire de taper openwebui start"
[[ "$(compte_reponses)" == "$avant" ]] || echec "replay RAG a laissé un fichier de réponses"
code=0; replay RAG --agents examples/AGENTS.liar.md 2 >/tmp/out 2>&1 || code=$?
[[ "$code" == 1 ]] && grep -q "own instructions" /tmp/out || echec "replay RAG --agents doit être refusé"

etape "replay avec OpenCode : le serveur privé se prépare (sans appel)"
/opt/workshop/venv/bin/python -I -c "
import importlib.machinery as m, shutil, os
r = m.SourceFileLoader('replay', '$(command -v replay)').load_module()
o = r.OpenCode('C', None)
assert 'tmp' in vars(o) and 'env' in vars(o), 'OpenCode de replay incomplet'
assert o.env.get('WORKSHOP_ENGINE') == 'opencode' and o.engine_line().startswith('Engine: OpenCode')
shutil.rmtree(o.tmp)
print('OpenCode de replay : OK')" || echec "replay ne prépare plus son serveur OpenCode"

etape "Fausse clé Anthropic : enregistrée, testée, refusée"
code=0; printf '%s\n' sk-ant-api03-SMOKETEST0000000000 | workshop-login --key - || code=$?
[[ "$code" == 2 ]] || echec "code attendu 2 (clé refusée), obtenu $code"
for v in CLAUDE_CODE_DISABLE_1M_CONTEXT CLAUDE_CODE_DISABLE_FAST_MODE; do
  grep -q "\"$v\": \"1\"" "$HOME/.claude/settings.json" || echec "settings.json : $v absent (jauge sur 1M ou mode rapide)"
done

etape "La clé est à root, en 0400 : workshop-key et apiKeyHelper la lisent, ce compte non"
CLE=sk-ant-api03-SMOKETEST0000000000
sudo -n true 2>/dev/null || echec "pas de sudo sans mot de passe : la clé resterait lisible par le modèle"
[[ "$(stat -c '%U %a' "$HOME/.workshop-key")" == "root 400" ]] || echec "clé : $(stat -c '%U %a' "$HOME/.workshop-key"), root 400 attendu"
[[ "$(workshop-key status)" == locked ]] || echec "workshop-key status : locked attendu"
if cat "$HOME/.workshop-key" > /dev/null 2>&1; then echec "clé lisible sans sudo"; fi
[[ "$(workshop-key read)" == "$CLE" ]] || echec "workshop-key read"
code=0; script -qec "workshop-key read" /dev/null > /tmp/out 2>&1 || code=$?
{ [[ $code != 0 ]] && ! grep -q SMOKETEST /tmp/out; } || echec "workshop-key read a écrit la clé dans un terminal"
grep -qF "\"apiKeyHelper\": \"sudo -n cat $HOME/.workshop-key 2>/dev/null\"" "$HOME/.claude/settings.json" || echec "apiKeyHelper : sudo attendu"
[[ "$(sh -c "$(workshop-key helper)")" == "$CLE" ]] || echec "apiKeyHelper ne rend pas la clé"
[[ -z "$(find "$HOME" -maxdepth 1 -name '.workshop-key?*')" ]] || echec "fichier temporaire de clé laissé"
/opt/workshop/venv/bin/python -I -c "
import sys; sys.path.insert(0, '$(dirname "$(realpath "$(command -v workshop-login)")")')
import workshop_provider as p
assert p.read_key() == '$CLE', 'read_key'" || echec "workshop_provider.read_key : la clé à root n'est pas relue"
# Entrée seule : la clé gardée, toujours à root.
code=0; printf '\n' | script -qec "workshop-login" /dev/null > /tmp/out 2>&1 || code=$?
grep -q "the saved key is kept" /tmp/out || { cat /tmp/out; echec "Entrée seule : clé gardée attendue"; }
if grep -q SMOKETEST /tmp/out; then echec "Entrée seule : clé affichée"; fi
[[ "$(stat -c '%U %a' "$HOME/.workshop-key")" == "root 400" && "$(workshop-key read)" == "$CLE" ]] || echec "Entrée seule : clé changée"
# Un lien à la place de la clé : jamais suivi par root.
mv "$HOME/.workshop-key" "$HOME/.workshop-key.vraie"; ln -s /etc/hostname "$HOME/.workshop-key"
if workshop-key read > /tmp/out 2>&1; then echec "workshop-key read a suivi un lien"; fi
[[ -z "$(/opt/workshop/venv/bin/python -I -c "import sys; sys.path.insert(0, '$(dirname "$(realpath "$(command -v workshop-login)")")'); import workshop_provider as p; print(p.read_key())")" ]] || echec "read_key a suivi un lien"
rm "$HOME/.workshop-key"; mv "$HOME/.workshop-key.vraie" "$HOME/.workshop-key"

etape "Une ancienne clé en 600 passe à root sans se perdre, une seule fois, et apiKeyHelper suit"
h=$(mktemp -d); mkdir "$h/.claude"
(umask 077; printf 'sk-ant-OLD0000000000\n' > "$h/.workshop-key")
printf '{\n  "apiKeyHelper": "cat %s/.workshop-key",\n  "env": { "ANTHROPIC_MODEL": "claude-sonnet-5-5" }\n}\n' "$h" > "$h/.claude/settings.json"
for i in 1 2; do
  HOME="$h" workshop-key lock || echec "workshop-key lock ($i)"
  [[ "$(stat -c '%U %a' "$h/.workshop-key")" == "root 400" ]] || echec "clé en 600 non passée à root ($i)"
  [[ "$(HOME="$h" workshop-key read)" == sk-ant-OLD0000000000 ]] || echec "clé perdue au passage à root ($i)"
  grep -qF "\"apiKeyHelper\": \"sudo -n cat $h/.workshop-key 2>/dev/null\"" "$h/.claude/settings.json" || echec "apiKeyHelper non remis d'accord ($i)"
  grep -qF '"ANTHROPIC_MODEL": "claude-sonnet-5-5"' "$h/.claude/settings.json" || echec "settings.json : réglage perdu ($i)"
done
# workshop le fait lui-même au démarrage.
(umask 077; rm -f "$h/.workshop-key"; printf 'sk-ant-OLD1111111111\n' > "$h/.workshop-key")
printf '{\n  "apiKeyHelper": "cat %s/.workshop-key"\n}\n' "$h" > "$h/.claude/settings.json"
HOME="$h" WORKSHOP_DRY_RUN=1 workshop C -p hi > /dev/null 2>&1 || true
[[ "$(stat -c '%U %a' "$h/.workshop-key")" == "root 400" && "$(HOME="$h" workshop-key read)" == sk-ant-OLD1111111111 ]] || echec "workshop : ancienne clé non passée à root"
grep -qF "sudo -n cat $h/.workshop-key" "$h/.claude/settings.json" || echec "workshop : apiKeyHelper non remis d'accord"
# Une clé refusée ne remplace pas une clé à root (faux curl).
b=$(mktemp -d); printf '#!/bin/sh\ncat > /dev/null; echo 401\n' > "$b/curl"; chmod +x "$b/curl"
code=0; printf '%s\n' sk-ant-NEW0000000000 | HOME="$h" PATH="$b:$PATH" workshop-login --key - 2>/tmp/err || code=$?
[[ "$code" == 2 ]] && grep -q "earlier key is kept" /tmp/err || { cat /tmp/err; echec "clé refusée (clé à root) : message attendu"; }
[[ "$(HOME="$h" workshop-key read)" == sk-ant-OLD1111111111 ]] || echec "clé refusée : la clé à root a été remplacée"
# Remplacée par une clé qui marche (faux curl à 200) : à root, et aucun fichier temporaire.
printf '#!/bin/sh\ncat > /dev/null; printf 200\n' > "$b/curl"
printf '%s\n' sk-ant-NEW2222222222 | HOME="$h" PATH="$b:$PATH" workshop-login --key - > /tmp/out 2>&1 || { cat /tmp/out; echec "nouvelle clé (faux curl 200)"; }
if grep -q NEW2222 /tmp/out; then echec "nouvelle clé : affichée en entier"; fi
[[ "$(stat -c '%U %a' "$h/.workshop-key")" == "root 400" && "$(HOME="$h" workshop-key read)" == sk-ant-NEW2222222222 ]] || echec "nouvelle clé : non enregistrée à root"
[[ -z "$(find "$h" -maxdepth 1 -name '.workshop-key?*')" ]] || echec "nouvelle clé : fichier temporaire laissé"
rm -rf "$h" "$b"

etape "Sans sudo sans mot de passe : clé en 600, un message, rien de cassé (faux sudo)"
h=$(mktemp -d); b=$(mktemp -d); mkdir "$h/.claude"
printf '#!/bin/sh\necho "sudo: a password is required" >&2; exit 1\n' > "$b/sudo"; chmod +x "$b/sudo"
printf '#!/bin/sh\ncat > /dev/null; printf 200\n' > "$b/curl"; chmod +x "$b/curl"
printf '%s\n' sk-ant-NOSUDO000000 | HOME="$h" PATH="$b:$PATH" workshop-login --key - > /tmp/out 2>&1 || { cat /tmp/out; echec "sans sudo : workshop-login"; }
[[ "$(grep -c "cannot be locked away" /tmp/out)" == 1 ]] || { cat /tmp/out; echec "sans sudo : un message attendu, une fois"; }
[[ "$(stat -c '%U %a' "$h/.workshop-key")" == "$(id -un) 600" ]] || echec "sans sudo : clé en 600 attendue"
[[ "$(HOME="$h" PATH="$b:$PATH" workshop-key read)" == sk-ant-NOSUDO000000 ]] || echec "sans sudo : workshop-key read"
grep -qF "\"apiKeyHelper\": \"cat $h/.workshop-key\"" "$h/.claude/settings.json" || echec "sans sudo : apiKeyHelper cat attendu"
HOME="$h" PATH="$b:$PATH" WORKSHOP_DRY_RUN=1 workshop C -p hi > /tmp/out 2>&1 || { cat /tmp/out; echec "sans sudo : workshop ne démarre pas"; }
if grep -q "cannot be locked" /tmp/out; then echec "sans sudo : message répété au démarrage"; fi
[[ "$(stat -c '%U %a' "$h/.workshop-key")" == "$(id -un) 600" ]] || echec "sans sudo : workshop a changé la clé"
rm -rf "$h" "$b"

etape "Une clé refusée ne remplace pas une clé enregistrée (faux curl)"
h=$(mktemp -d); b=$(mktemp -d); printf '#!/bin/sh\necho 401\n' > "$b/curl"; chmod +x "$b/curl"
printf 'sk-ant-OLD0000000000\n' > "$h/.workshop-key"
code=0; printf '%s\n' sk-ant-NEW0000000000 | HOME="$h" PATH="$b:$PATH" workshop-login --key - 2>/tmp/err || code=$?
[[ "$code" == 2 ]] && grep -q "earlier key is kept" /tmp/err || { cat /tmp/err; echec "clé refusée : message attendu"; }
[[ "$(cat "$h/.workshop-key")" == sk-ant-OLD0000000000 ]] || echec "clé refusée : l'ancienne clé a été remplacée"
rm -rf "$h" "$b"

etape "La clé choisit le fournisseur : passages Anthropic <-> OpenRouter (faux points d'accès, aucun appel réel)"
# Le module donne les modèles par défaut : aucun nom écrit ici, on vérifie seulement qu'aucun n'est un Claude.
BIN="$(dirname "$(realpath "$(command -v workshop-login)")")"
defaut="$(/opt/workshop/venv/bin/python -I - "$BIN" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import workshop_provider as p
assert not any("claude" in m for m in (p.OPENROUTER.chat, p.OPENROUTER.small, p.OPENROUTER.judge, p.EUROPE_MODEL)), "un Claude par défaut avec OpenRouter"
assert p.ROUTING == {"data_collection": "deny"}, p.ROUTING
assert p.EUROPE_ENDPOINTS == ["mistral/eu"], p.EUROPE_ENDPOINTS
assert p.EUROPE_MODEL != p.OPENROUTER.small, "--europe : le mode B demande une autre fenêtre que celle du petit modèle"
print(p.OPENROUTER.chat, p.OPENROUTER.small, p.EUROPE_MODEL)
PY
)" || echec "workshop_provider : modèles par défaut d'OpenRouter"
read -r defaut petit europeen <<< "$defaut"
h=$(mktemp -d); b=$(mktemp -d); mkdir "$h/.claude"
# Faux curl : répond 200 pour Anthropic ; le reste va au faux OpenRouter.
cat > "$b/curl" <<'SH'
#!/bin/bash
for a in "$@"; do
  case "$a" in *api.anthropic.com*) cat > /dev/null; printf 200; exit 0 ;; esac
done
exec /usr/bin/curl "$@"
SH
chmod +x "$b/curl"
# Faux OpenRouter : la liste des modèles, /key, et le modèle, qui force une recherche quand on lui parle en flux.
cat > "$b/faux.py" <<'PY'
import json, os, sys, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
journal, refus, *modeles = sys.argv[1:]
europeen = modeles[2]
tours = {"n": 0}
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def rend(self, code, corps):
        data = json.dumps(corps).encode()
        self.send_response(code); self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(data))); self.end_headers(); self.wfile.write(data)
    def do_GET(self):
        if self.path.endswith("/models"):
            return self.rend(200, {"data": [{"id": m, "context_length": 128000, "supported_parameters": ["tools"],
                                             "pricing": {"prompt": "0.0000001", "completion": "0.0000002"}} for m in modeles]})
        if self.path.endswith("/endpoints"):  # la fenêtre de chaque modèle en Europe, et d'autres entreprises à ignorer
            if os.path.exists(refus + "-fenetre"):
                return self.rend(500, {"error": {"message": "no"}})
            return self.rend(200, {"data": {"endpoints": [
                {"tag": "deepinfra/fp8", "context_length": 128000},
                {"tag": "mistral/eu", "context_length": 262144 if europeen in self.path else 32000},
                {"tag": "azure/eu", "context_length": 64000}, {"tag": "google-vertex/eu", "context_length": 1000}]}})
        if os.path.exists(refus):
            return self.rend(401, {"error": {"message": "no"}})
        self.rend(200, {"data": {"label": "test"}})
    def do_POST(self):
        corps = json.loads(self.rfile.read(int(self.headers.get("content-length", 0))))
        with open(journal, "a") as f: f.write(json.dumps(corps) + "\n")
        with open(journal + "-cle", "a") as f: f.write(str(self.headers.get("authorization")) + "\n")
        if "only" in corps.get("provider", {}) and (corps["model"] == "test/hors-europe"
                                                    or (corps["model"] == europeen and os.path.exists(refus + "-europeen"))):
            return self.rend(404, {"error": {"message": "No allowed providers are available for the selected model."}})
        if not corps.get("stream"):
            return self.rend(200, {"choices": [{"message": {"content": "ok"}, "finish_reason": "stop"}]})
        if os.path.exists(refus + "-lent"):  # le temps de taper workshop-login pendant la question
            time.sleep(4)
        tours["n"] += 1; d = {"content": "DONE"}; fin = "stop"
        if tours["n"] == 1:
            d = {"tool_calls": [{"index": 0, "id": "c1", "type": "function", "function": {"name": "grep",
                 "arguments": json.dumps({"pattern": "wildfire", "path": "summaries"})}}]}; fin = "tool_calls"
        self.send_response(200); self.send_header("content-type", "text/event-stream"); self.end_headers()
        for c in ({"choices": [{"index": 0, "delta": dict(d, role="assistant")}]},
                  {"choices": [{"index": 0, "delta": {}, "finish_reason": fin}], "usage": {"prompt_tokens": 10, "completion_tokens": 1}}):
            self.wfile.write(f"data: {json.dumps(c)}\n\n".encode())
        self.wfile.write(b"data: [DONE]\n\n")
ThreadingHTTPServer(("127.0.0.1", 8797), H).serve_forever()
PY
/opt/workshop/venv/bin/python -I "$b/faux.py" "$b/journal" "$b/refus" "$defaut" "$petit" "$europeen" test/hors-europe & faux=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do /usr/bin/curl -s -o /dev/null http://127.0.0.1:8797/api/v1/models && break; sleep 0.3; done
connexion() { # la clé (vide : Entrée seule), puis les options de workshop-login
  local k="$1"; shift
  if [[ -n "$k" ]]; then set -- --key - "$@"; fi
  printf '%s\n' "$k" | HOME="$h" PATH="$b:$PATH" WORKSHOP_OPENROUTER_API=http://127.0.0.1:8797/api/v1 workshop-login "$@"
}
etat() { # clé attendue, moteur attendu, modèle attendu pour OpenCode
  [[ "$(HOME="$h" workshop-key read)" == "$1" ]] || echec "clé enregistrée : attendu ${1:0:7}…"
  [[ "$(cat "$h/.workshop-engine")" == "$2" ]] || echec "moteur enregistré : attendu $2"
  grep -qF "\"model\": \"$3\"" "$h/.workshop-opencode.json" || { cat "$h/.workshop-opencode.json"; echec "modèle enregistré : attendu $3"; }
}
ANT=sk-ant-api03-SMOKETEST0000000000; OR=sk-or-v1-SMOKETEST0000000000
sortie="$(connexion "$ANT")" || { echo "$sortie"; echec "clé Anthropic neuve"; }
etat "$ANT" claude anthropic/claude-sonnet-5-5
grep -qF "Key OK (Claude Code, Anthropic, model claude-sonnet-5-5)" <<< "$sortie" || { echo "$sortie"; echec "Key OK d'Anthropic : texte attendu"; }
grep -q apiKeyHelper "$h/.claude/settings.json" || echec "apiKeyHelper absent avec une clé Anthropic"
sortie="$(connexion "$OR")" || { echo "$sortie"; echec "Anthropic puis OpenRouter"; }
etat "$OR" opencode "openrouter/$defaut"
grep -qF "Key OK (OpenCode, OpenRouter, model openrouter/$defaut)" <<< "$sortie" || { echo "$sortie"; echec "Key OK d'OpenRouter : texte attendu"; }
if grep -q apiKeyHelper "$h/.claude/settings.json"; then echec "apiKeyHelper gardé avec une clé OpenRouter (elle partirait chez Anthropic)"; fi
{ grep -q '"context": 128000' "$h/.workshop-opencode.json" && grep -q '"cost"' "$h/.workshop-opencode.json"; } || echec "fenêtre et prix du modèle non enregistrés"
tail -1 "$b/journal" | /opt/workshop/venv/bin/python -I -c "
import json, sys
c = json.loads(sys.stdin.read())
assert c['provider'] == {'data_collection': 'deny'} and c['model'] == sys.argv[1] and 'max_tokens' not in c, c" "$defaut" \
  || echec "essai du modèle sans la règle data_collection"
sortie="$(connexion "")" || { echo "$sortie"; echec "Entrée seule avec une clé OpenRouter"; }
grep -q "the saved key is kept" <<< "$sortie" || { echo "$sortie"; echec "Entrée seule : message attendu"; }
etat "$OR" opencode "openrouter/$defaut"
# Une clé refusée ne remplace pas une clé de l'autre fournisseur.
sortie="$(connexion "$ANT")" || { echo "$sortie"; echec "OpenRouter puis Anthropic"; }
etat "$ANT" claude anthropic/claude-sonnet-5-5
grep -q apiKeyHelper "$h/.claude/settings.json" || echec "apiKeyHelper non rétabli au retour vers Anthropic"
touch "$b/refus"
code=0; connexion "$OR" 2>/tmp/err > /dev/null || code=$?
{ [[ "$code" == 2 ]] && grep -q "earlier key is kept" /tmp/err; } || { cat /tmp/err; echec "clé OpenRouter refusée : code 2 et ancienne clé gardée attendus, obtenu $code"; }
etat "$ANT" claude anthropic/claude-sonnet-5-5
rm "$b/refus"
# OpenCode choisi avec --engine : il reste après un passage par OpenRouter ; --engine claude revient en arrière.
connexion "$ANT" --engine opencode > /dev/null || echec "--engine opencode avec une clé Anthropic"
etat "$ANT" opencode anthropic/claude-sonnet-5-5
connexion "$OR" > /dev/null || echec "OpenCode explicite puis OpenRouter"
connexion "$ANT" > /dev/null || echec "retour à Anthropic"
etat "$ANT" opencode anthropic/claude-sonnet-5-5
connexion "$ANT" --engine claude > /dev/null || echec "--engine claude"
etat "$ANT" claude anthropic/claude-sonnet-5-5
# WORKSHOP_ENGINE : pour une commande, jamais enregistré, et dit à l'écran.
sortie="$(WORKSHOP_ENGINE=opencode connexion "$ANT")" || { echo "$sortie"; echec "WORKSHOP_ENGINE=opencode"; }
etat "$ANT" claude anthropic/claude-sonnet-5-5
grep -qF "WORKSHOP_ENGINE=opencode is not saved" <<< "$sortie" || { echo "$sortie"; echec "WORKSHOP_ENGINE non enregistré : message attendu"; }

etape "OpenRouter en mode classe : l'avertissement sur les jeunes ; Anthropic sans changement"
sortie="$(OPENWEBUI_MODE=class connexion "$OR" 2>&1)" || { echo "$sortie"; echec "mode classe avec une clé OpenRouter"; }
grep -qxF "Warning: with young people, turn on zero-data-retention models hosted in Europe: workshop-login --europe" <<< "$sortie" || { echo "$sortie"; echec "mode classe : avertissement absent"; }
grep -qF "Key OK (OpenRouter, model $defaut). You can start: openwebui start" <<< "$sortie" || { echo "$sortie"; echec "mode classe : Key OK attendu"; }
sortie="$(OPENWEBUI_MODE=class connexion "$ANT" 2>&1)" || { echo "$sortie"; echec "mode classe avec une clé Anthropic"; }
if grep -q "young people" <<< "$sortie"; then echec "mode classe, Anthropic : l'avertissement ne le concerne pas"; fi
grep -qF "Key OK (Anthropic, model claude-sonnet-5-5). You can start: openwebui start" <<< "$sortie" || { echo "$sortie"; echec "mode classe, Anthropic : Key OK attendu"; }

etape "OpenRouter avec le vrai OpenCode : une recherche (rg sans téléchargement), le modèle, la règle de routage"
connexion "$OR" > /dev/null || echec "clé OpenRouter"
: > "$b/journal"
sortie="$(HOME="$h" WORKSHOP_HOME="$copie" WORKSHOP_OPENCODE_BASEURL=http://127.0.0.1:8797/api/v1 timeout 120 workshop C -p probe 2>&1)" \
  || { echo "$sortie"; echec "workshop C avec une clé OpenRouter"; }
/opt/workshop/venv/bin/python -I - "$b/journal" "$defaut" <<'PY' || echec "OpenRouter avec OpenCode : requêtes inattendues"
import json, sys
corps = [json.loads(l) for l in open(sys.argv[1])]
assert len(corps) == 2, len(corps)
for c in corps:
    assert c["provider"] == {"data_collection": "deny"}, c.get("provider")
    assert c["model"] == sys.argv[2], c["model"]
reponse = [str(m.get("content")) for m in corps[1]["messages"] if m.get("role") == "tool"][-1]
assert "matches" in reponse and "ripgrep execution failed" not in reponse, reponse[:200]
print("deux requêtes, modèle par défaut, routage dans chacune, recherche :", reponse.split(chr(10))[0])
PY
[[ -z "$(find "$h" -type f -name rg)" ]] || echec "OpenCode a téléchargé son propre rg alors qu'il y en a un sur le PATH"
# La clé, à root, arrive quand même au point d'accès (par une variable de la seule session d'OpenCode).
[[ "$(stat -c '%U' "$h/.workshop-key")" == root ]] || echec "clé OpenRouter : pas à root"
[[ "$(tail -1 "$b/journal-cle")" == "Bearer $OR" ]] || { tail -2 "$b/journal-cle"; echec "OpenCode n'a pas envoyé la clé enregistrée"; }
if grep -rqs SMOKETEST "$h/.workshop-run" "$h/.local" "$h/.cache" "$h/.config"; then echec "la clé est restée dans un fichier d'OpenCode"; fi

etape "workshop-login --europe : enregistré, gardé, retiré, perdu au changement de fournisseur, refusé avec une clé Anthropic"
fichier="$h/.workshop-opencode.json"
routage_europe() { # le dernier corps du journal porte la règle européenne, pour le modèle $1
  tail -1 "$b/journal" | /opt/workshop/venv/bin/python -I -c "
import json, sys
c = json.loads(sys.stdin.read())
assert c['model'] == sys.argv[1], c['model']
assert c['provider'] == {'data_collection': 'deny', 'zdr': True, 'allow_fallbacks': False, 'only': ['mistral/eu']}, c['provider']" "$1"
}
sortie="$(connexion "" --europe)" || { echo "$sortie"; echec "--europe, Entrée seule"; }
etat "$OR" opencode "openrouter/$europeen"
grep -qF "Key OK (OpenCode, OpenRouter, model openrouter/$europeen, hosted in Europe). You can start:" <<< "$sortie" || { echo "$sortie"; echec "--europe : Key OK attendu"; }
grep -q '"europe": true' "$fichier" || echec "--europe non enregistré"
grep -q '"context": 262144' "$fichier" || { cat "$fichier"; echec "--europe : la fenêtre européenne attendue (262144)"; }
if grep -q "not checked" <<< "$sortie"; then echo "$sortie"; echec "--europe : fenêtre lue, mais annoncée non vérifiée"; fi
routage_europe "$europeen" || echec "--europe : règle absente de l'essai du modèle"
sortie="$(connexion "")" || { echo "$sortie"; echec "--europe puis Entrée seule"; }
etat "$OR" opencode "openrouter/$europeen"; grep -q '"europe": true' "$fichier" || echec "--europe perdu à la connexion suivante (Entrée seule)"
grep -qF "hosted in Europe" <<< "$sortie" || { echo "$sortie"; echec "--europe gardé : Key OK attendu"; }
connexion "${OR}B" > /dev/null || echec "--europe puis une nouvelle clé OpenRouter"
etat "${OR}B" opencode "openrouter/$europeen"; grep -q '"europe": true' "$fichier" || echec "--europe perdu avec une nouvelle clé du même fournisseur"
connexion "$OR" > /dev/null || echec "retour à la première clé OpenRouter"
# --model garde sa place ; l'essai dit que Mistral ne sert pas ce modèle, et propose un modèle qui marche.
code=0; connexion "" --model test/hors-europe > /dev/null 2>/tmp/err || code=$?
{ [[ "$code" == 4 ]] && grep -qF "Key saved, but Mistral does not serve the model openrouter/test/hors-europe in Europe with zero data retention." /tmp/err && grep -qF "workshop-login --model $europeen" /tmp/err; } || { cat /tmp/err; echec "--europe, modèle hors d'Europe : phrase attendue, code $code"; }
grep -q '"europe": true' "$fichier" || echec "--europe perdu après un modèle refusé"
# Le modèle par défaut refusé : jamais lui-même comme conseil.
touch "$b/refus-europeen"
code=0; connexion "" --model "$europeen" > /dev/null 2>/tmp/err || code=$?
rm "$b/refus-europeen"
{ [[ "$code" == 4 ]] && grep -qF "for example: workshop-login --model $petit" /tmp/err; } || { cat /tmp/err; echec "--europe, modèle par défaut refusé : l'autre modèle attendu, code $code"; }
connexion "" --model "$europeen" > /dev/null || echec "--europe : retour au modèle par défaut"
# Sans la liste des entreprises du modèle : la valeur de la liste, et on le dit.
touch "$b/refus-fenetre"
sortie="$(connexion "")" || { echo "$sortie"; echec "--europe sans la liste des entreprises"; }
grep -q "is not checked" <<< "$sortie" || { echo "$sortie"; echec "--europe : fenêtre non vérifiée, message attendu"; }
grep -q '"context": 128000' "$fichier" || { cat "$fichier"; echec "--europe : valeur de la liste attendue"; }
rm "$b/refus-fenetre"; connexion "" > /dev/null || echec "--europe : fenêtre relue"
# Le vrai OpenCode envoie la règle et déclare la fenêtre.
: > "$b/journal"
sortie="$(HOME="$h" WORKSHOP_HOME="$copie" WORKSHOP_OPENCODE_BASEURL=http://127.0.0.1:8797/api/v1 timeout 120 workshop C -p probe 2>&1)" \
  || { echo "$sortie"; echec "workshop C avec --europe"; }
routage_europe "$europeen" || echec "--europe : règle absente de la requête d'OpenCode"
fenetre_declaree() { # le modèle $1 est déclaré à OpenCode avec la fenêtre $2
  HOME="$h" WORKSHOP_HOME="$copie" WORKSHOP_DRY_RUN=1 workshop-opencode C -p x | /opt/workshop/venv/bin/python -I -c "
import json, sys
c = json.load(sys.stdin)['config']['providers']['openrouter']['models'][sys.argv[1]]
assert c['limit']['context'] == int(sys.argv[2]), c" "$1" "$2"
}
fenetre_declaree "$europeen" 200000 || echec "--europe : fenêtre ramenée à 200000 attendue, comme avec Claude"
# Le mode B tient dans cette fenêtre : la question part, sous la règle européenne.
: > "$b/journal"
sortie="$(HOME="$h" WORKSHOP_HOME="$copie" WORKSHOP_OPENCODE_BASEURL=http://127.0.0.1:8797/api/v1 timeout 120 workshop B -p probe 2>&1)" \
  || { echo "$sortie"; echec "--europe : le mode B doit tourner avec le modèle par défaut"; }
routage_europe "$europeen" || echec "--europe : règle absente du mode B"
# Tourner --europe avec un modèle que Mistral ne sert pas : le modèle change.
connexion "" --no-europe --model test/hors-europe > /dev/null || echec "--no-europe --model"
sortie="$(connexion "" --europe)" || { echo "$sortie"; echec "--europe depuis un modèle hors d'Europe"; }
etat "$OR" opencode "openrouter/$europeen"
# Un modèle à 32k tapé par quelqu'un : gardé, et le mode B est refusé avant toute requête, avec un modèle qui marche.
connexion "" --model "$petit" > /dev/null || echec "--europe : le petit modèle"
grep -q '"context": 32000' "$fichier" || { cat "$fichier"; echec "--europe : petit modèle, 32000 attendu"; }
connexion "" --europe > /dev/null || echec "--europe, déjà là, petit modèle"
etat "$OR" opencode "openrouter/$petit"
fenetre_declaree "$petit" 32000 || echec "--europe : fenêtre de 32000 non déclarée à OpenCode"
: > "$b/journal"; code=0
sortie="$(HOME="$h" WORKSHOP_HOME="$copie" WORKSHOP_OPENCODE_BASEURL=http://127.0.0.1:8797/api/v1 timeout 60 workshop B -p x 2>&1)" || code=$?
{ [[ "$code" == 1 ]] && grep -qF "This mode cannot run with it. Choose a model with a larger window: workshop-login --model $europeen" <<< "$sortie" && [[ ! -s "$b/journal" ]]; } || { echo "$sortie"; echec "--europe : mode B en 32k, refus attendu"; }
connexion "" --model "$europeen" > /dev/null || echec "--europe : retour au modèle par défaut"
sortie="$(OPENWEBUI_MODE=class connexion "" 2>&1)" || { echo "$sortie"; echec "--europe en mode classe"; }
if grep -q "young people" <<< "$sortie"; then echo "$sortie"; echec "--europe en mode classe : pas d'avertissement attendu"; fi
grep -qF "Key OK (OpenRouter, model $europeen, hosted in Europe). You can start: openwebui start" <<< "$sortie" || { echo "$sortie"; echec "--europe en mode classe : Key OK attendu"; }
# Clé Anthropic : rien n'est enregistré.
lu() { { HOME="$h" workshop-key read; cat "$h/.workshop-engine" "$fichier" "$h/.claude/settings.json"; } | sha256sum; }
avant="$(lu)"
code=0; connexion "$ANT" --europe > /dev/null 2>/tmp/err || code=$?
{ [[ "$code" == 1 ]] && grep -qF -- "--europe needs an OpenRouter key" /tmp/err && grep -q "Nothing saved" /tmp/err; } || { cat /tmp/err; echec "--europe avec une clé Anthropic : refus attendu, code $code"; }
[[ "$avant" == "$(lu)" ]] || echec "--europe avec une clé Anthropic : quelque chose a été enregistré"
# --no-europe : le modèle reste, la règle et la fenêtre reviennent, l'avertissement aussi.
sortie="$(OPENWEBUI_MODE=class connexion "" --no-europe 2>&1)" || { echo "$sortie"; echec "--no-europe"; }
if grep -q '"europe"' "$fichier"; then cat "$fichier"; echec "--no-europe : réglage resté"; fi
grep -q '"context": 128000' "$fichier" || { cat "$fichier"; echec "--no-europe : fenêtre de la liste attendue"; }
grep -q "workshop-login --europe" <<< "$sortie" || { echo "$sortie"; echec "--no-europe : avertissement attendu en mode classe"; }
etat "$OR" opencode "openrouter/$europeen"
tail -1 "$b/journal" | grep -q '"provider": {"data_collection": "deny"}' || echec "--no-europe : règle ordinaire attendue"
# Règle changée pendant replay : OpenCode ouvert est signalé, et la question suivante ne part pas.
sortie="$(connexion "")" || { echo "$sortie"; echec "--no-europe puis Entrée seule"; }
if grep -q "keeps the old data rule" <<< "$sortie"; then echo "$sortie"; echec "règle inchangée : pas de ligne attendue"; fi
: > "$b/journal"; touch "$b/refus-lent"
HOME="$h" WORKSHOP_HOME="$copie" WORKSHOP_OPENCODE_BASEURL=http://127.0.0.1:8797/api/v1 replay C 1 2 3 > /tmp/replay-regle 2>&1 & r=$!
for _ in $(seq 1 300); do grep -q '"stream": true' "$b/journal" && break; sleep 0.2; done
sortie="$(connexion "" --europe)" || { echo "$sortie"; echec "--europe pendant replay"; }
grep -qF "OpenCode is already open and keeps the old data rule" <<< "$sortie" || { echo "$sortie"; echec "--europe pendant replay : ligne attendue"; }
code=0; wait "$r" || code=$?
rm "$b/refus-lent"
{ [[ "$code" == 1 ]] && grep -qF "Your data rule changed during this replay" /tmp/replay-regle; } || { cat /tmp/replay-regle; echec "replay : arrêt attendu, code $code"; }
/opt/workshop/venv/bin/python -I - "$b/journal" <<'PY' || echec "replay : une question est partie sous l'ancienne règle"
import json, sys
corps = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
questions = {json.dumps(c["messages"][-1]) for c in corps if c.get("stream") and c["provider"] == {"data_collection": "deny"}}
assert len(questions) == 1, questions
PY
rm -f "$copie"/answers/C-*.md
connexion "" --no-europe > /dev/null || echec "--no-europe après replay"
# Changement de fournisseur : le réglage part, et le fichier d'Anthropic ne change pas d'un octet.
connexion "" --europe > /dev/null || echec "--europe de nouveau"
sortie="$(connexion "$ANT")" || { echo "$sortie"; echec "--europe puis clé Anthropic"; }
grep -qF "Key OK (Claude Code, Anthropic, model claude-sonnet-5-5)" <<< "$sortie" || { echo "$sortie"; echec "clé Anthropic après --europe : Key OK attendu"; }
[[ "$(cat "$fichier")" == '{"provider": "anthropic", "model": "anthropic/claude-sonnet-5-5", "engine_explicit": false}' ]] || { cat "$fichier"; echec "clé Anthropic : fichier changé"; }
connexion "$OR" > /dev/null || echec "retour à OpenRouter après --europe"
etat "$OR" opencode "openrouter/$defaut"
if grep -q '"europe"' "$fichier"; then cat "$fichier"; echec "--europe gardé après un changement de fournisseur"; fi
kill "$faux"; wait "$faux" 2>/dev/null || true
rm -rf "$h" "$b"

etape "score, replay, openwebui : chargés d'ailleurs (SourceFileLoader, python -I), avec le module à côté d'eux"
h=$(mktemp -d); l=$(mktemp -d); ln -s "$(command -v score)" "$l/score-lien"
(cd "$h" && HOME="$h" /opt/workshop/venv/bin/python -I - "$(command -v score)" "$l/score-lien" "$(command -v replay)" "$(command -v openwebui)" <<'PY') || echec "chargement par SourceFileLoader"
import contextlib, importlib.machinery, importlib.util, io, json, os, pathlib, sys
def charge(nom, chemin):
    l = importlib.machinery.SourceFileLoader(nom, chemin)
    m = importlib.util.module_from_spec(importlib.util.spec_from_loader(nom, l)); l.exec_module(m)
    return m
score, lien, replay, owui = charge("score", sys.argv[1]), charge("score2", sys.argv[2]), charge("replay", sys.argv[3]), charge("owui", sys.argv[4])
wp = sys.modules["workshop_provider"]
assert os.path.dirname(wp.__file__) == os.path.dirname(os.path.realpath(sys.argv[1])), wp.__file__
# Le juge suit la clé.
assert score.judge_model("sk-or-x") == wp.OPENROUTER.judge and score.judge_model("sk-ant-x") == wp.ANTHROPIC.judge
assert lien.JUDGE_MODEL == wp.ANTHROPIC.small == score.JUDGE_MODEL
# La ligne Engine de replay, que score relit pour écrire le modèle sous le tableau.
def relue(ligne):
    p = pathlib.Path("reponses.md"); p.write_text(f"# Answers: mode C\n\n{ligne}\n\n## 1\n", encoding="utf-8")
    return score.model_of(p)
wp.KEY_FILE.write_text("sk-or-x\n"); wp.SETTINGS_FILE.write_text(json.dumps({"provider": "openrouter", "model": "openrouter/a/b:free"}))
assert relue(replay.OpenWebUIRag().engine_line()) == "a/b:free"
assert relue("Engine: OpenCode (model openrouter/a/b:free)") == "openrouter/a/b:free"
assert score.different_models({"bare": "openrouter/a/b:free", "A": "a/b:free"}) is None
assert "cannot be compared" in score.different_models({"bare": "a/b:free", "A": "claude-sonnet-5-5"})
os.environ["WORKSHOP_MODEL"] = "claude-sonnet-5-5"
ligne = replay.claude_engine_line()
assert ligne == "Engine: Claude Code (model claude-sonnet-5-5)" and relue(ligne) == "claude-sonnet-5-5", ligne
# Open WebUI : la règle de routage sur les modèles d'OpenRouter, jamais sur ceux d'Anthropic.
assert owui.routed({}, wp.OPENROUTER)["custom_params"]["provider"] == json.dumps(wp.ROUTING)
assert "custom_params" not in owui.routed({"custom_params": {"provider": "{}"}}, wp.ANTHROPIC)
sortie = io.StringIO()
with contextlib.redirect_stdout(sortie):
    owui.warn_young_people(wp.ANTHROPIC)
assert not sortie.getvalue()
with contextlib.redirect_stdout(sortie):
    owui.warn_young_people(wp.OPENROUTER)
assert "turn on zero-data-retention models hosted in Europe: workshop-login --europe\nHow to do it: https://" in sortie.getvalue(), sortie.getvalue()
# --europe : la même règle partout, pas d'avertissement, un autre juge, et Open WebUI redémarre pour la prendre.
class Conteneur:
    returncode = 0
    stdout = json.dumps(["OPENAI_API_KEY=sk-or-x", "DEFAULT_MODEL_PARAMS=" + json.dumps(owui.routed({}, wp.OPENROUTER))]
                        + [f"{nom}={valeur}" for nom, valeur in owui.HARDENED.items()]
                        + ["TOOL_SERVER_CONNECTIONS=" + json.dumps(owui.mcp_connection("x"))])
owui.docker = lambda *a, **k: Conteneur
owui.check_same_key("sk-or-x", "a/b")
# Un conteneur lancé par une version plus ancienne (sans gabarit RAG, notes encore là) : openwebui start d'abord.
assert "RAG_TEMPLATE" in owui.HARDENED and owui.HARDENED["ENABLE_NOTES"] == "false"
class Ancien:
    returncode = 0
    stdout = json.dumps(json.loads(Conteneur.stdout)[:2])
owui.docker = lambda *a, **k: Ancien
erreur = io.StringIO()
try:
    with contextlib.redirect_stderr(erreur):
        owui.check_same_key("sk-or-x", "a/b")
    raise AssertionError("un conteneur ancien doit arrêter check_same_key")
except SystemExit:
    assert "started by an older version" in erreur.getvalue(), erreur.getvalue()
owui.docker = lambda *a, **k: Conteneur
wp.SETTINGS_FILE.write_text(json.dumps({"provider": "openrouter", "model": "openrouter/a/b", "europe": True}))
assert wp.routing() == {"data_collection": "deny", "zdr": True, "only": wp.EUROPE_ENDPOINTS, "allow_fallbacks": False}
assert json.loads(owui.routed({}, wp.OPENROUTER)["custom_params"]["provider"]) == wp.routing()
assert "custom_params" not in owui.routed({}, wp.ANTHROPIC)
sortie = io.StringIO()
with contextlib.redirect_stdout(sortie):
    owui.warn_young_people(wp.OPENROUTER)
assert not sortie.getvalue()
assert score.judge_model("sk-or-x") == wp.OPENROUTER.small and score.judge_model("sk-ant-x") == wp.ANTHROPIC.judge
# Mode classe avec --europe : deux modèles de base. Chaque chatbot garde le sien ou va au bon ; un seul avec le petit modèle.
class Api:
    def __init__(self, lignes):
        self.lignes, self.modifs = lignes, {}
    def request(self, methode, chemin, body=None, query=None):
        if methode == "GET":
            return self.lignes
        self.modifs[body["id"]] = body["base_model_id"]
def bot(nom, base):
    return {"id": nom, "name": nom, "base_model_id": base, "params": {}, "meta": {}}
owui.has_tools = lambda *a: True
petit, grand = wp.OPENROUTER.small, wp.EUROPE_MODEL
owui.CLASS = True
assert owui.base_models("sk-or-x", grand) == [grand, petit] and owui.base_models("sk-or-x", petit) == [petit]
lignes = [bot("petit", petit), bot("ordinaire", wp.OPENROUTER.chat), bot("haiku", wp.ANTHROPIC.small), bot("sonnet", wp.ANTHROPIC.chat)]
api = Api(lignes)
with contextlib.redirect_stdout(io.StringIO()):
    owui.realign_models(api, "sk-or-x", wp.OPENROUTER, grand)
assert api.modifs == {"petit": petit, "ordinaire": grand, "haiku": petit, "sonnet": grand}, api.modifs
api = Api([bot("grand", grand), bot("petit", petit)])
with contextlib.redirect_stdout(io.StringIO()):
    owui.realign_models(api, "sk-or-x", wp.OPENROUTER, petit)
assert api.modifs == {"grand": petit, "petit": petit}, api.modifs
# Le retour au grand modèle ne ramène pas les chatbots : openwebui start les nomme, avec --europe seulement.
def nommes(modele, reglages):
    wp.SETTINGS_FILE.write_text(json.dumps(reglages))
    sortie = io.StringIO()
    with contextlib.redirect_stdout(sortie):
        owui.name_second_model_chatbots(Api([bot("grand", grand), bot("petit", petit)]), "sk-or-x", modele)
    return sortie.getvalue()
regle = {"provider": "openrouter", "model": "openrouter/" + grand, "europe": True}
assert "petit stays on " + petit in nommes(grand, regle) and "-> " + grand + " ->" in nommes(grand, regle)
assert not nommes(petit, regle) and not nommes(grand, {**regle, "europe": False})
owui.CLASS = False
# Trop petite fenêtre : un conseil qui marche, jamais le modèle en cours.
wp.SETTINGS_FILE.write_text(json.dumps({"provider": "openrouter", "model": "openrouter/" + petit, "europe": True}))
assert wp.larger_window_advice().endswith("workshop-login --model " + grand), wp.larger_window_advice()
wp.SETTINGS_FILE.write_text(json.dumps({"provider": "openrouter", "model": "openrouter/" + grand, "europe": True}))
assert grand not in wp.larger_window_advice(), wp.larger_window_advice()
wp.SETTINGS_FILE.write_text(json.dumps({"provider": "openrouter", "model": "openrouter/a/b"}))
assert wp.larger_window_advice().endswith("--models openrouter"), wp.larger_window_advice()
wp.SETTINGS_FILE.write_text(json.dumps({"provider": "openrouter", "model": "openrouter/a/b", "europe": True}))
ancien = owui.routed({"system": "s", "custom_params": {"provider": json.dumps(wp.ROUTING), "seed": 1}}, wp.OPENROUTER)
assert ancien["custom_params"]["seed"] == 1 and json.loads(ancien["custom_params"]["provider"]) == wp.routing()
try:
    owui.check_same_key("sk-or-x", "a/b")
    raise AssertionError("une règle changée doit arrêter check_same_key")
except SystemExit:
    pass
# replay RAG : Open WebUI garde sa règle, la question suivante ne part pas.
rag = replay.OpenWebUIRag()
rag.request = lambda *a, **k: (_ for _ in ()).throw(AssertionError("question envoyée"))
wp.SETTINGS_FILE.write_text(json.dumps({"provider": "openrouter", "model": "openrouter/a/b"}))
try:
    rag.ask("q")
    raise AssertionError("une règle changée doit arrêter replay RAG")
except SystemExit as e:
    assert "Your data rule changed" in str(e), e
print("score, replay, openwebui : chargés ; juge, ligne Engine, routage et avertissement OK")
PY
rm -rf "$h" "$l"

etape "Réglages de chaque mode (répétition à blanc, sans appel au modèle)"
grep -q 'CLAUDE_CODE_AUTO_CONNECT_IDE="false"' "$(command -v workshop-claude)" || echec "workshop-claude : lien avec VS Code non coupé (outils et sélection envoyés au modèle)"
grep -q 'CLAUDE_CODE_DISABLE_AUTO_MEMORY="1"' "$(command -v workshop-claude)" || echec "workshop-claude : mémoire automatique active (replay non indépendant)"
reglages() { WORKSHOP_DRY_RUN=1 workshop "$1" -p hi; }
a_la_suite() { printf '%s\n' "$1" | grep -A1 -xF -- "$2" | tail -1; }
for m in bare A B C D; do
  grep -qxF -- manual <<< "$(a_la_suite "$(reglages "$m")" --permission-mode)" || echec "mode $m : --permission-mode manual absent"
done
for m in bare A B; do
  r="$(reglages "$m")"
  [[ "$(a_la_suite "$r" --tools)" == "" ]] || echec "mode $m : des outils sont actifs"
  grep -qxF -- --mcp-config <<< "$r" && echec "mode $m : serveur MCP chargé"
done
grep -q "^cwd=.*\.workshop-bare$" <<< "$(reglages bare)" || echec "mode bare : pas lancé hors du kit"
grep -qxF -- --append-system-prompt-file <<< "$(reglages A)" && echec "mode A : corpus préchargé"
fichier="$(a_la_suite "$(reglages B)" --append-system-prompt-file)"
attendus="$(( $(find "$KIT/summaries" -maxdepth 1 -name '[1-9]*.md' | wc -l) + $(find "$KIT/corpus/text" -maxdepth 1 -name '[1-9]*.md' | wc -l) ))"
charges="$(grep -cE '^## Document: (summaries|corpus/text)/[1-9]' "$fichier")"
[[ "$charges" == "$attendus" ]] || echec "mode B : $charges documents chargés sur $attendus"
echo "B : $charges documents (résumés et copies lisibles du corpus) chargés au démarrage"
# Un lien dans summaries/ n'entre jamais dans les instructions (il mènerait à la clé ou à /proc/self/environ).
ln -s "$HOME/.workshop-key" "$copie/summaries/98-lien.md"
fichier="$(a_la_suite "$(WORKSHOP_HOME="$copie" reglages B)" --append-system-prompt-file)"
if grep -q "summaries/98-lien.md" "$fichier"; then echec "mode B : un lien a été chargé"; fi
rm "$copie/summaries/98-lien.md"
r="$(reglages C)"
[[ "$(a_la_suite "$r" --tools)" == "Read,Bash,Edit,Write,Skill" ]] || echec "mode C : outils inattendus"
grep -qxF -- --mcp-config <<< "$r" && echec "mode C : serveur MCP chargé"
grep -qxF -- --mcp-config <<< "$(reglages D)" || echec "mode D : serveur MCP absent"
if reglages E 2>/tmp/err; then echec "mode E lancé sans wiki"; fi
grep -q wiki-start /tmp/err || echec "mode E sans wiki : message attendu wiki-start"
r="$(WORKSHOP_HOME="$copie" reglages E)"
grep -qxF -- --mcp-config <<< "$r" || echec "mode E : serveur MCP absent"
grep -q "wiki/index.md" <<< "$r" || echec "mode E : le wiki n'est pas indiqué au modèle"
for m in C D E; do
  r="$(WORKSHOP_HOME="$copie" reglages "$m")"
  grep -q "disableAutoMode" <<< "$r" || echec "mode $m : mode auto non désactivé"
  grep -qxF -- --disallowedTools <<< "$r" && echec "mode $m : règle de refus (demande de permission à chaque cd …; grep)"
  grep -q "test-questions.md, scores.md, answers/ or examples/" <<< "$r" || echec "mode $m : consigne sur le matériel de test absente"
  # wc, du, tree, diff et git montrent ~/.workshop-key malgré le blocage hors du dossier (--files0-from, --fromfile,
  # --from-file, git blame --ignore-revs-file) ; docker inspect, la clé donnée à Open WebUI.
  # sudo et ce qui en tient lieu, workshop-key : ils rendraient la clé, à root.
  for c in wc du tree diff git docker sudo sudoedit su pkexec workshop-key /usr/bin/sudo env exec sh bash; do
    grep -qF "\"Bash($c:*)\"" <<< "$r" || echec "mode $m : règle de refus Bash($c:*) absente (la clé serait lisible)"
    grep -qxF -- "Bash($c:*)" <<< "$r" && echec "mode $m : Bash($c:*) autorisé"
  done
done
echo "C : recherche et skills ; D : + MCP ; E : + wiki (après wiki-start) ; mode auto désactivé"
grep -q "never write tool calls" <<< "$(reglages A)" || echec "mode A : consigne « pas d'outils » absente (faux appels d'outils)"
grep -q "never write tool calls" "$(a_la_suite "$(reglages B)" --append-system-prompt-file)" || echec "mode B : consigne « pas d'outils » absente"

etape "Personnalités (replay --agents), notes (score), sauvegarde et reprise (workshop-save, workshop-start)"
r="$(WORKSHOP_AGENTS="$KIT/examples/AGENTS.liar.md" reglages A)"
grep -qxF -- --add-dir <<< "$r" || echec "WORKSHOP_AGENTS : dossier des instructions non ajouté"
grep -q claudeMdExcludes <<< "$r" || echec "WORKSHOP_AGENTS : AGENTS.md du kit non exclu"
for p in liar storyteller sophist; do
  grep -q "Demo bot: this answer contains deliberate errors" "$KIT/examples/AGENTS.$p.md" || echec "AGENTS.$p.md : étiquette de démonstration absente"
done
# replay : une faute de frappe ne rejoue pas tout (aucune question posée) ; D à F seulement si le dépôt les a.
code=0; replay D 8,11 > /tmp/out 2>&1 || code=$?
[[ $code == 1 ]] && grep -q "Not a question number: 8,11" /tmp/out || { cat /tmp/out; echec "replay D 8,11 : refus attendu"; }
code=0; replay D 99 > /tmp/out 2>&1 || code=$?
[[ $code == 1 ]] && grep -q "No question 99" /tmp/out || { cat /tmp/out; echec "replay D 99 : refus attendu"; }
code=0; replay Z > /tmp/out 2>&1 || code=$?
[[ $code == 1 ]] && grep -q "Unknown mode: Z" /tmp/out || { cat /tmp/out; echec "replay Z : message attendu"; }
d3="$(mktemp -d)"; cp -r "$KIT/." "$d3"; rm -rf "$d3/.git" "$d3/.mcp.json"
code=0; WORKSHOP_HOME="$d3" workshop D -p hi > /tmp/out 2>&1 || code=$?
[[ $code == 1 ]] && grep -q "Mode D comes with workshop 4" /tmp/out || { cat /tmp/out; echec "mode D sans .mcp.json : message attendu"; }
code=0; WORKSHOP_HOME="$d3" replay D 1 > /tmp/out 2>&1 || code=$?
[[ $code == 1 ]] && grep -q "Mode D comes with workshop 4" /tmp/out || { cat /tmp/out; echec "replay D sans .mcp.json : message attendu"; }
sortie="$(WORKSHOP_HOME="$d3" WORKSHOP_DRY_RUN=1 workshop A 2>&1 > /dev/null)"
grep -q "Other modes: workshop bare | A | B | C$" <<< "$sortie" || { echo "$sortie"; echec "bannière : modes de ce dépôt attendus"; }
rm -rf "$d3"
score --help > /dev/null || echec "score --help"
code=0; WORKSHOP_HOME="$copie" score A > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "replay A" /tmp/err || { cat /tmp/err; echec "score sans réponses : message attendu replay A"; }
# score : le dernier verdict du juge l'emporte (il se corrige parfois dans la même réponse)
/opt/workshop/venv/bin/python - "$(command -v score)" <<'PY' || echec "score : parse_verdict ne garde pas le dernier verdict"
import importlib.machinery, importlib.util, sys
l = importlib.machinery.SourceFileLoader("score", sys.argv[1]); m = importlib.util.module_from_spec(importlib.util.spec_from_loader("score", l)); l.exec_module(m)
assert m.parse_verdict('{"score": 0, "why": "x"} {"score": 1, "why": "y"}')["score"] == "1"
assert m.parse_verdict("rien") is None
# Dépôts sans mcp/ (ateliers 1 à 3) : pas de message de panne à la question 8.
import pathlib, tempfile
m.KIT = pathlib.Path(tempfile.mkdtemp())
assert "No live tool" in m.with_live_data("q", "x mcp/fire-danger.json")
PY
code=0; workshop-start > /dev/null 2>&1 || code=$?
[[ $code == 2 ]] || echec "workshop-start sans numéro : code 2 attendu, obtenu $code"
code=0; workshop-start 3 --from "" > /dev/null 2>&1 || code=$?
[[ $code == 2 ]] || echec "workshop-start --from vide : code 2 attendu, obtenu $code"
# workshop-start : ouvre le README d'un dépôt d'atelier, signale le dépôt d'un autre atelier (sans clé : rien ne démarre)
d1="$(mktemp -d)"; cp -r "$copie"/. "$d1"/; printf '# Workshop 1 - Test\n' > "$d1/README.md"
grep -q "Today's page: README.md" <<< "$(cd "$d1" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d1" workshop-start 1)" || echec "workshop-start 1 : README de l'atelier non ouvert"
code=0; sortie="$(cd "$d1" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d1" workshop-start 3 2>&1)" || code=$?
[[ $code == 1 ]] && grep -q "This repository is for workshop 1" <<< "$sortie" || { echo "$sortie"; echec "workshop-start 3 dans le dépôt de l'atelier 1 : refus attendu"; }
# Atelier 6 : son propre dépôt, sans kit. workshop-start 6 n'y prépare rien, workshop-save garde messages/,
# et une nouvelle copie les reprend ; ailleurs, workshop-start 6 renvoie à son dépôt.
d6="$(mktemp -d)"; printf '# Workshop 6 - Test\n' > "$d6/README.md"; printf '#!/bin/sh\n' > "$d6/sorter"
printf 's\n' > "$d6/SETUP.md"; printf 's\n' > "$d6/sheet.md"; mkdir "$d6/tools"; printf 'x = 1\n' > "$d6/tools/sorter.py"
mkdir "$d6/messages"; printf '## topic\n- a\n' > "$d6/messages/examples.md"; printf '## topic\n- b\n' > "$d6/messages/test.md"
git -C "$d6" init -q; git -C "$d6" add -A; git -C "$d6" -c user.name=t -c user.email=t@t commit -qm depart
d6b="$(mktemp -d)"; cp -r "$d6"/. "$d6b"/
sortie="$(cd "$d6" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6" workshop-start 6)" || { echo "$sortie"; echec "workshop-start 6"; }
grep -qF 'First command: ./sorter setup' <<< "$sortie" || { echo "$sortie"; echec "workshop-start 6 : première commande absente"; }
[[ ! -e "$d6/AGENTS.md" ]] || echec "workshop-start 6 : un fichier du kit a été ajouté"
printf -- '- mine\n' >> "$d6/messages/examples.md"
printf '#!/bin/sh\n' > "$d6/messages/mine.sh"; chmod +x "$d6/messages/mine.sh"
(cd "$d6" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6" workshop-save > /dev/null) || echec "workshop-save (atelier 6)"
unzip -p "$d6/my-work.zip" messages/examples.md | grep -qx -- '- mine' || echec "workshop-save : messages/ absent du .zip"
unzip -p "$d6/my-work.zip" MANIFEST.md | grep -qx "Workshop: 6" || echec "workshop-save : « Workshop: 6 » absent du MANIFEST"
cp "$d6/my-work.zip" "$d6b/"
(cd "$d6b" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6b" workshop-start 6 --from my-work.zip > /dev/null) || echec "workshop-start 6 --from"
grep -qx -- '- mine' "$d6b/messages/examples.md" || echec "workshop-start 6 --from : messages/ non restauré"
[[ -x "$d6b/messages/mine.sh" ]] || echec "workshop-start --from : un script ne s'exécute plus après restauration"
# Sauvegarde abîmée : refusée avant toute écriture.
cp "$d6/my-work.zip" "$d6b/damaged.zip"; dd if=/dev/zero of="$d6b/damaged.zip" bs=1 seek=60 count=8 conv=notrunc status=none
code=0; sortie="$(cd "$d6b" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6b" workshop-start 6 --from damaged.zip 2>&1)" || code=$?
[[ $code == 1 ]] && grep -q "Download your save again" <<< "$sortie" || { echo "$sortie"; echec "workshop-start : sauvegarde abîmée non refusée"; }
# Atelier 6 : le MANIFEST et la sortie donnent workshop-start 6 ; les fichiers du dépôt ne sont pas gardés, et c'est dit.
d6c="$(mktemp -d)"; cp -r "$d6"/. "$d6c"/; rm -f "${d6c:?}"/*.zip
printf 'x\n' >> "$d6c/sheet.md"; printf 'x = 2\n' > "$d6c/tools/sorter.py"; printf -- '- saved\n' >> "$d6c/messages/test.md"
sortie="$(cd "$d6c" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6c" workshop-save)" || { echo "$sortie"; echec "workshop-save (fichiers du dépôt)"; }
grep -qF '! Changed but not saved: sheet.md, tools/sorter.py.' <<< "$sortie" || { echo "$sortie"; echec "workshop-save : fichiers du dépôt non signalés"; }
grep -qF 'workshop-start 6 --from my-work.zip' <<< "$sortie" || { echo "$sortie"; echec "workshop-save : commande de reprise de l'atelier 6 absente"; }
grep -qF 'workshop-start 6 --from my-work.zip' <<< "$(unzip -p "$d6c/my-work.zip" MANIFEST.md)" || echec "workshop-save : commande de reprise de l'atelier 6 absente du MANIFEST"
if unzip -Z1 "$d6c/my-work.zip" | grep -qxE 'sheet\.md|tools/sorter\.py'; then echec "workshop-save : fichier du dépôt dans le .zip"; fi
# Disque plein (ulimit) : l'ancienne sauvegarde ne bouge pas, et aucune restauration à moitié.
empreinte="$(sha256sum < "$d6c/my-work.zip")"; head -c 40000 /dev/urandom > "$d6c/messages/zz.bin"
code=0; sortie="$(cd "$d6c" && ulimit -f 8 && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6c" workshop-save 2>&1)" || code=$?
[[ $code == 1 ]] && grep -q "do not download a .zip yet" <<< "$sortie" || { echo "$sortie"; echec "workshop-save disque plein : message attendu"; }
[[ "$(sha256sum < "$d6c/my-work.zip")" == "$empreinte" ]] || echec "workshop-save disque plein : l'ancienne sauvegarde a bougé"
[[ -z "$(find "$d6c" -maxdepth 1 \( -name '.*.tmp' -o -name 'my-work-*.zip' \))" ]] || echec "workshop-save disque plein : fichiers laissés"
(cd "$d6c" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6c" workshop-save > /dev/null) || echec "workshop-save après disque plein"
d6d="$(mktemp -d)"; cp -r "$d6b"/. "$d6d"/; rm -f "${d6d:?}"/*.zip; cp "$d6c/my-work.zip" "$d6d/"; printf -- '- here\n' >> "$d6d/messages/test.md"
code=0; sortie="$(cd "$d6d" && ulimit -f 8 && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6d" workshop-start 6 --from my-work.zip 2>&1)" || code=$?
[[ $code == 1 ]] && grep -q "Nothing was restored" <<< "$sortie" || { echo "$sortie"; echec "workshop-start disque plein : message attendu"; }
grep -qx -- '- here' "$d6d/messages/test.md" && ! grep -qx -- '- saved' "$d6d/messages/test.md" && [[ ! -e "$d6d/messages/zz.bin" ]] || echec "workshop-start disque plein : restauration à moitié"
[[ -z "$(find "$d6d" -name '.workshop-start-*')" ]] || echec "workshop-start disque plein : fichier temporaire laissé"
# Atelier 6 sans git : messages/ est gardé, SETUP.md et sheet.md ne le sont pas, un démarrage simple n'écrit aucune sauvegarde.
d6n="$(mktemp -d)"; cp -r "$d6"/. "$d6n"/; rm -rf "${d6n:?}/.git" "${d6n:?}"/*.zip
(cd "$d6n" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6n" workshop-save > /dev/null) || echec "workshop-save sans git (atelier 6)"
grep -qx -- '- mine' <<< "$(unzip -p "$d6n/my-work.zip" messages/examples.md)" || echec "workshop-save sans git : messages/ absent du .zip"
if unzip -Z1 "$d6n/my-work.zip" | grep -qxE 'SETUP\.md|sheet\.md'; then echec "workshop-save sans git : page du dépôt dans le .zip"; fi
rm "$d6n/my-work.zip"; (cd "$d6n" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6n" workshop-start 6 > /dev/null) || echec "workshop-start 6 sans git"
[[ -z "$(find "$d6n" -maxdepth 1 -name '*.zip')" ]] || echec "workshop-start 6 sans git : sauvegarde inutile"
# MANIFEST.md : lu sur son premier Mio, compté dans la limite ; répertoire central abîmé, fin du fichier intacte : refus en clair.
/opt/workshop/venv/bin/python - "$d6b" <<'PY' || echec "sauvegardes de test non écrites"
import sys, zipfile
d = sys.argv[1]
top = "# Workshop save: x\n\nSaved on: 2026-10-30 10:00\nWorkshop: 6\n"
for name, size in (("long", 2 * 2**20), ("huge", 401 * 2**20)):
    with zipfile.ZipFile(f"{d}/{name}.zip", "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("MANIFEST.md", top + "x" * size)
        z.writestr("messages/from-long.md", "x\n")
raw = bytearray(open(f"{d}/my-work.zip", "rb").read()); start = zipfile.ZipFile(f"{d}/my-work.zip").start_dir
raw[start:start + 4] = b"XXXX"
open(f"{d}/directory.zip", "wb").write(raw)
PY
sortie="$(cd "$d6b" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6b" workshop-start 6 --from long.zip 2>&1)" || { echo "$sortie"; echec "workshop-start : long MANIFEST"; }
grep -qF 'saved on 2026-10-30 10:00' <<< "$sortie" || { echo "$sortie"; echec "workshop-start : date du MANIFEST non lue"; }
code=0; sortie="$(cd "$d6b" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6b" workshop-start 6 --from huge.zip 2>&1)" || code=$?
[[ $code == 1 ]] && grep -q "too large" <<< "$sortie" || { echo "$sortie"; echec "workshop-start : MANIFEST énorme non refusé"; }
code=0; sortie="$(cd "$d6b" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6b" workshop-start 6 --from directory.zip 2>&1)" || code=$?
[[ $code == 1 ]] && grep -q "Download your save again" <<< "$sortie" && ! grep -q "unexpected error" <<< "$sortie" || { echo "$sortie"; echec "workshop-start : .zip abîmé, refus en clair attendu"; }
# MANIFEST abîmé dans la sauvegarde déjà là : workshop-save garde l'ancienne et écrit la nouvelle (sinon plus aucune sauvegarde possible).
d6e="$(mktemp -d)"; cp -r "$d6"/. "$d6e"/; printf -- '- later\n' >> "$d6e/messages/test.md"
dd if=/dev/zero of="$d6e/my-work.zip" bs=1 seek=60 count=8 conv=notrunc status=none
sortie="$(cd "$d6e" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6e" workshop-save 2>&1)" || { echo "$sortie"; echec "workshop-save : MANIFEST abîmé dans l'ancienne sauvegarde"; }
grep -q "is kept as" <<< "$sortie" || { echo "$sortie"; echec "workshop-save : ancienne sauvegarde abîmée non gardée"; }
# Un dossier à la place d'un fichier : refus avant toute écriture, pas d'arrêt au milieu.
d6f="$(mktemp -d)"; cp -r "$d6b"/. "$d6f"/; git -C "$d6f" checkout -q -- messages; rm -f "$d6f/messages/mine.sh"; mkdir "$d6f/messages/mine.sh"
code=0; sortie="$(cd "$d6f" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6f" workshop-start 6 --from my-work.zip 2>&1)" || code=$?
[[ $code == 1 ]] && grep -q "a file and a folder have the same name" <<< "$sortie" || { echo "$sortie"; echec "workshop-start : dossier à la place d'un fichier, refus attendu"; }
if grep -qx -- '- mine' "$d6f/messages/examples.md"; then echec "workshop-start : restauration à moitié (dossier à la place d'un fichier)"; fi
rm -rf "$d6c" "$d6d" "$d6e" "$d6f" "$d6n"
code=0; sortie="$(cd "$d1" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d1" workshop-start 6 2>&1)" || code=$?
[[ $code == 1 ]] && grep -q "yal-workshop-finetune" <<< "$sortie" || { echo "$sortie"; echec "workshop-start 6 hors de son dépôt : renvoi attendu"; }
code=0; sortie="$(cd "$d6" && HOME="$(mktemp -d)" WORKSHOP_HOME="$d6" workshop-start 3 2>&1)" || code=$?
[[ $code == 1 ]] && grep -q "This repository is for workshop 6" <<< "$sortie" || { echo "$sortie"; echec "workshop-start 3 dans le dépôt de l'atelier 6 : refus attendu"; }
# Atelier 2 : sans clé, workshop-start 2 ne lance pas Open WebUI en arrière-plan (copie neuve, HOME vide).
copie2="$(mktemp -d)"; cp -r "$KIT/." "$copie2"; rm -rf "$copie2/.git"
sortie="$(cd "$copie2" && HOME="$(mktemp -d)" WORKSHOP_HOME="$copie2" workshop-start 2)" || { echo "$sortie"; echec "workshop-start 2"; }
grep -q "there is no key yet" <<< "$sortie" || { echo "$sortie"; echec "workshop-start 2 sans clé : message attendu workshop-login"; }
[[ ! -e "$copie2/.workshop/openwebui-start.log" ]] || echec "workshop-start 2 sans clé : Open WebUI lancé quand même"
(cd "$copie" && WORKSHOP_HOME="$copie" workshop-save > /dev/null) || echec "workshop-save"
[[ -f "$copie/my-work.zip" ]] || echec "workshop-save : my-work.zip absent"
rm -f "$copie/my-work.zip"
# Sauvegarde trop ancienne : MANIFEST avec « Workshop: n », avertissements de workshop-start.
dw="$(mktemp -d)"; cp -r "$KIT/." "$dw"; rm -rf "$dw/.git"; printf 'You are Testbot.\n' >> "$dw/AGENTS.md"
mkdir -p "$dw/.workshop"; echo '{"workshop": 1}' > "$dw/.workshop/last-start.json"
(cd "$dw" && WORKSHOP_HOME="$dw" workshop-save > /dev/null) || echec "workshop-save (atelier 1)"
unzip -p "$dw/my-work.zip" MANIFEST.md | grep -qx "Workshop: 1" || echec "workshop-save : « Workshop: 1 » absent du MANIFEST"
/opt/workshop/venv/bin/python - "$dw" <<'PY' || echec "copie de sauvegarde plus récente non écrite"
import sys, zipfile
d = sys.argv[1]; src = zipfile.ZipFile(f"{d}/my-work.zip")
with zipfile.ZipFile(f"{d}/my-work (1).zip", "w") as out:
    for n in src.namelist():
        data = src.read(n)
        if n == "MANIFEST.md":
            data = data.decode().replace("Saved on: ", "Saved on: 2099-01-01 10:00\nWas: ", 1).encode()
        out.writestr(n, data)
PY
sortie="$(cd "$dw" && HOME="$(mktemp -d)" WORKSHOP_HOME="$dw" workshop-start 4 --from my-work.zip 2>&1)" || true
grep -qF '! my-work (1).zip was saved later (on 2099-01-01 10:00)' <<< "$sortie" || { echo "$sortie"; echec "workshop-start : sauvegarde plus récente non signalée"; }
grep -qF '! This save is from workshop 1.' <<< "$sortie" || { echo "$sortie"; echec "workshop-start : sauvegarde de l'atelier 1 non signalée à l'atelier 4"; }
# openwebui (kit, sans comptes) : un port public arrête Open WebUI et refuse ; rien hors Codespace ni en mode classe.
openwebui check-private || echec "openwebui check-private hors Codespace : rien à refuser"
/opt/workshop/venv/bin/python - "$(command -v openwebui)" <<'PY' || echec "openwebui : port public non refusé"
import contextlib, importlib.machinery, importlib.util, io, sys
l = importlib.machinery.SourceFileLoader("owui", sys.argv[1]); m = importlib.util.module_from_spec(importlib.util.spec_from_loader("owui", l)); l.exec_module(m)
calls = []; m.docker = lambda *a, **k: calls.append(a); m.port_is_public = lambda: True
m.gh_set_visibility = lambda v: False; m.time.sleep = lambda s: None
err = io.StringIO()
with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
    try:
        m.refuse_public_port(interactive=False); raise AssertionError("no refusal")
    except SystemExit as e:
        assert e.code == 1
assert ("stop", m.CONTAINER) in calls and "because port 3000 is public" in err.getvalue(), (calls, err.getvalue())
assert "Forward a Port" in err.getvalue(), err.getvalue()
# GitHub lets gh make it private: Open WebUI keeps running.
states = iter([True, False]); calls.clear()
m.port_is_public = lambda: next(states); m.gh_set_visibility = lambda v: v == "private"
with contextlib.redirect_stdout(io.StringIO()):
    m.refuse_public_port(interactive=False)
assert not calls, calls
for state in (False, None):
    calls.clear(); m.port_is_public = lambda: state; m.refuse_public_port(); assert not calls
m.CLASS = True; m.port_is_public = lambda: True; m.refuse_public_port()
PY

etape "OpenCode : configuration de chaque mode (répétition à blanc, sans appel au modèle)"
oc() { WORKSHOP_ENGINE=opencode WORKSHOP_DRY_RUN=1 WORKSHOP_HOME="$copie" workshop "$1" -p hi; }
for m in bare A B C D E F; do
  oc "$m" > "/tmp/oc-$m.json" || echec "OpenCode, mode $m : la configuration n'est pas produite"
done
/opt/workshop/venv/bin/python - <<'PY' || echec "OpenCode : configuration d'un mode inattendue"
import json
def load(m): return json.load(open(f"/tmp/oc-{m}.json"))
for m in "bare A B C D E F".split():
    d = load(m); c = d["config"]; perms = c["agents"]["chatbot"]["permissions"]
    allowed = {p["action"] for p in perms if p["effect"] == "allow"}
    servers = set((c.get("mcp") or {}).get("servers") or {})
    assert d["env"]["OPENCODE_DISABLE_PROJECT_CONFIG"] == "1", m
    assert "sk-" not in json.dumps(c), f"{m}: key in the config"
    if m in ("bare", "A", "B"):
        assert perms == [{"action": "*", "resource": "*", "effect": "deny"}], f"{m}: tools"
    else:
        assert {"read", "grep", "skill"} <= allowed, f"{m}: search tools"
        # No shell command without asking: "cat *" would also let through "cat x > file" and
        # "cat ~/.workshop-key" (OpenCode matches the whole line). And never the key file.
        assert not [p for p in perms if p["action"] == "shell" and p["effect"] == "allow"], f"{m}: shell allowed"
        assert {"action": "read", "resource": "*workshop-key*", "effect": "deny"} in perms, f"{m}: key readable"
        # La clé est dans l'environnement d'OpenCode : /proc et /dev jamais, même sur approbation ; sudo jamais.
        for place in ("/proc", "/proc/*", "/dev", "/dev/*"):
            for action in ("read", "external_directory"):
                assert {"action": action, "resource": place, "effect": "deny"} in perms, f"{m}: {action} {place}"
        for line in ("*sudo*", "env", "*printenv*", "*environ*"):
            assert {"action": "shell", "resource": line, "effect": "deny"} in perms, f"{m}: shell {line}"
    assert c["providers"][next(iter(c["providers"]))]["settings"]["apiKey"] == "{env:WORKSHOP_OPENCODE_KEY}", f"{m}: apiKey"
    assert ("fire-danger" in servers) == (m in "DEF"), f"{m}: MCP fire-danger"
    assert ("time" in servers) == (m in "DEF"), f"{m}: MCP time"
    if m in "DEF":
        assert {"action": "time_*", "resource": "*", "effect": "allow"} in perms, f"{m}: time tools"
    assert ("graphify" in servers) == (m == "F"), f"{m}: MCP graphify"
print("OpenCode : bare/A/B sans outils, C+ recherche, D+ MCP (fire-danger, time), F graphify ; aucune clé dans la configuration")
PY
# Un lien vers l'extérieur du dossier : OpenCode ne démarre pas en C (read y lirait /proc/self/environ).
ln -s /proc/self/environ "$copie/inbox/lien-dehors.md"
code=0; oc C > /tmp/out 2>&1 || code=$?
{ [[ $code == 1 ]] && grep -q "leads outside it: inbox/lien-dehors.md" /tmp/out; } || { cat /tmp/out; echec "OpenCode : lien vers l'extérieur non refusé"; }
oc A > /dev/null || echec "OpenCode, mode A : sans outils, un lien ne gêne pas"
rm "$copie/inbox/lien-dehors.md"
WORKSHOP_WEATHER=1 oc D > /tmp/oc-weather.json || echec "OpenCode, WORKSHOP_WEATHER=1 : configuration non produite"
/opt/workshop/venv/bin/python - <<'PY' || echec "OpenCode, WORKSHOP_WEATHER=1 : configuration inattendue"
import json
c = json.load(open("/tmp/oc-weather.json"))["config"]
server = c["mcp"]["servers"]["open-meteo"]
assert server["environment"]["DOTENV_CONFIG_PATH"] == "/dev/null", server
perms = c["agents"]["chatbot"]["permissions"]
meteo = sorted(p["action"] for p in perms if p["action"].startswith("open-meteo") and p["effect"] == "allow")
assert meteo == ["open-meteo_geocoding", "open-meteo_weather_forecast"], meteo
print("OpenCode, météo : deux outils autorisés, .env ignoré")
PY

etape "Démarrage réel : outils, skills et serveur MCP annoncés par Claude Code"
verifie() {
  # Avec la fausse clé, claude finit en erreur : seule compte la description du démarrage.
  local sortie
  sortie="$(timeout 120 workshop "$1" -p hi --output-format stream-json --verbose < /dev/null 2>/dev/null || true)"
  printf '%s\n' "$sortie" | /opt/workshop/venv/bin/python -c '
import json, os, sys
mode, outils_attendus = sys.argv[1], int(sys.argv[2])
for ligne in sys.stdin:
    try: d = json.loads(ligne)
    except ValueError: continue
    if d.get("subtype") != "init": continue
    mcp = [s["name"] for s in d["mcp_servers"] if s["status"] == "connected"]
    skills = sorted(s for s in d["skills"] if s in ("ingest", "lint", "source-note", "summarize", "validate-summary"))
    print(mode, len(d["tools"]), "outils", mcp, skills)
    ok = len(d["tools"]) == outils_attendus
    curation = ["source-note", "summarize", "validate-summary"]
    if mode == "C": ok = ok and mcp == [] and skills == curation
    # disableBundledSkills: the skills bundled with Claude Code are not offered (they crowded out the
    # descriptions of the workshop skills).
    ok = ok and not {"dataviz", "deep-research", "workflow-authoring", "code-review"} & set(d["skills"])
    meteo = ["open-meteo"] if os.environ.get("WORKSHOP_WEATHER") == "1" else []
    if mode == "D": ok = ok and sorted(mcp) == sorted(["fire-danger", "time"] + meteo) and skills == curation
    if mode == "E": ok = ok and sorted(mcp) == ["fire-danger", "time"] and skills == sorted(curation + ["ingest", "lint"])
    if mode == "F": ok = ok and sorted(mcp) == ["fire-danger", "graphify", "time"] and skills == sorted(curation + ["ingest", "lint"]) \
        and not any("_prs" in t or "pr_impact" in t for t in d["tools"])
    sys.exit(0 if ok else 1)
sys.exit("pas d événement init")' "$1" "$2"
}
verifie bare 0 || echec "mode bare"
verifie A 0 || echec "mode A"
verifie C 5 || echec "mode C"
verifie D 9 || echec "mode D"
WORKSHOP_HOME="$copie" verifie E 9 || echec "mode E"
WORKSHOP_HOME="$copie" verifie F 16 || echec "mode F"
# Atelier 4, extension météo : deux outils d'Open-Meteo seulement (les 15 autres ne sont pas montrés).
WORKSHOP_WEATHER=1 verifie D 11 || echec "WORKSHOP_WEATHER=1 workshop D : 11 outils attendus"
sortie="$(WORKSHOP_WEATHER=1 timeout 120 workshop D -p hi --output-format stream-json --verbose < /dev/null 2>/dev/null || true)"
printf '%s\n' "$sortie" | /opt/workshop/venv/bin/python -c '
import json, sys
for ligne in sys.stdin:
    try: d = json.loads(ligne)
    except ValueError: continue
    if d.get("subtype") != "init": continue
    meteo = sorted(t for t in d["tools"] if t.startswith("mcp__open-meteo__"))
    connectes = [s["name"] for s in d["mcp_servers"] if s["status"] == "connected"]
    print("météo :", meteo)
    sys.exit(0 if meteo == ["mcp__open-meteo__geocoding", "mcp__open-meteo__weather_forecast"] and "open-meteo" in connectes else 1)
sys.exit("pas d événement init")' || echec "WORKSHOP_WEATHER=1 : outils d'Open-Meteo inattendus"
rm -rf "$copie"

rm -f "$HOME/.workshop-key" "$HOME/.claude/settings.json"
printf '\n✓ Smoke-test réussi\n'
