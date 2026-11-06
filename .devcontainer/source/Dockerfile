# Image du Codespace de l'atelier : tout s'installe ici, à la construction, et non dans une
# commande de cycle de vie rejouée à chaque création de Codespace. Publiée sur ghcr.io par
# .github/workflows/devcontainer-publish.yml (même mécanique que IUTInfoAix/IntroPython).
#
# Image de base épinglée sur Python 3.12 et Debian bookworm ; elle fournit l'utilisateur
# vscode, git, curl et sudo. Digest de l'index multi-architecture, celui de l'image 2026.10.40 (mêmes
# couches amd64 vérifiées le 2026-11-01) : à changer à la main pour suivre les correctifs de la base.
FROM mcr.microsoft.com/devcontainers/python:3.12-bookworm@sha256:5ff1ba19e3b9273b24ec101055172d0e75046bc9ec40780643c530d2df2c75e5

LABEL org.opencontainers.image.source="https://github.com/Youth-AI-Lab/yal-workshop-kit" \
      org.opencontainers.image.description="Youth AI Lab workshop: Claude Code, OpenCode, MCP server and workshop commands"

# Claude Code, version figée (claude-version). L'installateur officiel
# installe sous /root ; on ne garde que le binaire, dans /usr/local/bin, vérifié par sa somme SHA-256
# écrite ici (celle de .../claude-code-releases/2.1.311/manifest.json, canal stable, à reprendre si claude-version change).
COPY .devcontainer/claude-version /tmp/claude-version
RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
      amd64) sum=86dc1fcc69498159eaf15f446613e847010f9036bfbbdffd4c49350be8489ada ;; \
      arm64) sum=2e2496c9a8065df93acb0fca2d341f59a6b8777649b2e025ab8c9bcd5eef61f3 ;; \
      *) exit 1 ;; esac; \
    curl -fsSL https://claude.ai/install.sh | bash -s "$(cat /tmp/claude-version)"; \
    install -m 755 "$(readlink -f /root/.local/bin/claude)" /usr/local/bin/claude; \
    echo "$sum  /usr/local/bin/claude" | sha256sum -c -; \
    rm -rf /root/.local/share/claude /root/.local/bin/claude /root/.cache /tmp/claude-version

# OpenCode, second moteur de l'atelier (workshop-login --engine opencode), version figée elle aussi
# (opencode-version). Paquet npm @opencode/cli-<plateforme> pris
# directement sur le registre et vérifié par sa somme SHA-256 écrite ici (2.2.5, à reprendre si
# opencode-version change) ; on ne garde que le binaire (≈ 230 Mo), sans Node ni les quatre variantes
# qu'installerait npm.
COPY .devcontainer/opencode-version /tmp/opencode-version
RUN set -eu; v="$(cat /tmp/opencode-version)"; \
    case "$(dpkg --print-architecture)" in \
      amd64) p=linux-x64; sum=92690eee07a680d3cb760ca02ba43878de9eab1b4e5d5dfae8795518c53628f4 ;; \
      arm64) p=linux-arm64; sum=f8c5a82075fede9b5b044ed6c8a6d13ad807a7e62caea1cd0a878adef49eb053 ;; \
      *) exit 1 ;; esac; \
    curl -fsSL "https://registry.npmjs.org/@opencode/cli-$p/-/cli-$p-$v.tgz" -o /tmp/opencode.tgz; \
    echo "$sum  /tmp/opencode.tgz" | sha256sum -c -; \
    tar -xzf /tmp/opencode.tgz -C /tmp package/bin/opencode; \
    install -m 755 /tmp/package/bin/opencode /usr/local/bin/opencode; \
    rm -rf /tmp/opencode.tgz /tmp/package /tmp/opencode-version; \
    [ "$(opencode --version)" = "opencode v$v" ]; \
    rm -rf /root/.local/share/opencode /root/.local/state/opencode /root/.cache/opencode /root/.config/opencode
# Pas de mise à jour automatique, pas de catalogue de modèles téléchargé à chaque lancement (celui
# du binaire suffit), pas de modèles gratuits d'OpenCode Zen.
ENV OPENCODE_DISABLE_AUTOUPDATE=1 OPENCODE_DISABLE_MODELS_FETCH=1 OPENCODE_DISABLE_FREE_MODELS=1

