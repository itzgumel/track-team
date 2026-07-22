# Glossary

A single alphabetized reference for openIMIS's domain and platform vocabulary.
Keep it open in a second tab while you read the rest of the handbook — most terms
here get a full chapter elsewhere, and each entry links to it where useful.

!!! tip "How to use this page"
    Definitions are one to three sentences: enough to unblock you, not a
    substitute for the chapter. Where a term has a home, follow the link. Terms are
    grouped by first letter; use your browser's find (`Ctrl/Cmd-F`) for a fast jump.

!!! info "Two vocabularies in one platform"
    openIMIS mixes a **domain** vocabulary (insuree, policy, claim, contribution —
    the language of health financing) with a **platform** vocabulary (module,
    manifest, service signal, `MutationLog` — the language of the architecture).
    This glossary interleaves both; the [Terminology Primer](../getting-started/terminology.md)
    teaches the essential subset narratively.

---

## A

AppConfig
: A module's Django `AppConfig` subclass, defined in its `apps.py` (e.g.
  `class CoreConfig(AppConfig)`). In openIMIS it does more than standard Django: it
  holds the module's `DEFAULT_CFG`, often a `_configure_permissions()` method, and
  reads runtime configuration from the database at startup. See
  [Backend Deep Dive](../architecture/backend.md).

Assembly repo
: A deployable repository that contains almost no business logic — only a manifest
  plus wiring — and assembles many module repositories into one running
  application. openIMIS has two: `openimis-be_py` (backend) and `openimis-fe_js`
  (frontend). See [Architecture Overview](../architecture/overview.md).

async_mutate
: The method a subclass of `OpenIMISMutation` implements to do a mutation's actual
  work. It runs the business logic (via a service), and the framework wraps it in
  the `MutationLog` audit + `clientMutationId` polling machinery. See
  [GraphQL](../graphql/index.md).

Audit
: The property, pervasive in openIMIS, that every write leaves a durable trace.
  Realized primarily through the `MutationLog` (every mutation) and temporal
  versioning (every business record's history). See [Security](../security/index.md).

## B

Base models
: The reusable model classes core provides so every module gets consistent
  behavior: `HistoryModel`, `HistoryBusinessModel`, `VersionedModel`, `UUIDModel`.
  New entities inherit the right base for temporal versioning, UUIDs, `legacy_id`,
  and `json_ext`. See [The Core Module](../modules/core.md).

bind_service_signal
: The core function a module calls to hook logic *before* or *after* another
  module's service method, without importing it. The consumer half of the
  service-signal extension seam (see `register_service_signal`). See
  [Best Practices](../best-practices/index.md).

## C

Calculation rule
: A pluggable pricing/valuation rule, registered via signals through
  `openimis-be-calculation_py` and implemented in `calcrule_*` modules. Used to
  value contributions, capitation, third-party payment, and claims. See
  [Calculation Rules](../modules/calculation.md).

Capitation
: A provider-payment method in which a health facility is paid a fixed amount per
  enrolled person per period, rather than per service delivered. In openIMIS it is
  computed by a calculation rule. See [Calculation Rules](../modules/calculation.md).

Claim
: A record that a health facility delivered services/items to an insuree under a
  policy, submitted for adjudication and payment. Valued via calculation rules and
  paid through the payment/invoice modules. Table lives in the `claim` module. See
  [Claim](../modules/claim.md).

ClaimAdmin (Claim Administrator)
: The actor at a health facility responsible for submitting and managing claims.
  A domain role distinct from a system permission. See [Claim](../modules/claim.md).

clientMutationId
: The identifier an `OpenIMISMutation` returns immediately instead of the created
  object. The client polls the `MutationLog` by this id to learn when the async
  work finished and whether it succeeded. See [GraphQL](../graphql/index.md).

Config over fork
: openIMIS's guiding customization principle: change *which* modules run (the
  manifest) or *how* a module behaves (its config), never fork core. See
  [Configuration](../configuration/index.md) and the
  [Architecture Critique](../critique/index.md).

Contribution
: A premium payment recorded against a policy — the money an insuree (or a payer on
  their behalf) pays for coverage. Distinct from a *payment*, which is money
  openIMIS pays *out* to providers. Lives in the `contribution` module. See
  [Contribution & Payment](../modules/payment.md).

Contributions (frontend)
: A **different** meaning from the domain term above: on the frontend, a module's
  config object exposes a `contributions` map of **named extension points** (e.g.
  `"insuree.MainMenu"`, `"core.AppBar"`) into which other modules inject
  components. The FE analogue of the backend service-signal seam. See
  [Frontend Architecture](../architecture/frontend.md).

