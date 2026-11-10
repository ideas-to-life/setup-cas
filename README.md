# setup-cas

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Powered by uv](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/uv/main/assets/badge/v0.json)](https://github.com/astral-sh/uv)

Official public distribution and composite GitHub Action for the **Continuous Architecture System (CAS)** CLI (`cas`).

`ideas-to-life/setup-cas` provisions the `cas` CLI into an isolated tool environment in **under 5 seconds** (on warm runner cache) using [Astral `uv`](https://docs.astral.sh/uv/) and pre-built release wheels—with **zero private repository credential requirements** and **zero target virtual environment pollution**.

---

## Quick Start

### 1. GitHub Actions (`uses: ideas-to-life/setup-cas@main`)

Add `setup-cas` to any GitHub Actions workflow in your repository (inside or outside the `ideas-to-life` organization):

```yaml
steps:
  - name: Checkout Repository
    uses: actions/checkout@v4
    with:
      fetch-depth: 0

  - name: Set up CAS CLI
    uses: ideas-to-life/setup-cas@main

  - name: Run CAS Governance Gates
    run: |
      cas governance check-env --target-dir .
      cas governance lint --target-dir .
      cas governance verify-diff --target-dir .
      cas governance check-bands --target-dir .
      cas skills eval
```

### 2. Local Developer & Agent Installation (`curl`)

Install or upgrade `cas` globally on macOS or Linux into `~/.local/bin/cas` without modifying your project's `.venv`, `pyproject.toml`, or `requirements.txt`:

```bash
curl -fsSL https://raw.githubusercontent.com/ideas-to-life/setup-cas/main/install-cas.sh | bash
```

Verify installation:

```bash
cas --help
cas governance check-env --target-dir .
```

---

## Onboarding a New Repository

Once `cas` is installed locally, initialize the CAS governance substrate in your target repository:

```bash
cd /path/to/your-repo
cas bootstrap .
```

`cas bootstrap` non-destructively provisions:
- **Multi-Harness Agent Steering**: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, and `REVIEW.md`.
- **Canonical Governance Substrate (`.cas/`)**: Architectural rules, pattern catalogue (`invariants` and `anti_patterns`), SDLC profile (`.cas/sdlc-profile.yaml`), statistical control bands (`.cas/bands.yaml`), Fresh-Context Verifier subagent (`verifier.md`), and `PreToolUse` runtime protection hooks.
- **Turnkey CI/CD Workflows (`.github/workflows/`)**:
  - `cas-validate-sdd.yml` — Tier-1 deterministic PR validation gate.
  - `cas-skill-evals.yml` — Agent skill evaluation pipeline.
  - `cas-continuous-architecture.yml` — Tier-2 continuous architecture synthesis and `cas-brain/knowledge` synchronization.
- **Developer Helper Script**: `scripts/install-cas.sh`.

---

## Action Inputs

| Input | Description | Required | Default |
| :--- | :--- | :---: | :---: |
| `version` | Release tag, branch, or commit to install (`main`, `latest`, or `vX.Y.Z`) | `false` | `"main"` |
| `source` | Installation source (`auto`, `wheel`, `git`, or `local`) | `false` | `"auto"` |
| `cache` | Enable `uv` tool and binary caching on the runner | `false` | `"true"` |

### Pinning a Specific Version

```yaml
- name: Set up CAS CLI
  uses: ideas-to-life/setup-cas@main
  with:
    version: "v0.1.0"
```

---

## Standardized Repository Variables & Secrets

Deterministic PR gates (`lint`, `verify-diff`, `check-bands`, `skills eval`) run **100% offline with zero secrets**. To enable full Tier-2 Continuous Architecture synthesis and synchronization with the central knowledge brain (`cas-brain/knowledge`), configure the following in your repository's **Settings → Secrets and variables → Actions**:

### Repository Secrets

| Secret Name | Required | Purpose |
| :--- | :---: | :--- |
| `CAS_KNOWLEDGE_BRAIN` | **Yes** *(for Brain sync)* | Fine-grained GitHub PAT with read/write (`Contents: Read and write`) access to `cas-brain/knowledge`. *(Legacy `CAS_KNOWLEDGE_TOKEN` is also supported automatically).* |
| `OPENAI_API_KEY` | Conditional | API key for OpenAI reasoning/synthesis (required when `CAS_DEFAULT_PROVIDER=openai`). |
| `GEMINI_API_KEY` | Optional | API key for Google Gemini reasoning/synthesis (when `CAS_DEFAULT_PROVIDER=gemini`). |
| `HF_TOKEN` | Optional | Hugging Face Hub token for pattern discovery and embeddings. |
| `OTEL_EXPORTER_OTLP_HEADERS` | Optional | Authorization headers for OpenTelemetry OTLP collectors. |

> **Security Invariant (`INV-SEC-001`)**: Client repositories **never** require or store `CAS_PORTAL_TOKEN` or `CAS_PORTAL_REPO`. Pushing updated architectural models to `cas-brain/knowledge` automatically triggers centralized portal compilation and deployment to [cas.ideas-to-life.ai](https://cas.ideas-to-life.ai).

### Repository Variables

| Variable Name | Default | Purpose |
| :--- | :--- | :--- |
| `CAS_PROJECT` | `${{ github.event.repository.name }}` | Project namespace identifier matching `cas-knowledge/projects/<CAS_PROJECT>`. |
| `KNOWLEDGE_REPO_NAME` | `cas-brain/knowledge` | Central governed architecture knowledge repository slug. |
| `CAS_DEFAULT_PROVIDER` | `gemini` | Default LLM provider (`openai`, `gemini`, `huggingface`, `stub`). |
| `CAS_DEFAULT_MODEL` | `gemini-3.8-flash` | Default LLM model identifier. |
| `CAS_MAX_TOKENS` | `10000` | Maximum generation token limit. |
| `CAS_TEMPERATURE` | `1.0` | Sampling temperature for generative tasks. |

Run `cas governance check-env --target-dir .` at any time to inspect your local or CI environment readiness.

---

## License

Licensed under the [Apache License, Version 2.0](LICENSE).