# ripgrep : les outils grep et glob d'OpenCode en ont besoin. Sans rg sur le PATH, OpenCode le télécharge
# à la première recherche : grep et glob échouent hors ligne (« ripgrep execution failed », mesuré avec
# OpenCode 2.1.4), et replay le ferait à chaque lancement (XDG_DATA_HOME neuf). Archive officielle prise sur
# la page de la version et vérifiée par sa somme SHA-256 écrite ici (fichiers .sha256 de la 15.2.0, à
# reprendre si ripgrep-version change). musl : binaire statique, seule variante x86_64 de la page.
COPY .devcontainer/ripgrep-version /tmp/ripgrep-version
RUN set -eu; v="$(cat /tmp/ripgrep-version)"; \
    case "$(dpkg --print-architecture)" in \
      amd64) a=x86_64; sum=33e15bcf1624b25cdd2a55813a47a2f95dbe126268203e76aa6a585d1e7b149c ;; \
      arm64) a=aarch64; sum=800b1e7206afe799dfb5a6901f23147cfaabe0e52210538100f61e86e1740915 ;; \
      *) exit 1 ;; esac; \
    d="ripgrep-$v-$a-unknown-linux-musl"; \
    curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/$v/$d.tar.gz" -o /tmp/rg.tgz; \
    echo "$sum  /tmp/rg.tgz" | sha256sum -c -; \
    tar -xzf /tmp/rg.tgz -C /tmp "$d/rg"; \
    install -m 755 "/tmp/$d/rg" /usr/local/bin/rg; \
    rm -rf /tmp/rg.tgz "/tmp/$d" /tmp/ripgrep-version; \
    rg --version | head -1 | grep -q "^ripgrep $v "