Core module
: `openimis-be-core_py` — the shared framework every other module depends on. It
  provides base models, the custom `User`, Graphene helpers, `OpenIMISMutation`,
  service signals, the scheduler, and audit. See [The Core Module](../modules/core.md).

## D

DEFAULT_CFG
: The Python dict in a module's `apps.py` holding its default configuration
  (feature flags, business parameters, permission code assignments). Overlaid at
  startup by a per-module JSON stored in the DB (`ModuleConfiguration`), enabling
  reconfiguration without code changes. See [Configuration](../configuration/index.md).

DHIS2
: District Health Information Software 2 — the widely used open-source aggregate
  health-data / HMIS platform. openIMIS pushes aggregate data to it via
  `openimis-be-dhis2_etl_py`. A complementary system, not a competitor. See
  [Integrations](../integrations/index.md).

Digital Public Good (DPG)
: An open-source solution that adheres to the DGPA standard (open licensing, privacy,
  standards, no harm) and advances the SDGs. openIMIS is a recognized DPG, governed
  by the openIMIS Initiative. See the [home page](../index.md).

Distribution repo
: `openimis-dist_dkr` — the docker-compose-based repository that ties the backend,
  frontend, database, and gateway into a runnable deployment. See
  [Docker & Deployment](../docker/index.md).

Dual keys
: openIMIS's coexistence of legacy integer primary keys and added UUIDs on many
  models (the integer preserved as `legacy_id`). A consequence of the MSSQL→
  PostgreSQL migration. See [Database](../database/index.md) and the
  [Architecture Critique](../critique/index.md).

## E

Enrolment Officer
: The field actor who enrolls families/insurees into policies and collects
  contributions. Modeled via `Officer` and linked to the openIMIS `User`. A core
  domain role in community-based schemes. See [Insuree](../modules/insuree.md).

ExtendedConnection
: A core Graphene helper that extends the standard Relay connection with
  `totalCount` and `edgeCount`, so paginated GraphQL lists report their sizes. See
  [GraphQL](../graphql/index.md).

Extension point
: Any named seam where a module can attach behavior without modifying the target:
  backend **service signals** and the frontend **`contributions`** map are the two
  primary kinds. See [Extending openIMIS](../extending/index.md).

## F

Family
: A grouping of insurees (typically a household) that holds policies in
  community-based insurance. The head of family and members are insurees. Lives in
  the `insuree` module. See [Insuree](../modules/insuree.md).

FHIR R4
: Fast Healthcare Interoperability Resources, Release 4 — the HL7 standard for
  exchanging health data. `openimis-be-api_fhir_r4_py` exposes REST FHIR endpoints
  under `/api_fhir_r4/`, mapping domain models to resources (Insuree→Patient,
  Policy→Coverage, Claim→Claim). See [FHIR R4 API](../modules/fhir.md).

filter_validity
: A core helper that appends the temporal validity filter (open validity window) to
  a queryset so it returns *current* versions only. Forgetting it is the number-one
  temporal bug. See [Database](../database/index.md).

## G

Gateway
: The Nginx reverse proxy in the reference deployment that fronts the frontend,
  `/api`, and `/graphql`, presenting one origin to the browser. See
  [Docker & Deployment](../docker/index.md).

Graphene / graphene-django
: The Python library openIMIS uses to build its GraphQL schema. Each module defines
  Graphene `Query`/`Mutation` classes that the assembly stitches together. See
  [GraphQL](../graphql/index.md).

GraphQL
: The query language and runtime the frontend uses to talk to the backend. A single
  `/graphql` endpoint serves typed queries and mutations. Taught from first
  principles in [GraphQL](../graphql/index.md).

## H

HistoryModel
: A core base model giving records full change history via temporal `validity_from`
  / `validity_to` fields (plus `legacy_id`, `json_ext`). Updating a record creates a
  new version rather than overwriting. See [The Core Module](../modules/core.md).

HistoryBusinessModel
: A core base model extending the history/temporal behavior with business-object
  conveniences shared across domain entities. See [The Core Module](../modules/core.md).

## I

Individual
: The newer, generic person entity from `openimis-be-individual_py`, used by social
  protection and beneficiary-registry use cases — a cleaner-schema counterpart to
  the legacy `Insuree`. See [Individual & Social Protection](../modules/individual.md).

