#!/usr/bin/env python3
"""The provider of the workshop tools, chosen by the saved key.

One key, one provider for every tool: sk-ant-... is Anthropic, sk-or-... is OpenRouter (with OpenCode as
the engine, and no Claude model unless someone names one). score and openwebui read the key here, and
every tool that calls a model directly goes through ask(). workshops/6-finetune/tools/sorter.py keeps a
short copy of ask(): it is not in the image.

ask() makes one request and never retries: the caller decides what to do with Reply.kind.
"""
import http.client
import json
import os
import urllib.error
import urllib.request
from collections import namedtuple
from pathlib import Path

KEY_FILE = Path.home() / ".workshop-key"
SETTINGS_FILE = Path.home() / ".workshop-opencode.json"  # written by workshop-login

# Tests only: another address for the API of both providers (a fake endpoint).
TEST_API = os.environ.get("WORKSHOP_PROVIDER_API")

# name: as in ~/.workshop-opencode.json. chat, small, judge: model ids as the provider's API knows them.
# small: the cheaper model of class mode, and ./sorter compare. judge: score.
# OpenRouter: chosen from measures (facilitator/workshops/measures/2026-11-01-openrouter-free), none of them Claude.
Provider = namedtuple("Provider", "name label prefix api chat small judge")
ANTHROPIC = Provider("anthropic", "Anthropic", "sk-ant-", TEST_API or "https://api.anthropic.com/v1",
                     os.environ.get("WORKSHOP_ANTHROPIC_MODEL", "claude-sonnet-5-5"),
                     os.environ.get("WORKSHOP_ANTHROPIC_SMALL_MODEL", "claude-haiku-5-5"),
                     os.environ.get("WORKSHOP_ANTHROPIC_SMALL_MODEL", "claude-haiku-5-5"))
OPENROUTER = Provider("openrouter", "OpenRouter", "sk-or-", TEST_API or "https://openrouter.ai/api/v1",
                      os.environ.get("WORKSHOP_OPENROUTER_MODEL", "deepseek/deepseek-v4-flash"),
                      os.environ.get("WORKSHOP_OPENROUTER_SMALL_MODEL", "mistralai/mistral-small-3.2-24b-instruct"),
                      os.environ.get("WORKSHOP_OPENROUTER_JUDGE_MODEL", "deepseek/deepseek-v4-flash"))
PROVIDERS = (ANTHROPIC, OPENROUTER)

# OpenRouter sends a question to any company that serves the model unless told otherwise. This rule leaves
# out the companies that may collect the data or train on it; some of the others may still keep questions
# for a time. A request that no company can serve then fails with 404 or 503.
ROUTING = {"data_collection": "deny"}

# workshop-login --europe, the route for young people: Mistral alone, in Europe, with zero data retention. Other
# companies are served in Europe too, but nothing concerning young people goes to a company whose terms were not read
# (facilitator/workshops/measures/2026-11-01-openrouter-free/data-policies-2026-11-01.json): Amazon and Azure were
# not, and Google's may exclude this use. A bare company name would not pin its regional endpoints.
# This chooses where the model runs, not where OpenRouter handles the request: only eu.openrouter.ai (Business and
# Enterprise plans) keeps that in Europe. Accounts, billing and security logs may stay in the US in all cases.
EUROPE_ENDPOINTS = ["mistral/eu"]

# text: the answer. tokens_in, tokens_out: as billed. cost: what the provider says the call cost, or None.
# stop: end, length, refusal or error. kind: None when the call worked, otherwise one of
#   key (refused), credits (no money left), limit (a spending limit or a quota), busy (try again later),
#   model (unknown model, or no company can serve it), refused (the request or the answer was blocked),
#   network, or other.
# message: the provider's words, for a person. retry_after: seconds, when the provider gives them.
Reply = namedtuple("Reply", "text tokens_in tokens_out cost stop kind message retry_after status")


def provider_of(key):
    """The provider of this key, or None."""
    for provider in PROVIDERS:
        if key.startswith(provider.prefix):
            return provider
    return None


def read_key():
    """The saved key, or "" when there is none."""
    try:
        return KEY_FILE.read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def saved_settings():
    try:
        saved = json.loads(SETTINGS_FILE.read_text(encoding="utf-8"))
        return saved if isinstance(saved, dict) else {}
    except (OSError, ValueError):
        return {}


def saved_window():
    """The window workshop-login saved for the model of this key, or None."""
    saved = saved_settings()
    provider = provider_of(read_key())
    if provider is None or saved.get("provider") != provider.name:
        return None
    try:
        return int(saved.get("context") or 0) or None
    except (TypeError, ValueError):
        return None


def europe():
    """True after workshop-login --europe."""
    return saved_settings().get("europe") is True


def routing():
    """What every OpenRouter request sends in "provider"."""
    if europe():
        return dict(ROUTING, zdr=True, only=EUROPE_ENDPOINTS, allow_fallbacks=False)
    return ROUTING


def chat_model(provider):
    """The model id chosen by workshop-login for this provider, as its API knows it."""
    saved = saved_settings()
    model = str(saved.get("model") or "")
    if saved.get("provider") == provider.name and model.startswith(provider.name + "/"):
        return model.split("/", 1)[1]
    return provider.chat