# qrencode : `openwebui share open` (mode classe) affiche le lien en QR code à projeter.
RUN apt-get update \
    && apt-get install -y --no-install-recommends qrencode \
    && rm -rf /var/lib/apt/lists/*

# Environnement Python du serveur MCP et de graphify : toutes les dépendances sont figées et vérifiées
# par leur empreinte (mcp-kit.txt, produit comme mcp-time.txt à partir de mcp[cli], beautifulsoup4,
# markdownify, pypdf et graphifyy, le 2026-11-05, sans rien de publié après le 2026-11-01 : mcp 2.3.0,
# beautifulsoup4 4.15.0, markdownify 1.2.3, pypdf 6.21.4, graphifyy 0.9.100). Mod token-weather (jauge de contexte) : commit vérifié, le même contenu que dans cette image.
COPY .devcontainer/source/mcp-kit.txt /tmp/mcp-kit.txt
RUN set -eu; python3 -m venv /opt/workshop/venv; \
    /opt/workshop/venv/bin/pip install --no-cache-dir -q --no-deps --require-hashes -r /tmp/mcp-kit.txt; \
    /opt/workshop/venv/bin/pip check; \
    rm /tmp/mcp-kit.txt; \
    MOD=569c5283d9a0a7ee7938df85bb32e4f48cbb8c86; \
    git init -q /opt/workshop/claude-code-playground; \
    cd /opt/workshop/claude-code-playground; \
    git fetch -q --depth 1 https://github.com/anthropics/claude-code-playground.git "$MOD"; \
    git checkout -q FETCH_HEAD; \
    [ "$(git rev-parse HEAD)" = "$MOD" ]; \
    rm -rf .git; \
    chmod -R a+rX /opt/workshop

# Serveur MCP Time (atelier 4) : serveur de référence officiel (modelcontextprotocol/servers), sans
# réseau, dans son propre environnement pour ne pas déplacer la version de mcp du serveur du kit.
# Toutes les dépendances sont figées et vérifiées par leur empreinte (mcp-time.txt, produit par
# `uv pip compile --universal --generate-hashes --exclude-newer 2026-11-01` à partir de mcp-server-time,
# qui reste 2026.10.28 : la 2026.11.4 est sortie le 2026-11-04).
COPY .devcontainer/source/mcp-time.txt /tmp/mcp-time.txt
RUN python3 -m venv /opt/workshop/mcp-time \
    && /opt/workshop/mcp-time/bin/pip install --no-cache-dir -q --no-deps --require-hashes -r /tmp/mcp-time.txt \
    && /opt/workshop/mcp-time/bin/pip check \
    && rm /tmp/mcp-time.txt \
    && chmod -R a+rX /opt/workshop/mcp-time

# Serveur MCP Open-Meteo (atelier 4, extension : WORKSHOP_WEATHER=1 workshop D) : serveur
# communautaire (github.com/cmer81/open-meteo-mcp, MIT), construit depuis son tag v2.5.6 (commit
# vérifié) avec son package-lock.json (npm ci : chaque paquet vérifié par son empreinte), sans les
# scripts d'installation des dépendances. Node 24 LTS, archive officielle vérifiée par sa somme
# SHA-256 écrite ici ; on ne garde que le binaire node (npm, corepack et les en-têtes ne servent
# qu'à la construction). Le modèle ne voit que 2 des 17 outils (workshop, workshop-opencode).
RUN set -eu; NODE=v24.22.2; \
    case "$(dpkg --print-architecture)" in \
      amd64) a=x64; sum=48cc0e21e048790e54c0cf5749c2725005313d652651c40b7a21feb9697aaf75 ;; \
      arm64) a=arm64; sum=eb187837a2230d4047161ac0be008584e16b46f726e9c9490ee35dc6b17d9ba8 ;; \
      *) exit 1 ;; esac; \
    curl -fsSL "https://nodejs.org/dist/$NODE/node-$NODE-linux-$a.tar.xz" -o /tmp/node.tar.xz; \
    echo "$sum  /tmp/node.tar.xz" | sha256sum -c -; \
    mkdir /tmp/node && tar -xJf /tmp/node.tar.xz -C /tmp/node --strip-components=1; \
    install -D -m 755 /tmp/node/bin/node /opt/workshop/node/bin/node; \
    git clone -q --branch v2.5.6 --depth 1 https://github.com/cmer81/open-meteo-mcp /opt/workshop/open-meteo-mcp; \
    cd /opt/workshop/open-meteo-mcp; \
    [ "$(git rev-parse HEAD)" = f6db0b3eef5bcbbeb4b5874fed1505059339505a ]; \
    PATH="/tmp/node/bin:$PATH"; export npm_config_cache=/tmp/npm-cache; \
    npm ci --ignore-scripts --no-audit --no-fund --loglevel=error; \
    ./node_modules/.bin/tsc; \
    npm prune --omit=dev --ignore-scripts --no-audit --no-fund --loglevel=error; \
    rm -rf .git src tests evals scripts /tmp/node /tmp/node.tar.xz /tmp/npm-cache /root/.npm; \
    [ "$(/opt/workshop/node/bin/node -p 'require("./package.json").version')" = 2.5.6 ]; \
    chmod -R a+rX /opt/workshop/node /opt/workshop/open-meteo-mcp

# graphify (bloc F) ne doit jamais installer ni rafraîchir sa skill dans ~/.claude : elle
# s'ajouterait à tous les modes.
ENV GRAPHIFY_NO_AUTO_REFRESH=1

# Commandes de l'atelier.
COPY .devcontainer/bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/workshop /usr/local/bin/workshop-claude /usr/local/bin/workshop-opencode /usr/local/bin/replay \
    /usr/local/bin/workshop-login /usr/local/bin/corpus-add \
    /usr/local/bin/wiki-start /usr/local/bin/wiki-graph /usr/local/bin/wiki-explore \
    /usr/local/bin/chatbot-export /usr/local/bin/openwebui \
    /usr/local/bin/score /usr/local/bin/workshop-save /usr/local/bin/workshop-start /usr/local/bin/workshop-key

# Outil en direct du mode classe (guide Open WebUI, décision du 2026-11-06) : le code du serveur fire-danger vient
# de l'image seulement, jamais du dépôt ouvert ; fire-danger.json est le gabarit (TO BE COMPLETED) que le premier
# `openwebui start` copie dans mcp/ du dépôt s'il manque. Contexte de construction : kit/ (devcontainer.json source,
# "context": "../..").
COPY mcp/fire_danger_server.py mcp/fire-danger.json /opt/workshop/fire-danger/
RUN chmod 755 /opt/workshop/fire-danger && chmod 644 /opt/workshop/fire-danger/*

# Message d'accueil de chaque nouveau terminal. Un dépôt peut le remplacer par la variable
# WORKSHOP_WELCOME (remoteEnv de son devcontainer.json ; vide : aucun message) : le guide OpenCode,
# qui n'utilise pas workshop-login, le fait. Sinon, rappel neutre (sans « binôme ») tant que la clé
# n'est pas enregistrée : atelier, guide Open WebUI.
# La même ligne pour zsh (déjà dans l'image de base, avec oh-my-zsh), si quelqu'un le choisit.
RUN echo 'if [[ -n "${WORKSHOP_WELCOME+x}" ]]; then [[ -z "$WORKSHOP_WELCOME" ]] || echo "$WORKSHOP_WELCOME"; elif [[ ! -f "$HOME/.workshop-key" ]]; then echo "Welcome! First, save your API key: workshop-login"; fi' \
      | tee -a /etc/bash.bashrc >> /etc/zsh/zshrc
