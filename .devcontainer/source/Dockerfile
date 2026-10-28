# Image du Codespace de l'atelier : tout s'installe ici, à la construction, et non dans une
# commande de cycle de vie rejouée à chaque création de Codespace. Publiée sur ghcr.io par
# .github/workflows/devcontainer-publish.yml (même mécanique que IUTInfoAix/IntroPython).
#
# Image de base épinglée sur Python 3.12 et Debian bookworm ; elle fournit l'utilisateur
# vscode, git, curl et sudo.
FROM mcr.microsoft.com/devcontainers/python:3.12-bookworm

LABEL org.opencontainers.image.source="https://github.com/Youth-AI-Lab/yal-workshop-kit" \
      org.opencontainers.image.description="Youth AI Lab workshop: Claude Code, OpenCode, MCP server and workshop commands"

# Claude Code, version figée (même fichier que le script du VPS). L'installateur officiel
# installe sous /root ; on ne garde que le binaire, dans /usr/local/bin.
COPY .devcontainer/claude-version /tmp/claude-version
RUN curl -fsSL https://claude.ai/install.sh | bash -s "$(cat /tmp/claude-version)" \
    && install -m 755 "$(readlink -f /root/.local/bin/claude)" /usr/local/bin/claude \
    && rm -rf /root/.local/share/claude /root/.local/bin/claude /root/.cache /tmp/claude-version

# OpenCode, second moteur de l'atelier (workshop-login --engine opencode), version figée elle aussi
# (opencode-version, lu aussi par le script du VPS). Paquet npm @opencode/cli-<plateforme> pris
# directement sur le registre et vérifié (empreinte sha512 publiée par le registre) ; on ne garde
# que le binaire (≈ 230 Mo), sans Node ni les quatre variantes qu'installerait npm.
COPY .devcontainer/opencode-version /tmp/opencode-version
RUN set -eu; v="$(cat /tmp/opencode-version)"; \
    case "$(dpkg --print-architecture)" in amd64) p=linux-x64 ;; arm64) p=linux-arm64 ;; *) exit 1 ;; esac; \
    curl -fsSL "https://registry.npmjs.org/@opencode/cli-$p/$v" -o /tmp/opencode.json; \
    curl -fsSL "https://registry.npmjs.org/@opencode/cli-$p/-/cli-$p-$v.tgz" -o /tmp/opencode.tgz; \
    python3 -c 'import base64, hashlib, json, sys; a, h = json.load(open("/tmp/opencode.json"))["dist"]["integrity"].split("-", 1); sys.exit(a != "sha512" or base64.b64decode(h) != hashlib.sha512(open("/tmp/opencode.tgz", "rb").read()).digest())'; \
    tar -xzf /tmp/opencode.tgz -C /tmp package/bin/opencode; \
    install -m 755 /tmp/package/bin/opencode /usr/local/bin/opencode; \
    rm -rf /tmp/opencode.json /tmp/opencode.tgz /tmp/package /tmp/opencode-version; \
    [ "$(opencode --version)" = "opencode v$v" ]; \
    rm -rf /root/.local/share/opencode /root/.local/state/opencode /root/.cache/opencode /root/.config/opencode
# Pas de mise à jour automatique, pas de catalogue de modèles téléchargé à chaque lancement (celui
# du binaire suffit), pas de modèles gratuits d'OpenCode Zen.
ENV OPENCODE_DISABLE_AUTOUPDATE=1 OPENCODE_DISABLE_MODELS_FETCH=1 OPENCODE_DISABLE_FREE_MODELS=1

# qrencode : `openwebui share open` (mode classe) affiche le lien en QR code à projeter.
RUN apt-get update \
    && apt-get install -y --no-install-recommends qrencode \
    && rm -rf /var/lib/apt/lists/*

# Environnement Python du serveur MCP, et mod token-weather (jauge de contexte).
RUN python3 -m venv /opt/workshop/venv \
    && /opt/workshop/venv/bin/pip install --no-cache-dir -q "mcp[cli]>=2,<3" \
         "beautifulsoup4==4.12.3" "markdownify==0.13.1" "pypdf==5.4.0" "graphifyy==0.9.92" \
    && git clone -q --depth 1 https://github.com/anthropics/claude-code-playground.git \
         /opt/workshop/claude-code-playground \
    && rm -rf /opt/workshop/claude-code-playground/.git \
    && chmod -R a+rX /opt/workshop

# graphify (bloc F) ne doit jamais installer ni rafraîchir sa skill dans ~/.claude : elle
# s'ajouterait à tous les modes.
ENV GRAPHIFY_NO_AUTO_REFRESH=1

# Commandes de l'atelier.
COPY .devcontainer/bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/workshop /usr/local/bin/workshop-opencode /usr/local/bin/replay \
    /usr/local/bin/workshop-login /usr/local/bin/corpus-add \
    /usr/local/bin/wiki-start /usr/local/bin/wiki-graph /usr/local/bin/wiki-explore \
    /usr/local/bin/chatbot-export /usr/local/bin/openwebui \
    /usr/local/bin/score /usr/local/bin/workshop-save /usr/local/bin/workshop-start

# Message d'accueil de chaque nouveau terminal. Un dépôt peut le remplacer par la variable
# WORKSHOP_WELCOME (remoteEnv de son devcontainer.json ; vide : aucun message) : le guide OpenCode,
# qui n'utilise pas workshop-login, le fait. Sinon, rappel neutre (sans « binôme ») tant que la clé
# n'est pas enregistrée : atelier, guide Open WebUI.
# La même ligne pour zsh (déjà dans l'image de base, avec oh-my-zsh), si quelqu'un le choisit.
RUN echo 'if [[ -n "${WORKSHOP_WELCOME+x}" ]]; then [[ -z "$WORKSHOP_WELCOME" ]] || echo "$WORKSHOP_WELCOME"; elif [[ ! -f "$HOME/.workshop-key" ]]; then echo "Welcome! First, save your API key: workshop-login"; fi' \
      | tee -a /etc/bash.bashrc >> /etc/zsh/zshrc
