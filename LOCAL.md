# Run the workshop on your own computer (without a Codespace)

The usual way to run this kit is a **GitHub Codespace**: nothing to install, one link per pair
([README](README.md)). This page is the other way: the **same kit, on your own computer**, in a
container. You get the same image, the same commands (`workshop`, `replay`, `openwebui`…) and the
same results.

> ℹ️ **Note.** This path is for the facilitator or a technical partner, not for the participants
> during a session. It needs Docker and a few more steps than a Codespace. If a Codespace works
> for you, use it.

**When you might want it:**

- your network or your organisation blocks GitHub Codespaces;
- you have used up the free Codespace quota (60 hours a month on a 2-core machine);
- you want to keep your work without the 30-day deletion and the idle stop of a Codespace;
- you want to connect a **local model**, so that nothing leaves the machine (the separate
  *local AI* guide builds on this page).

> ⚠️ **Important.** Everything below the first container step is **identical** to the Codespace:
> the same `workshop-login`, the same `workshop bare`, the same blocks A to F. Only the setup
> differs. So read this page for the setup, then follow the [README](README.md) for the session.

---

## Part 1 — What you need

1. **A computer** with at least **8 GB of memory** and a few gigabytes of free disk (the workshop
   image is downloaded once; Open WebUI, if you use it, adds about 1.5 GB plus a first download of
   about 4.6 GB).
2. **Docker**, running:
   - **Windows or macOS:** install **Docker Desktop** (<https://www.docker.com/products/docker-desktop/>).
     Read its licence first: it is free for small organisations and for education, but a large
     organisation may need a paid plan. On Linux you can use **Docker Engine** instead, which is free.
   - **Linux:** install **Docker Engine** (<https://docs.docker.com/engine/install/>).
3. **Visual Studio Code**, the desktop application (<https://code.visualstudio.com/>), not the
   browser version.
4. The **Dev Containers** extension for VS Code (identifier `ms-vscode-remote.remote-containers`):
   in VS Code, open the Extensions panel, search for "Dev Containers", install it.
5. **git** (<https://git-scm.com/>), to download the kit.

> ℹ️ **Note — Apple Silicon Macs (M1, M2, M3…).** Since version `2026.10.27`, the workshop image
> exists in two versions: one for Intel/AMD computers (`amd64`) and one for ARM computers such as
> Apple Silicon Macs (`arm64`). Docker picks the right one by itself, with no emulation. Both
> versions pass the same automatic checks before they are published. Nobody has yet opened the kit
> on an Apple Silicon Mac with VS Code: if you are the first, tell the facilitator how it went.

---

## Part 2 — Open the kit in a container

1. **Download the kit.** In a terminal, in a folder where you keep your projects:

   ```bash
   git clone https://github.com/Youth-AI-Lab/yal-workshop-kit.git
   ```

2. **Open the folder in VS Code.** Start VS Code, then **File → Open Folder…**, and choose the
   `yal-workshop-kit` folder you just downloaded.

3. **Reopen in the container.** VS Code sees the kit's container configuration and shows, at the
   bottom right, a message **"Reopen in Container"**: click it. If you miss it, open the command
   palette (`Ctrl+Shift+P`, `Cmd+Shift+P` on a Mac), type **"Dev Containers: Reopen in Container"**
   and press Enter.

4. **Wait for the first build.** The first time, Docker **downloads the workshop image** (the same
   one every pair uses in a Codespace): several gigabytes, a few minutes on a normal connection.
   The next times, it reuses the image and opens in seconds.

**What you should see.** VS Code reopens, connected to the container: the **list of files** on the
left (`AGENTS.md`, `README.md`, `corpus`, `summaries`…) and a **terminal** at the bottom. The
small green corner at the bottom left reads **"Dev Container: Youth AI Lab…"**. From here on, the
terminal is the same as in a Codespace.

> ℹ️ **Note.** Your work stays in this folder on your computer. There is no idle stop and no
> 30-day deletion: you reopen the folder whenever you want.

---

## Part 3 — Save the key of your pair

Exactly as in the [README](README.md), Step 3:

```bash
workshop-login
```

Paste the key when asked (`Ctrl+Shift+V`, `Cmd+V` on a Mac), then press Enter. You should see
**"Key OK (Claude Code, Anthropic, model claude-sonnet-5-5)"**. For OpenCode and OpenRouter, see
the main README.

From here, follow the [README](README.md) for the session: `workshop bare`, then blocks A to F.

---

## Part 4 — What is the same, what changes

| | Codespace | On your computer |
|---|---|---|
| Image and commands | the same pinned image, `workshop`, `replay`, `openwebui`, all identical | the same |
| Where your work lives | in the Codespace (kept, but deleted after 30 days of no use) | in the folder on your computer, as long as you keep it |
| The model's key | the same `workshop-login`, the same model | the same |
| Idle stop | after 30 minutes (reopens in ~30 s) | none |
| A public link to share | the Codespace gives a `…app.github.dev` address | none: you share over your **local network** (Part 6) |
| Open WebUI | works in the Codespace (Docker is in the image) | needs Docker to run containers inside the container; see Part 5 |

---

## Part 5 — Open WebUI on your computer

The `openwebui` command (the RAG demo of block 3, and the after-session chatbots) runs **Open
WebUI in a container inside the workshop container**. In a Codespace this works out of the box. On
your computer it needs the container to be allowed to run Docker (a *privileged* container), which
depends on your Docker backend.

> ⚠️ **Important — not yet tested locally.** We have run `openwebui` in a Codespace (2026-10-23 and
> 2026-10-26), but **not yet** with Docker Desktop on Windows or macOS, nor with Docker Engine on
> Linux, from this container. Treat Part 5 as **to be confirmed**. If `openwebui start` fails on
> your machine, a working fallback is to run Open WebUI **directly on the computer** (outside the
> container), following Open WebUI's own instructions, and point it at the kit's knowledge export.
> This part will be completed once a partner has tested it on each system. **TO BE COMPLETED.**

When it works, the address is **`http://localhost:3000`** on the same computer (in a Codespace it
is a forwarded port instead).

---

## Part 6 — Sharing with a group, without a Codespace

A Codespace can give a public `…app.github.dev` link. On your computer there is none. To let a
group reach a chatbot you run (for example after the session, with `openwebui`):

- share it over your **local network**: give the group the computer's address on the network (for
  example `http://192.168.x.x:3000`) and, if you like, a QR code of that address;
- everyone must be on the **same network** as the computer;
- what touches the organisation's network (firewall, Wi-Fi for guests) is for whoever runs the IT:
  decide it with them.

> ℹ️ **Note.** This is the same idea as the *class* mode of the Open WebUI guide, without a
> Codespace. That guide has the group-facing parts (accounts, a banner, a notice for participants).

---

## What is not yet tested

Honest list, to complete as partners try it:

- **"Reopen in Container"** on **Windows** and **macOS** (we have run the container tooling on
  Linux, 2026-10-19, but not the VS Code flow on each system);
- **Open WebUI** (`openwebui`) with Docker Desktop and with Docker Engine, from the container
  (Part 5);
- the **`arm64` image** on a real Apple Silicon Mac (published since `2026.10.27` and checked
  automatically on an ARM machine, but not yet opened with VS Code on a Mac);
- the **exact disk and memory** a full run of the five blocks uses on a normal laptop;
- a **full pass of the five blocks** on Linux, Windows and macOS (at least one partner per system).
