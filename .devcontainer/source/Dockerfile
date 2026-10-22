# Image du Codespace de l'atelier : tout s'installe ici, à la construction, et non dans une
# commande de cycle de vie rejouée à chaque création de Codespace. Publiée sur ghcr.io par
# .github/workflows/devcontainer-publish.yml (même mécanique que IUTInfoAix/IntroPython).
#
# Image de base épinglée sur Python 3.12 et Debian bookworm ; elle fournit l'utilisateur
# vscode, git, curl et sudo.
FROM mcr.microsoft.com/devcontainers/python:3.12-bookworm

LABEL org.opencontainers.image.source="https://github.com/Youth-AI-Lab/yal-workshop-kit" \
      org.opencontainers.image.description="Youth AI Lab workshop: Claude Code, MCP server and workshop commands"

# Claude Code, version figée (même fichier que le script du VPS). L'installateur officiel
# installe sous /root ; on ne garde que le binaire, dans /usr/local/bin.
COPY .devcontainer/claude-version /tmp/claude-version
RUN curl -fsSL https://claude.ai/install.sh | bash -s "$(cat /tmp/claude-version)" \
    && install -m 755 "$(readlink -f /root/.local/bin/claude)" /usr/local/bin/claude \
    && rm -rf /root/.local/share/claude /root/.local/bin/claude /root/.cache /tmp/claude-version

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
RUN chmod 755 /usr/local/bin/workshop /usr/local/bin/replay /usr/local/bin/workshop-login /usr/local/bin/corpus-add \
    /usr/local/bin/wiki-start /usr/local/bin/wiki-graph /usr/local/bin/wiki-explore \
    /usr/local/bin/chatbot-export /usr/local/bin/openwebui

# Rappel dans chaque nouveau terminal tant que le binôme n'a pas enregistré sa clé.
RUN echo '[[ -f "$HOME/.workshop-key" ]] || echo "Welcome! First, save the API key of your pair: workshop-login"' \
      >> /etc/bash.bashrc