Insuree
: The insured person in the health-financing domain — a member of a family covered
  (or to be covered) by a policy. The legacy core beneficiary entity, in
  `openimis-be-insuree_py`. Contrast with the newer `Individual`. See
  [Insuree](../modules/insuree.md).

InsureePolicy
: The link record associating an insuree with a policy, capturing that person's
  coverage under it (dates, status). See [Policy](../modules/policy.md).

InteractiveUser
: The part of the openIMIS `User` representing a human who logs into the UI (carries
  roles and integer rights). Contrast with `TechnicalUser`. See
  [Security](../security/index.md).

INSTALLED_APPS (dynamic)
: openIMIS builds Django's `INSTALLED_APPS` at startup from the loaded module list
  (the manifest) rather than hardcoding it — the mechanism that makes the platform
  modular. Built in `openimis/settings.py`. See
  [Plugin / Module System](../architecture/plugin-system.md).

## J

json_ext
: A JSONField present on openIMIS base models for storing extra, deployment- or
  country-specific data without a schema migration. Prefer it over a new column for
  optional/rarely-queried fields. See [Database](../database/index.md).

Journalize
: The frontend helper that polls a mutation's `MutationLog` status after a write and
  updates the Redux store when it resolves — the FE side of the async mutation
  pattern. See [Frontend Architecture](../architecture/frontend.md).

JWT (JSON Web Token)
: The bearer token openIMIS uses for authentication, via `django-graphql-jwt`,
  stored in an **HttpOnly cookie** to reduce XSS token theft. OIDC/OAuth2 is also
  supported for external identity providers. See [Security](../security/index.md).

## L

legacy_id
: A field on versioned models holding the original legacy integer primary key,
  preserving the link to pre-migration data and reports alongside the newer UUID.
  See [Database](../database/index.md).

Location hierarchy
: The tree of administrative and facility locations (e.g. region → district →
  municipality → village, plus health facilities), foundational reference data from
  `openimis-be-location_py`. Most domain records hang off a location. See
  [Location & Health Facility](../modules/location.md).

## M

Manifest (module manifest)
: The `openimis.json` file in each assembly repo listing the modules to load (with
  pip/git sources on the backend). The load-bearing artifact behind "config over
  fork." See [Plugin / Module System](../architecture/plugin-system.md).

Medical (items & services)
: Reference data for the medical items (drugs, consumables) and services a scheme
  covers, from `openimis-be-medical_py` — the building blocks of price lists and
  claims. See [Medical & Product](../modules/medical.md).

Module
: An independently versioned unit of functionality living in its own repository
  (`openimis-be-<name>_py` / `openimis-fe-<name>_js`), loaded via the manifest. The
  central design idea of openIMIS. See [Plugin / Module System](../architecture/plugin-system.md).

ModuleConfiguration
: The core model that stores each module's runtime configuration JSON in the
  database, overlaying its `DEFAULT_CFG` at startup so operators can reconfigure a
  deployment without code changes. See [Configuration](../configuration/index.md).

ModulesManager
: The frontend cross-module registry (from FE core) used to look up published refs,
  config, and contributions — e.g. `modulesManager.getRef("insuree.InsureePicker")`,
  `.getContribs("insuree.MainMenu")`. The FE analogue of the backend plugin seam.
  See [Frontend Architecture](../architecture/frontend.md).

MutationLog
: The core model recording every mutation: its `clientMutationId`, status, and any
  error. It is both the audit trail and the object the client polls for async
  completion. See [GraphQL](../graphql/index.md).

## O

Officer
: The domain model for field staff (e.g. enrolment officers), linked to the openIMIS
  `User`. See [Insuree](../modules/insuree.md).

OpenIMISMutation
: The core base class implementing the **asynchronous mutation pattern**: create a
  `MutationLog`, do the work in a service, return a `clientMutationId` for the
  client to poll. Every mutation subclasses it and is audited. See
  [GraphQL](../graphql/index.md).

OpenSearch
: The search/analytics engine openIMIS uses to offload heavy reporting from the
  transactional database, driven by `opensearch_reports`. See
  [Integrations](../integrations/index.md).

OrderedDjangoFilterConnectionField
: A core Graphene helper providing filterable, orderable Relay connections for
  GraphQL list queries. See [GraphQL](../graphql/index.md).

## P

Payer
: The entity that pays contributions on behalf of insurees (e.g. an employer, a
  government subsidy, a donor). See [Contribution & Payment](../modules/payment.md).

