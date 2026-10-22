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
for c in workshop replay workshop-login corpus-add wiki-start wiki-graph wiki-explore chatbot-export openwebui; do command -v "$c" || echec "$c absent"; done

etape "Serveur MCP importable avec l'environnement de l'image"
(cd "$KIT/mcp" && /opt/workshop/venv/bin/python -c "import fire_danger_server as s; print(s.territories().splitlines()[0])") \
  || echec "le serveur MCP ne s'importe pas"

etape "Mod token-weather présent"
[[ -d /opt/workshop/claude-code-playground/claude-code/mods/token-weather ]] || echec "mod absent"

etape "Sans clé, workshop le dit"
rm -f "$HOME/.workshop-key" "$HOME/.claude/settings.json"
if workshop bare -p hi 2>/tmp/err; then echec "workshop a démarré sans clé"; fi
grep -q workshop-login /tmp/err || echec "message attendu : workshop-login"

etape "Une clé mal formée est refusée sans rien écrire"
if workshop-login --key "not-a-key" 2>/dev/null; then echec "clé mal formée acceptée"; fi
[[ ! -f "$HOME/.workshop-key" ]] || echec "clé mal formée enregistrée"

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
