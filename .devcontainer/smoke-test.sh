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
for c in workshop replay workshop-login corpus-add wiki-start wiki-graph wiki-explore chatbot-export openwebui score workshop-save workshop-start; do command -v "$c" || echec "$c absent"; done

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

etape "OpenCode à la version figée (second moteur)"
attendu="$(cat "$KIT/.devcontainer/opencode-version")"
opencode --version
[[ "$(opencode --version)" == "opencode v$attendu" ]] || echec "OpenCode : version attendue $attendu"
command -v workshop-opencode || echec "workshop-opencode absent"

etape "Mod token-weather présent"
[[ -d /opt/workshop/claude-code-playground/claude-code/mods/token-weather ]] || echec "mod absent"

etape "Sans clé, workshop le dit"
rm -f "$HOME/.workshop-key" "$HOME/.claude/settings.json"
if workshop bare -p hi 2>/tmp/err; then echec "workshop a démarré sans clé"; fi
grep -q workshop-login /tmp/err || echec "message attendu : workshop-login"

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
print(len(n), 'fichiers dans le paquet')
" "$copie/smoke-test.zip" || echec "chatbot-export : paquet incomplet"

etape "openwebui : Docker fonctionne dans le conteneur, la commande demande la clé d'abord"
# Pas de téléchargement d'Open WebUI ici (4,6 Go) : le démarrage réel est vérifié à la main
# dans un Codespace (facilitator/SETUP.md).
docker info > /dev/null || echec "Docker ne répond pas (fonctionnalité docker-in-docker)"
openwebui help | grep -q "openwebui start" || echec "openwebui help"
code=0; openwebui start > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "workshop-login" /tmp/err || { cat /tmp/err; echec "openwebui sans clé : message attendu workshop-login"; }
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

etape "Réglages de chaque mode (répétition à blanc, sans appel au modèle)"
grep -q "CLAUDE_CODE_AUTO_CONNECT_IDE=false" "$(command -v workshop)" || echec "workshop : lien avec VS Code non coupé (outils et sélection envoyés au modèle)"
grep -q "CLAUDE_CODE_DISABLE_AUTO_MEMORY=1" "$(command -v workshop)" || echec "workshop : mémoire automatique active (replay non indépendant)"
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
score --help > /dev/null || echec "score --help"
code=0; WORKSHOP_HOME="$copie" score A > /tmp/err 2>&1 || code=$?
[[ $code -ne 0 ]] && grep -q "replay A" /tmp/err || { cat /tmp/err; echec "score sans réponses : message attendu replay A"; }
code=0; workshop-start > /dev/null 2>&1 || code=$?
[[ $code == 2 ]] || echec "workshop-start sans numéro : code 2 attendu, obtenu $code"
(cd "$copie" && WORKSHOP_HOME="$copie" workshop-save > /dev/null) || echec "workshop-save"
[[ -f "$copie/my-work.zip" ]] || echec "workshop-save : my-work.zip absent"
rm -f "$copie/my-work.zip"

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
    assert ("graphify" in servers) == (m == "F"), f"{m}: MCP graphify"
print("OpenCode : bare/A/B sans outils, C+ recherche, D+ MCP, F graphify ; aucune clé dans la configuration")
PY

etape "Démarrage réel : outils, skills et serveur MCP annoncés par Claude Code"
verifie() {
  # Avec la fausse clé, claude finit en erreur : seule compte la description du démarrage.
  local sortie
  sortie="$(timeout 120 workshop "$1" -p hi --output-format stream-json --verbose < /dev/null 2>/dev/null || true)"
  printf '%s\n' "$sortie" | /opt/workshop/venv/bin/python -c '
import json, sys
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
    if mode == "D": ok = ok and mcp == ["fire-danger"] and skills == curation
    if mode == "E": ok = ok and mcp == ["fire-danger"] and skills == sorted(curation + ["ingest", "lint"])
    if mode == "F": ok = ok and sorted(mcp) == ["fire-danger", "graphify"] and skills == sorted(curation + ["ingest", "lint"]) \
        and not any("_prs" in t or "pr_impact" in t for t in d["tools"])
    sys.exit(0 if ok else 1)
sys.exit("pas d événement init")' "$1" "$2"
}
verifie bare 0 || echec "mode bare"
verifie A 0 || echec "mode A"
verifie C 5 || echec "mode C"
verifie D 7 || echec "mode D"
WORKSHOP_HOME="$copie" verifie E 7 || echec "mode E"
WORKSHOP_HOME="$copie" verifie F 14 || echec "mode F"
rm -rf "$copie"

rm -f "$HOME/.workshop-key" "$HOME/.claude/settings.json"
printf '\n✓ Smoke-test réussi\n'
