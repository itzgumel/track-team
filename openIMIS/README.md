# openIMIS Developer Academy

A comprehensive, course-style architectural handbook for the
[openIMIS](https://openimis.org) open-source health financing platform, built as
a [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) documentation
site.

This handbook reverse-engineers and teaches the entire openIMIS ecosystem —
backend (Django + Graphene), frontend (React + Redux + Vite), the plugin/module
architecture, GraphQL, database design, Docker distribution, deployment,
security, FHIR, and more — as a structured course for experienced Django
engineers onboarding to the core team.

> **Disclaimer.** This is an independent, community-authored learning resource.
> It is not an official openIMIS publication. Facts are grounded in the public
> openIMIS repositories under <https://github.com/openimis> and the official
> wiki; where the source code is the ultimate authority, the handbook points you
> to the exact repository and file to read.

## Quick start

```bash
# 1. Create a virtual environment (Python 3.9+)
python -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Live-preview the site with hot reload
mkdocs serve
# open http://127.0.0.1:8000

# 4. Build a static site into ./site
mkdocs build
```

## Deploy to GitHub Pages

```bash
mkdocs gh-deploy --force
```

Or point any static host (Netlify, Cloudflare Pages, S3, Nginx) at the generated
`site/` directory.

## Structure

```
openIMIS/
├── mkdocs.yml            # Site configuration and navigation
├── requirements.txt      # Python build dependencies
└── docs/
    ├── index.md          # Course landing page
    ├── getting-started/  # Platform overview, terminology, dev setup
    ├── architecture/     # Backend, frontend, plugin system, request lifecycle
    ├── graphql/          # GraphQL from first principles
    ├── modules/          # Deep dives per business module
    ├── database/         # Schema, UUID strategy, soft delete, migrations
    ├── security/         # AuthN / AuthZ, JWT, permissions
    ├── docker/           # Docker distribution + deployment
    ├── configuration/    # Config system, env vars, localization
    ├── integrations/     # FHIR, DHIS2, payments, SMS/email
    ├── extending/        # How to build modules + full code walkthrough
    ├── workflow/         # Local dev, testing, CI/CD, releases
    ├── academy/          # 7-level progressive tutorial
    ├── critique/         # Architecture strengths, weaknesses, comparisons
    ├── best-practices/   # Standards, patterns, pitfalls
    └── reference/        # Glossary, troubleshooting, repository appendix
```
