# Troubleshooting

A field guide to the problems openIMIS developers actually hit, organized by area.
Each area opens with a **symptom → likely cause → fix** table for fast triage,
followed by detailed callouts for the trickiest cases. Everything here is
practical; when a fix depends on your version or deployment, we say so and point
you at the authoritative file.

!!! tip "Triage method"
    Work outside-in: is it **setup/Docker** (the stack won't come up), **data/
    migrations** (the DB is wrong), **API/auth** (requests are rejected), **module/
    config** (behavior is wrong), or **frontend** (the UI is broken)? Jump to that
    section's table first, then the callouts.

!!! info "The three openIMIS-specific reflexes"
    Before deep debugging, check the three things newcomers get wrong most:
    (1) a **missing validity filter** on a versioned query, (2) expecting a
    **mutation to return the object** instead of a `clientMutationId`, and
    (3) a change made in the **assembly repo** that belongs in a **module** repo.
    See [Best Practices](../best-practices/index.md).

---

## Setup / install

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `ModuleNotFoundError` for a module package | Module in `openimis.json` but not installed | Regenerate `modules-requirements.txt` and `pip install -r` it, or `pip install -e ../openimis-be-<name>_py/` |
| Edits to a module don't take effect | Module installed from git, not editable | Reinstall as editable: `pip install -e ../openimis-be-<name>_py/` |
| `INSTALLED_APPS` missing your app | Module absent/typo'd in the manifest | Check the module entry in `openimis.json`; `settings.py` builds apps from it |
| Version conflicts on `pip install` | Pinned module refs disagree on a dep | Align the pins in `openimis.json`; recreate the virtualenv clean |
| Import errors only for one module | Module's own deps not installed | Install that module's requirements; check its `setup.py`/`pyproject` |

!!! danger "Common mistake: editing a module that was installed from git"
    If a module was installed from its pinned git ref (the default from
    `modules-requirements.txt`), your local edits to a sibling checkout have **no
    effect** — Python is importing the installed copy, not your working tree.
    Reinstall it editable (`pip install -e ../openimis-be-<name>_py/`) so the
    assembly imports your checkout directly. This is the single most common
    "why isn't my change doing anything?" during setup. See
    [Set Up a Dev Environment](../getting-started/setup.md).

---

## Docker

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `backend` exits immediately at boot | Migrations/config load failed | Read `backend` logs; the start script runs migrations + module config loads first |
| `backend` can't reach `db` | Started before Postgres was ready | Ensure startup order db → backend; add a healthcheck/wait-for-db |
| Frontend loads but `/graphql` 502s | `backend` down or gateway misrouted | Check backend health; verify the gateway proxies `/graphql` and `/api` |
| Env/secrets not applied | `.env` not passed to compose | Confirm `.env` path and variable names match compose expectations |
| OpenSearch service unhealthy | Memory limits / vm.max_map_count | Raise Docker memory; set `vm.max_map_count` if using `opensearch_reports` |
| Ports already in use | Host port collision | Change host port mappings in the compose file |

!!! warning "Startup order is load-bearing"
    The reference `openimis-dist_dkr` stack must come up **db → backend →
    frontend/gateway**. The `backend` container runs migrations and loads module
    configurations at start; if it races Postgres it dies. If your `backend`
    restarts in a loop, it is almost always (a) the database not ready, or (b) a
    migration/config failure — read the *first* error in its logs, not the last.
    See [Docker & Deployment](../docker/index.md).

??? note "Deep dive: reading a crash-looping backend"
    `docker compose logs backend` shows the story in order. Look for: a Postgres
    connection refusal (ordering/healthcheck issue) near the top; a Django
    migration traceback (schema/data issue — see the migrations section); or a
    module config load error (a bad `ModuleConfiguration` JSON or a module that
    fails to import). Fix the *earliest* failure; later ones are usually
    cascades. The container's entrypoint lives under `script/` in `openimis-be_py`.

---

## Database / migrations

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `relation "tbl..." does not exist` | Migrations not applied / wrong DB | Run migrations; confirm you're pointed at the right database |
| Query returns duplicate/old rows | **Missing validity filter** | Add `filter_validity()`; you're seeing historical versions |
| Update seems to lose the old value | Working as designed (new version) | Query current version with validity filter; history is intentional |
| Join returns wrong/empty rows | UUID vs. legacy integer key confusion | Confirm which key the join/API expects; check `legacy_id` |
| `column "camelCase" does not exist` | Legacy `db_column` mismatch in raw SQL | Use the ORM, or match the exact legacy column name/case |
| Migration conflict on merge | Two branches added migrations | Resolve/renumber migrations in the owning module; re-run |

!!! danger "Common mistake: the silent missing validity filter"
    A versioned model queried without a validity filter returns **every historical
    version** of every record. It looks fine in a fresh dev DB with little history,
    then returns duplicates and wrong counts in production. Make
    `filter_validity()` a reflex on every query against a `VersionedModel` /
    `HistoryModel`. This is both the top correctness bug and a top performance bug.
    See [Database](../database/index.md).

!!! info "Why the schema looks inconsistent"
    Old tables carry `tbl` prefixes and camelCase columns inherited from the legacy
    MSSQL IMIS system; newer modules (e.g. `individual`) use clean names. If a raw
    query fails on a column name, you are almost certainly fighting the legacy
    casing — prefer the ORM, which maps it for you via `db_column`. See the
    [Architecture Critique](../critique/index.md) on legacy DB debt.

---

## GraphQL / permissions errors

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `PermissionDenied` with a valid login | Role lacks the exact integer right | Grant the specific code; resolve it in the module's `apps.py` |
| Mutation "succeeds" but nothing changed | Read the wrong result — it's async | Poll the `MutationLog` by `clientMutationId` for real status/errors |
| Mutation returns no object | Working as designed (async pattern) | Query the created record afterward; use FE journalize |
| Unknown field / field from nowhere | Contributed by a module via inheritance | Trace the module list + MRO in `openimis/schema.py` |
| Empty list where data exists | Missing validity filter in resolver | Add the validity filter to the queryset |
| `totalCount`/`edgeCount` missing | Not using `ExtendedConnection` | Use core's `ExtendedConnection` for counts |

!!! danger "Common mistake: trusting the mutation's immediate response"
    An `OpenIMISMutation` returns a `clientMutationId`, **not** the created/updated
    object, and its immediate response does **not** reflect whether the work
    succeeded. Errors land in the `MutationLog`. If a write "did nothing," poll the
    log by that id and read its status and error fields — do not conclude success
    from a 200 response. See [GraphQL](../graphql/index.md).

??? note "Deep dive: debugging an integer permission failure"
    openIMIS authorizes with integer rights codes checked via
    `user.has_perms([<codes>])`, defined per module in `apps.py` (e.g.
    `gql_query_claims_perms = [111001]`). When a valid user is denied:
    (1) find the exact code the resolver/mutation requires in the owning module's
    `apps.py`; (2) confirm the user's role actually carries **that** integer, not a
    neighbor (`111002` vs `111001` is a classic off-by-one); (3) remember roles and
    their rights are DB-configured, so the running config may differ from source
    defaults. Never eyeball raw integer lists. See [Security](../security/index.md).

---

## Auth / JWT cookie issues

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Logged in but every request 401/403 | JWT cookie not sent | Ensure same origin via gateway; cookie is HttpOnly, check domain/path |
| Cookie set but dropped by browser | `Secure`/`SameSite`/domain mismatch | Serve over the gateway origin; align cookie flags with your scheme (http/https) |
| Works in dev, fails behind proxy | Gateway not forwarding cookies/headers | Configure the proxy to pass `Cookie`/auth headers to `/graphql` |
| Token expires mid-session | Expiry/refresh not handled | Rely on the FE refresh flow; check `django-graphql-jwt` expiry settings |
| External IdP login fails | OIDC/OAuth2 misconfiguration | Verify client id/secret, redirect URIs, and provider metadata |

!!! warning "The cross-origin cookie trap"
    openIMIS stores its JWT in an **HttpOnly cookie**. Cookies are origin-bound, so
    if the browser talks to the frontend on one origin and `/graphql` on another,
    the cookie may not be attached and every request looks unauthenticated. The
    reference deployment avoids this by putting frontend, `/api`, and `/graphql`
    behind **one gateway origin**. If you split them, you must get `SameSite`,
    `Secure`, `Domain`, and `Path` exactly right. When "login works but nothing is
    authorized," suspect the cookie before the credentials. See
    [Security](../security/index.md).

---

## Module loading / config

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Module's feature absent at runtime | Not in the manifest / not loaded | Add it to `openimis.json`; confirm it's in `INSTALLED_APPS` at boot |
| Config change ignored | Editing `DEFAULT_CFG` at runtime | Change the DB `ModuleConfiguration`; `DEFAULT_CFG` is only the default |
| Config change needs a restart | Config read at startup | Restart the backend so it reloads module configs |
| Permission code has no effect | Not wired into a role/config | Assign the code to a role; check `_configure_permissions()` |
| Another module's hook not firing | Bound to the wrong signal name | Match `register_service_signal` name exactly in `bind_service_signal` |

!!! info "DEFAULT_CFG is the default, not the truth"
    A module's `apps.py` `DEFAULT_CFG` is only the fallback. The **effective**
    configuration is the DB `ModuleConfiguration` overlaid on it at startup. If a
    config change "does nothing," you probably edited the code default while the DB
    holds an override — change the override, then restart so it reloads. See
    [Configuration](../configuration/index.md).

??? note "Deep dive: a service-signal hook that never runs"
    If binding to another module's service does nothing: (1) confirm the exact
    signal name string matches the producer's `register_service_signal(...)` —
    these are plain strings and a typo fails silently; (2) confirm your binding
    module is actually loaded (in the manifest) so its `bind_service_signal` call
    executes at startup; (3) confirm you bound the right phase (before vs. after);
    (4) verify the producing service method is the one actually invoked on your
    code path. See [Best Practices](../best-practices/index.md).

---

## Frontend build / Vite

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Module not appearing in the FE | Missing from FE `openimis.json` | Add it; `openimis-config-vite.js` regenerates `src/modules.js` |
| `src/modules.js` stale | Config script not re-run | Re-run the Vite config generation step; restart the dev server |
| `getRef`/`getContribs` returns nothing | Component not published / wrong name | Register it in the module config; match the published name exactly |
| Old CRA/CRACO instructions fail | Repo migrated to Vite | Use the Vite scripts, not the legacy CRA build |
| GraphQL call has no cache/devtools | There is no Apollo here | Use the custom `graphql`/`graphqlWithVariables` Redux layer + journalize |
| Stale data or infinite refetch | Bad effect dependency array | Fix `react-hooks/exhaustive-deps`; don't disable the rule |

!!! warning "There is no Apollo — stop looking for it"
    The frontend does **not** use Apollo Client. GraphQL runs through a custom Redux
    layer in FE core: `graphql` / `graphqlWithVariables` action creators plus a
    **journalize** polling helper for the async mutation status. If you are looking
    for an Apollo cache, devtools, or `useQuery`, you will not find them — learn the
    custom layer instead. See [Frontend Architecture](../architecture/frontend.md).

??? note "Deep dive: a component other modules can't find"
    The FE `ModulesManager` resolves components by published name
    (`modulesManager.getRef("insuree.InsureePicker")`) and injects UI at
    `contributions` points (`getContribs("insuree.MainMenu")`). If a lookup returns
    nothing: (1) the owning module must export it under that exact key in its config
    object (`refs`/`reference`, `contributions`); (2) that module must be in the FE
    manifest so its config is registered; (3) after adding it, regenerate
    `src/modules.js` via the Vite config script and restart. Name mismatches are
    the usual culprit. See [Frontend Architecture](../architecture/frontend.md).

---

## Performance

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| List views slow, query count huge | N+1 on relations | `select_related` (FK) / `prefetch_related` (reverse/M2M) |
| Queries slow as data grows | No index on validity/FK columns | Index `validity_from`/`validity_to` and join keys on big tables |
| Reports hammer the transactional DB | Analytics on the live store | Offload to OpenSearch via `opensearch_reports` |
| Write throughput stalls | Async worker/scheduler saturation | Scale workers; batch valuation; watch the `MutationLog` backlog |
| Whole-object fetches are heavy | Selecting all columns | `.only()` / `.values()` for list projections |

!!! tip "Find N+1 fast"
    Turn on Django's `django.db.backends` logger in development and watch the query
    count for one request. If you see one query per row for a related object, that's
    an N+1 — collapse it with `select_related`/`prefetch_related`. Do this before
    reaching for caching. See the performance section of
    [Best Practices](../best-practices/index.md).

---

## When you're truly stuck

!!! example "A repeatable escalation path"
    1. **Isolate the layer** using the triage method at the top.
    2. **Read the earliest error**, not the last — especially in Docker logs and
       migrations.
    3. **Check the three reflexes**: validity filter, async mutation polling, right
       repo/right key.
    4. **Find the source of truth**: the owning module's `apps.py` (config/perms),
       `models.py` (keys/validity), `services.py` (logic), or `openimis/schema.py`
       (where a GraphQL field comes from).
    5. **Confirm the manifest**: is the module even loaded? `openimis.json` +
       `INSTALLED_APPS` at boot.
    6. **Ask the community** with the isolated symptom, the earliest error, and what
       you already ruled out.

## Further reading

- [Best Practices](../best-practices/index.md) — how to avoid most of these before
  they happen.
- [Architecture Critique](../critique/index.md) — why several of these traps exist
  (legacy DB, dual keys, async mutations, no Apollo).
- [Glossary](glossary.md) — quick definitions for any term above.
- [Set Up a Dev Environment](../getting-started/setup.md) — the clean-install path.
- [Security](../security/index.md) and [Configuration](../configuration/index.md) —
  the auth and config subsystems in depth.
- Official openIMIS wiki: [openimis.atlassian.net/wiki](https://openimis.atlassian.net/wiki/).
