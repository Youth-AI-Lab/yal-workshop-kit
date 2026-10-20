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
for c in workshop replay workshop-login; do command -v "$c" || echec "$c absent"; done

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

etape "Fausse clé Anthropic : enregistrée, testée, refusée"
code=0; workshop-login --key sk-ant-api03-SMOKETEST0000000000 || code=$?
[[ "$code" == 2 ]] || echec "code attendu 2 (clé refusée), obtenu $code"

etape "Réglages de chaque mode (répétition à blanc, sans appel au modèle)"
reglages() { WORKSHOP_DRY_RUN=1 workshop "$1" -p hi; }
a_la_suite() { printf '%s\n' "$1" | grep -A1 -xF -- "$2" | tail -1; }
for m in bare A B; do
  r="$(reglages "$m")"
  [[ "$(a_la_suite "$r" --tools)" == "" ]] || echec "mode $m : des outils sont actifs"
  grep -qxF -- --mcp-config <<< "$r" && echec "mode $m : serveur MCP chargé"
done
grep -q "^cwd=.*\.workshop-bare$" <<< "$(reglages bare)" || echec "mode bare : pas lancé hors du kit"
grep -qxF -- --append-system-prompt-file <<< "$(reglages A)" && echec "mode A : corpus préchargé"
fichier="$(a_la_suite "$(reglages B)" --append-system-prompt-file)"
attendus="$(find "$KIT/corpus" -name '[1-9]*.md' | wc -l)"
charges="$(grep -c '^## Document: corpus/' "$fichier")"
[[ "$charges" == "$attendus" ]] || echec "mode B : $charges documents chargés sur $attendus"
echo "B : $charges documents du corpus chargés au démarrage"
grep -qxF -- --mcp-config <<< "$(reglages C)" || echec "mode C : serveur MCP absent"
r="$(reglages W)"
[[ "$(a_la_suite "$r" --tools)" == "Read" ]] || echec "mode W : outils autres que Read"
[[ "$(a_la_suite "$r" --disallowedTools)" == "Read(./corpus/**)" ]] || echec "mode W : corpus/ non bloqué"
grep -qxF -- --mcp-config <<< "$r" && echec "mode W : serveur MCP chargé"
echo "W : lecture seule, corpus/ bloqué par une règle de permission"

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
    skills = sorted(s for s in d["skills"] if s in ("ingest", "lint", "source-note"))
    print(mode, len(d["tools"]), "outils", mcp, skills)
    ok = len(d["tools"]) == outils_attendus
    if mode == "C": ok = ok and mcp == ["fire-danger"] and skills == ["ingest", "lint", "source-note"]
    if mode == "W": ok = ok and d["tools"] == ["Read"] and mcp == []
    sys.exit(0 if ok else 1)
sys.exit("pas d événement init")' "$1" "$2"
}
verifie bare 0 || echec "mode bare"
verifie A 0 || echec "mode A"
verifie C 7 || echec "mode C"
verifie W 1 || echec "mode W"

rm -f "$HOME/.workshop-key" "$HOME/.claude/settings.json"
printf '\n✓ Smoke-test réussi\n'
