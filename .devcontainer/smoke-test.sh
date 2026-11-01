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
for c in workshop workshop-claude workshop-opencode replay workshop-login corpus-add wiki-start wiki-graph wiki-explore chatbot-export openwebui score workshop-save workshop-start; do command -v "$c" || echec "$c absent"; done

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
if workshop-login --key "not-a-key" 2>/dev/null; then echec "clé mal formée acceptée"; fi
[[ ! -f "$HOME/.workshop-key" ]] || echec "clé mal formée enregistrée"

etape "Une clé OpenRouter est refusée avec Claude Code (OpenRouter : OpenCode seulement)"
code=0; workshop-login --key sk-or-v1-SMOKETEST0000000000 2>/tmp/err || code=$?
[[ "$code" == 1 ]] || echec "clé OpenRouter avec Claude Code : code attendu 1, obtenu $code"
grep -q -- "--engine opencode" /tmp/err || echec "clé OpenRouter : message vers OpenCode attendu"
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
WORKSHOP_HOME="$copie" chatbot-export --name "Smoke test" > /dev/null || echec "chatbot-export"
/opt/workshop/venv/bin/python -c "
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1]); n = z.namelist()
assert 'instructions.md' in n and 'README.md' in n, n[:5]
assert '<!--' not in z.read('instructions.md').decode(), 'commentaires dans les instructions'
for p in ('summaries__', 'wiki__', 'corpus-text__'):
    assert any(x.startswith('knowledge/' + p) for x in n), p
# Ni catalogues ni fichiers du wiki qui ne sont pas des connaissances (comme workshop B et openwebui).
bad = [x for x in n if x.startswith('knowledge/') and x.split('__', 1)[1] in
       ('index.md', 'README.md', 'log.md', 'CLAUDE.md', 'AGENTS.md', 'graph.md') or '__00-' in x]
assert not bad, bad
print(len(n), 'fichiers dans le paquet')
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
# Le partage demande des comptes : refusé dans l'instance de l'atelier (sans comptes).
code=0; openwebui share open > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "Never make its port public" /tmp/err || { cat /tmp/err; echec "openwebui share hors mode classe : refus attendu"; }
OPENWEBUI_MODE=class openwebui help | grep -q "share open" || echec "openwebui help (mode classe)"
OPENWEBUI_MODE=class openwebui help | grep -q "openwebui import FILE" || echec "openwebui help (mode classe) : export et import"
command -v qrencode > /dev/null || echec "qrencode absent (QR code de share open)"

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
code=0; workshop-login --key sk-ant-api03-SMOKETEST0000000000 || code=$?
[[ "$code" == 2 ]] || echec "code attendu 2 (clé refusée), obtenu $code"
for v in CLAUDE_CODE_DISABLE_1M_CONTEXT CLAUDE_CODE_DISABLE_FAST_MODE; do
  grep -q "\"$v\": \"1\"" "$HOME/.claude/settings.json" || echec "settings.json : $v absent (jauge sur 1M ou mode rapide)"
done

etape "Une clé refusée ne remplace pas une clé enregistrée (faux curl)"
h=$(mktemp -d); b=$(mktemp -d); printf '#!/bin/sh\necho 401\n' > "$b/curl"; chmod +x "$b/curl"
printf 'sk-ant-OLD0000000000\n' > "$h/.workshop-key"
code=0; HOME="$h" PATH="$b:$PATH" workshop-login --key sk-ant-NEW0000000000 2>/tmp/err || code=$?
[[ "$code" == 2 ]] && grep -q "earlier key is kept" /tmp/err || { cat /tmp/err; echec "clé refusée : message attendu"; }
[[ "$(cat "$h/.workshop-key")" == sk-ant-OLD0000000000 ]] || echec "clé refusée : l'ancienne clé a été remplacée"
rm -rf "$h" "$b"

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
  for c in wc du tree diff git docker; do
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
    assert ("fire-danger" in servers) == (m in "DEF"), f"{m}: MCP fire-danger"
    assert ("time" in servers) == (m in "DEF"), f"{m}: MCP time"
    if m in "DEF":
        assert {"action": "time_*", "resource": "*", "effect": "allow"} in perms, f"{m}: time tools"
    assert ("graphify" in servers) == (m == "F"), f"{m}: MCP graphify"
print("OpenCode : bare/A/B sans outils, C+ recherche, D+ MCP (fire-danger, time), F graphify ; aucune clé dans la configuration")
PY
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