Payment
: Money openIMIS pays *out* — chiefly provider payment for adjudicated claims,
  handled by the payment/invoice modules. Contrast with *contribution* (money paid
  *in*). See [Contribution & Payment](../modules/payment.md).

Policy
: A coverage contract linking an insuree/family to a product for a validity period —
  the record that says "this person is covered under these benefits now." Lives in
  `openimis-be-policy_py`. See [Policy](../modules/policy.md).

PrefixFilterset
: A core helper for building Graphene/Django filtersets with a shared field prefix,
  reducing filter boilerplate across modules. See [GraphQL](../graphql/index.md).

Price List
: The set of prices a product/scheme applies to covered medical items and services —
  the reference used when valuing claims. See [Medical & Product](../modules/medical.md).

Product
: An insurance product: the benefit package, rules, price lists, and parameters an
  insuree is covered under via a policy. From `openimis-be-product_py`. See
  [Medical & Product](../modules/medical.md).

## R

register_service_signal
: The core decorator/function that marks a service method as emitting before/after
  signals (named like `"module.service.method"`), so other modules can bind to it
  without importing it. The producer half of the service-signal seam. See
  [Best Practices](../best-practices/index.md).

Rights / Permissions
: openIMIS authorizes actions by **integer rights codes** (e.g. `111001`) carried by
  a user's roles and checked with `user.has_perms([...])`. Codes are defined per
  module in `apps.py`. See [Security](../security/index.md).

## S

Schema assembly
: The process in `openimis/schema.py` of importing each module's Graphene
  `Query`/`Mutation` and combining them into one root `Query`/`Mutation` via Python
  multiple inheritance. See [Plugin / Module System](../architecture/plugin-system.md).

Scheduler (APScheduler)
: The background-task scheduler core uses for periodic jobs (data loads, ETL,
  maintenance). See [The Core Module](../modules/core.md).

Service (service layer)
: A module's `services.py` class holding business logic, callable from GraphQL,
  REST/FHIR, jobs, and tests alike — keeping resolvers/mutations thin. See
  [Best Practices](../best-practices/index.md).

Service signal
: The core extension seam letting a module run logic before/after another module's
  service call *without importing it* (`register_service_signal` +
  `bind_service_signal`). Distinct from plain Django ORM signals, which openIMIS
  also uses. See [The Core Module](../modules/core.md).

Social Protection
: The broader domain — beyond health insurance — of benefit and cash-transfer
  programs, supported by `openimis-be-social_protection_py` on top of the generic
  `Individual` model. See [Individual & Social Protection](../modules/individual.md).

## T

TechnicalUser
: The part of the openIMIS `User` representing a service account (machine-to-machine
  access, integrations), as opposed to `InteractiveUser` (humans). See
  [Security](../security/index.md).

Temporal versioning
: The design in which business records carry `validity_from` / `validity_to`
  windows and updates create new versions, so you can query the state "as of" any
  date — essential for adjudicating claims against past coverage. See
  [Database](../database/index.md).

## U

User (openIMIS User)
: Core's custom user model, which *composes* `InteractiveUser` (humans),
  `TechnicalUser` (service accounts), and `Officer`/`i_user`. Roles carry integer
  rights. Not the vanilla Django user. See [Security](../security/index.md).

UUIDModel
: A core base model providing a UUID primary key, part of the identity system added
  during the migration away from purely integer keys. See [Database](../database/index.md).

## V

ValidityFrom / ValidityTo (`validity_from` / `validity_to`)
: The temporal fields on versioned models bounding when a version is the current
  truth. An open (null) `validity_to` marks the live version. See
  [Database](../database/index.md).

VersionedModel
: The core base model implementing temporal versioning (`validity_from` /
  `validity_to`, `legacy_id`) — the foundation for auditable, as-of-queryable
  business data. See [The Core Module](../modules/core.md).

## W

Workflow / tasks_management
: Modules (`openimis-be-workflow_py`, `openimis-be-tasks_management_py`) supporting
  configurable multi-step business processes and human task queues (e.g. claim
  review workflows). See [Developer Workflow](../workflow/index.md).

---

## Further reading

- [Terminology Primer](../getting-started/terminology.md) — the essential subset,
  taught narratively for newcomers.
- [Repository Appendix](appendix.md) — every repository, package, and
  responsibility in one master table.
- [Troubleshooting](troubleshooting.md) — when a term above turns into a real bug.
- Official openIMIS wiki: [openimis.atlassian.net/wiki](https://openimis.atlassian.net/wiki/).