def _kind(status, message):
    """What an HTTP error means for the person. 403 is not always the key on OpenRouter."""
    text = message.lower()
    if status == 401:
        return "key"
    if status == 402:
        return "credits"
    if status == 403:
        if "limit" in text or "budget" in text or "guardrail" in text:
            return "limit"
        return "refused" if "moderat" in text or "flagged" in text else "key"
    if status == 404:
        return "model"
    if status == 429:
        return "busy"
    if status in (408, 500, 502, 503, 504, 524, 529):
        return "model" if "no available" in text or "no endpoints" in text else "busy"
    return "other"


def error_kind(status, message):
    """Reply.kind for an HTTP error that did not come through ask(): OpenCode's error events."""
    return _kind(status, message)


def _retry_after(headers):
    try:
        return max(0.0, float(headers.get("retry-after")))
    except (TypeError, ValueError, AttributeError):  # missing, or a date
        return None


def _failed(kind, message, status=None, retry_after=None):
    return Reply("", 0, 0, None, "error", kind, message, retry_after, status)


def _count(usage, *names):
    """The sum of these fields of usage. A field can be missing, or null."""
    values = [usage.get(name) for name in names]
    return sum(value for value in values if isinstance(value, (int, float)))


def _request_anthropic(provider, key, system, user, model, max_tokens, effort):
    body = {"model": model, "max_tokens": max_tokens, "system": system,
            "messages": [{"role": "user", "content": user}]}
    if effort == "none":
        body["thinking"] = {"type": "disabled"}
    elif effort:
        body["output_config"] = {"effort": effort}
    return f"{provider.api}/messages", body, {"x-api-key": key, "anthropic-version": "2023-06-01"}


def _request_openrouter(provider, key, system, user, model, max_tokens, effort):
    # max_tokens is deprecated there, and some companies refuse less than 16.
    body = {"model": model, "max_completion_tokens": max(max_tokens, 16), "provider": routing(),
            "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}]}
    if effort:
        body["reasoning"] = {"effort": effort}
    return f"{provider.api}/chat/completions", body, {"Authorization": f"Bearer {key}"}


def _read_anthropic(data):
    usage = data.get("usage") or {}
    tokens_in = _count(usage, "input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")
    text = "".join(b.get("text", "") for b in data.get("content") or [] if b.get("type") == "text")
    stop = {"refusal": "refusal", "max_tokens": "length"}.get(data.get("stop_reason"), "end")
    return Reply(text, tokens_in, _count(usage, "output_tokens"), None, stop,
                 "refused" if stop == "refusal" else None, "", None, 200)


def _read_openrouter(data):
    # OpenRouter can answer 200 with an error, in the body or in the choice: check both first.
    choice = (data.get("choices") or [{}])[0]
    finish = choice.get("finish_reason")
    error = data.get("error") or choice.get("error")
    if finish == "error" and not error:     # whatever text came is a piece of an answer, not an answer
        error = "it stopped before the end of the answer"
    usage = data.get("usage") or {}
    tokens = (_count(usage, "prompt_tokens"), _count(usage, "completion_tokens"))
    cost = usage.get("cost")
    if error:
        message = str(error.get("message") or error) if isinstance(error, dict) else str(error)
        code = error.get("code") if isinstance(error, dict) else None
        return Reply("", *tokens, cost, "error", _kind(code if isinstance(code, int) else 502, message), message,
                     None, code if isinstance(code, int) else 200)
    content = (choice.get("message") or {}).get("content")
    if isinstance(content, list):
        content = "".join(b.get("text", "") for b in content if isinstance(b, dict))
    if finish == "content_filter" or (choice.get("message") or {}).get("refusal"):
        return Reply(content or "", *tokens, cost, "refusal", "refused", "the provider blocked this text", None, 200)
    if finish == "length":
        return Reply(content or "", *tokens, cost, "length", None, "", None, 200)
    return Reply(content or "", *tokens, cost, "end", None, "", None, 200)


def ask(key, system, user, model=None, max_tokens=1024, effort=None, url=None, timeout=90):
    """One request to the provider of this key. Never raises: read Reply.kind.

    effort: None (the model's default), "none" (no thinking before the answer) or "low".
    url: another address for the request (a fake endpoint in the tests)."""
    provider = provider_of(key)
    if provider is None:
        return _failed("key", "this key is neither Anthropic (sk-ant-) nor OpenRouter (sk-or-)")
    build = _request_openrouter if provider is OPENROUTER else _request_anthropic
    read = _read_openrouter if provider is OPENROUTER else _read_anthropic
    address, body, headers = build(provider, key, system, user, model or provider.small, max_tokens, effort)
    request = urllib.request.Request(url or address, data=json.dumps(body).encode("utf-8"),
                                     headers=dict(headers, **{"content-type": "application/json"}))
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            data = json.load(response)
        if not isinstance(data, dict):
            raise ValueError("the reply is not a JSON object")
    except urllib.error.HTTPError as e:
        try:
            detail = json.load(e).get("error") or {}
            message = str((detail.get("message") or "") if isinstance(detail, dict) else detail)
        except (ValueError, AttributeError, OSError, http.client.HTTPException):  # a body cut in the middle
            message = ""
        return _failed(_kind(e.code, message), message, e.code, _retry_after(e.headers))
    except (urllib.error.URLError, OSError, ValueError, http.client.HTTPException) as e:
        return _failed("network", str(getattr(e, "reason", e)))
    try:
        return read(data)
    except (AttributeError, IndexError, KeyError, TypeError, ValueError):  # a 200 with a body of another shape
        return _failed("other", "the provider's reply could not be read", 200)
