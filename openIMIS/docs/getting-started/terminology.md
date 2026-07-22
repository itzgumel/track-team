# Terminology & Glossary Primer

> **Part 2 of the course.** openIMIS mixes two vocabularies: the **health-financing domain** (insuree, policy, contribution, claim) and the **platform's own conventions** (module, assembly repo, `MutationLog`, `json_ext`). Confusing them — or, worse, mapping a domain word onto the wrong platform concept — is the single most common source of early bugs and miscommunication. This chapter is your primer.

## Learning objectives

By the end of this chapter you will be able to:

- Use the core **domain** vocabulary — insuree, individual, family, product, policy, contribution, claim, health facility, location, officer, payer, price list, capitation — correctly and precisely.
- Distinguish pairs that newcomers routinely conflate: **insuree vs. individual**, **product vs. policy**, **contribution vs. payment**.
- Recognize the platform's own vocabulary — **module**, **assembly repo**, **rights/permissions**, **`MutationLog`**, **`validity_from`/`validity_to`**, **`json_ext`** — and know which module owns each concept.

## Prerequisites

- [Platform Overview](overview.md) — the ecosystem story that these terms label.
- No code required. Keep this page open as a reference while you read the rest of the handbook.

!!! note "This is a primer, not the full glossary"
    This chapter teaches the *essential* vocabulary and the distinctions that trip people up. The complete, alphabetized glossary — every term, every acronym — lives at [Reference → Glossary](../reference/glossary.md). Think of this page as the "words you need before chapter 3" and the glossary as the "look anything up" companion.

---

## Part A — The domain vocabulary

These are concepts from the world of health insurance. They exist whether or not openIMIS exists; openIMIS just models them.

### People and beneficiaries

Insuree
:   A **person covered by (or being enrolled into) a scheme**. The classic openIMIS beneficiary, implemented by the [insuree module](../modules/insuree.md) (`openimis-be-insuree_py`). An insuree belongs to a **family** and is linked to policies. Backed historically by the `tblInsuree` table.

Family / Household
:   A **group of insurees enrolled together**, usually with a designated head and dependents. Policies are typically held at the family level, so covering the family covers its members. The unit most schemes actually enrol.

Individual
:   A **more general "person" concept** introduced with the social-protection work, implemented by the [individual module](../modules/individual.md) (`openimis-be-individual_py`). Where **insuree** is specific to health-insurance beneficiaries, **individual** is a broader registry of people used by social-protection, payroll, and benefit-plan modules. See the distinction below — this pair confuses everyone at first.

Officer / Enrolment Officer
:   A **field agent responsible for enrolling members and collecting contributions** in a given area. Modeled in core (linked from the `User` model via `Officer`). Officers are tied to locations and often to the policies and contributions they process. Not the same as a system administrator — an officer is a domain actor.

Payer
:   An **entity that pays contributions on behalf of insurees** — for example a government subsidy programme, an employer, or a donor. Lets a scheme model third-party or subsidized premiums rather than assuming every member self-pays.

### Coverage and financing

Product
:   The **definition of an insurance plan**: premium, covered medical services and items, waiting periods, ceilings, deductibles, and the associated **price lists**. A product is a *template* of coverage. Implemented alongside the [medical/product modules](../modules/medical.md). **A product does not cover anyone by itself** — it must be attached to a policy.

Policy
:   The **contract that applies a product to a family for a period of time**, with a start date, an expiry date, and a status. The policy is what makes a person *actually covered right now*. Implemented by the [policy module](../modules/policy.md) (`openimis-be-policy_py`). If **product** is the plan, **policy** is the subscription to that plan.

Contribution
:   A **premium payment recorded against a policy** to keep it active. Implemented by the [contribution module](../modules/payment.md) (`openimis-be-contribution_py`). Contributions are the *money coming in* to fund coverage. See "Contribution vs. Payment" below — they are not the same thing.

Price List
:   A **schedule of prices for medical services and items** attached to products and health facilities. Determines what a given service or item is worth under a given product, feeding claim valuation.

### Delivery and providers

Health Facility
:   A **provider of care** — clinic, health center, hospital, pharmacy — that serves insurees and submits claims. Registered with a type and a place in the location hierarchy. Implemented via the [location module](../modules/location.md) (`openimis-be-location_py`).

Location hierarchy
:   The **administrative geography** of a deployment — typically region → district → municipality/ward → village, though the exact levels are country-configurable. Governs administration, officer assignments, and which facilities serve which members. Also implemented by the [location module](../modules/location.md).

Claim
:   A **request for payment submitted by a health facility for care delivered** to a covered insuree. It lists the services and items provided, is checked for eligibility, adjudicated against the product's rules, and **valued** (often via calculation rules). Implemented by the [claim module](../modules/claim.md) (`openimis-be-claim_py`). Backed historically by `tblClaim`.

Capitation
:   A **provider-payment method that pays a facility a fixed amount per enrolled person per period**, regardless of services delivered — as opposed to fee-for-service, which pays per service. In openIMIS, capitation and other valuation schemes are implemented as pluggable **calculation rules** (`calcrule_*` modules) on top of the [calculation](../modules/calculation.md) framework.

Payment
:   The **actual movement of money** — the money going *out* to providers (settling valued claims via the invoice/payment modules) or, at the edges, integrating with external payment gateways such as mobile money. Distinct from a contribution.

!!! danger "Common mistake: three pairs you must not conflate"
    - **Insuree ≠ Individual.** *Insuree* is the classic health-insurance beneficiary (insuree module). *Individual* is the newer, more general person concept used by social-protection and payroll (individual module). Different modules, different tables, related but not interchangeable.
    - **Product ≠ Policy.** A *product* is the plan definition; a *policy* is a specific family's time-bounded subscription to that plan. A product covers nobody until a policy attaches it to a family.
    - **Contribution ≠ Payment.** A *contribution* is a **premium coming in** to fund a policy. A *payment* is money moving — most notably **going out** to providers for valued claims. They live in different modules for a reason.

---

## Part B — The platform vocabulary

These are openIMIS-specific engineering concepts. They are *not* domain terms — they are how the platform is built. Learn these before the [Architecture](../architecture/overview.md) chapter.

### Structure and packaging

Module
:   An **independently versioned plugin** that provides part of openIMIS. On the backend it is a Django app in a repo named `openimis-be-<name>_py`; the installed Python package is just `<name>` (e.g. `core`, `claim`, `policy`). On the frontend it is `openimis-fe-<name>_js` exporting a config object. Modules are the unit of everything: code, release cadence, and configuration. Covered in depth in the [Plugin System](../architecture/plugin-system.md) chapter.

Assembly repo
:   The **thin top-level project that stitches modules into one running application**. Backend: **`openimis-be_py`** (a Django project). Frontend: **`openimis-fe_js`** (a React SPA). Each is mostly a manifest plus wiring; almost no business logic lives here. See the [Repository Map](../architecture/repository-map.md).

`openimis.json`
:   The **module manifest** — the list of modules (~47 on the backend) that the assembly repo should load, each with a pip/git source. A build step turns it into `modules-requirements.txt` for installation. There is a backend `openimis.json` (in `openimis-be_py`) and a frontend one (in `openimis-fe_js`).

Core module
:   The **framework layer every other module depends on** (`openimis-be-core_py`, package `core`). It provides the base models, the custom `User`, the permissions machinery, the GraphQL/Graphene helpers, the `OpenIMISMutation` base class, service signals, the calculation-rule framework, and the scheduler. Nearly everything in Part B below is defined here. Its own chapter is [Modules → Core](../modules/core.md).

### Permissions and users

Rights / Permissions
:   openIMIS authorizes actions using **integer permission codes** ("rights"), defined per module in each module's `apps.py` (for example `gql_query_claims_perms = [111001]`). Users hold rights through their roles; resolvers and mutations check them with `user.has_perms([<int codes>])`. On the frontend, route guards check the same integer rights. Do not expect Django's string-based permission names here — the codes are numbers. Detailed in the [Security](../security/index.md) chapter.

User (and InteractiveUser / TechnicalUser / Officer)
:   openIMIS ships a **custom `User` model** (in core) that links to several role objects:
    - **InteractiveUser** — a human who logs into the UI.
    - **TechnicalUser** — a service account for machine-to-machine access.
    - **Officer** — the domain actor (enrolment officer) described in Part A.
    A single `User` unifies these so authentication and rights work uniformly.

### The framework primitives

`MutationLog`
:   The **audit-and-status record for every GraphQL mutation**. openIMIS mutations are **asynchronous**: the `OpenIMISMutation` base class creates a `MutationLog`, does the real work in a service, and immediately returns a `clientMutationId`; the client then **polls** the mutation's status (received → checked/processing → success/failed). This gives every write a durable audit trail and a uniform async contract. The pattern is taught in the [GraphQL](../graphql/index.md) chapter.

`ValidityFrom` / `ValidityTo` (`validity_from` / `validity_to`)
:   **Temporal versioning fields** carried by core's `HistoryModel` / `VersionedModel`. Instead of hard-deleting or overwriting, openIMIS often "closes" a row by stamping `validity_to` and creating a new version — so you can reconstruct the state of the data at any past date. A row with an empty `validity_to` is the currently valid version. Inherited and formalized from the legacy IMIS design. Covered in [Database](../database/index.md).

`json_ext`
:   A **`JSONField` present on many models for extensibility**. Because a module cannot always add columns to another module's table, `json_ext` provides a per-row "extension bag" where extra, deployment- or module-specific attributes can live without a schema migration. It is the pragmatic escape hatch that keeps the modular system flexible — and, used carelessly, a place where undocumented data hides. Use it deliberately.

`legacy_id`
:   The **old integer primary key from IMIS**, retained alongside the modern UUID on versioned models so legacy data and reports still line up after migration.

!!! info "Did you know?"
    The asynchronous `MutationLog` pattern means the openIMIS frontend is *not* a simple "fire request, await response" client. After sending a mutation it "journalizes" and **polls** for the mutation's final status. This is why the React layer uses a custom GraphQL integration over Redux rather than Apollo — see the [Frontend Architecture](../architecture/frontend.md) chapter.

---

## Quick-reference table

A compressed cheat sheet. Domain terms on top, platform terms below.

| Term | Category | One-line meaning | Owning module |
| --- | --- | --- | --- |
| Insuree | Domain | Health-insurance beneficiary | `insuree` |
| Individual | Domain | General person (social protection) | `individual` |
| Family | Domain | Household enrolled together | `insuree` |
| Officer | Domain | Enrolment/field agent | `core` |
| Payer | Domain | Third party paying premiums | `contribution` / `payment` |
| Product | Domain | Insurance plan definition | `product` / `medical` |
| Policy | Domain | Family's subscription to a product | `policy` |
| Contribution | Domain | Premium coming in | `contribution` |
| Price list | Domain | Prices for services/items | `medical` / `product` |
| Health facility | Domain | Care provider that submits claims | `location` |
| Location hierarchy | Domain | Administrative geography | `location` |
| Claim | Domain | Facility's request for payment | `claim` |
| Capitation | Domain | Per-enrollee provider payment | `calculation` / `calcrule_*` |
| Payment | Domain | Money going out (and gateways) | `payment` / `invoice` |
| Module | Platform | Independently versioned plugin | — |
| Assembly repo | Platform | Thin project stitching modules | `openimis-be_py` / `openimis-fe_js` |
| `openimis.json` | Platform | Module manifest | assembly repos |
| Rights / permissions | Platform | Integer authorization codes | `core` + each module |
| `MutationLog` | Platform | Async mutation audit + status | `core` |
| `validity_from` / `validity_to` | Platform | Temporal versioning | `core` |
| `json_ext` | Platform | Per-row extension JSON | `core` (used everywhere) |

---

## Hands-on lab

!!! example "Lab 2 — Build your own term map"
    **Goal:** cement the domain/platform split and the confusable pairs.

    1. On a sheet of paper (or a note), draw two columns: **Domain** and **Platform**. Place each term from the quick-reference table in the correct column *from memory*, then check yourself against the table.
    2. For each of the three confusable pairs — insuree/individual, product/policy, contribution/payment — write one sentence that uses **both** terms correctly in the same sentence.
    3. Open the `openimis-be-core_py` repository and locate `core/models.py`. Find the base model classes mentioned here (`HistoryModel`, `VersionedModel`) and confirm the presence of the `validity_from` / `validity_to` fields and a `json_ext` field. You do not need to understand the code yet — just verify the vocabulary maps to real fields. *(See `openimis-be-core_py/core/models.py`.)*

    **Success looks like:** you never again write "the product covers this family" when you mean "the policy," and you can point at the real fields behind `validity_to` and `json_ext`.

## Knowledge check

??? question "Q1: What is the difference between a product and a policy? (click for answer)"
    A **product** is the definition of an insurance plan (premium, covered services/items, ceilings, price lists) — a template. A **policy** is a specific family's time-bounded subscription to a product, with a start date, expiry date, and status. A product covers nobody until a policy attaches it to a family.

??? question "Q2: A contribution and a payment both involve money. How do they differ in openIMIS? (click for answer)"
    A **contribution** is a **premium coming in** to fund a policy (contribution module). A **payment** is money **moving**, most notably **going out** to providers to settle valued claims (payment/invoice modules), plus integration with external payment gateways. Different direction, different modules.

??? question "Q3: What is a MutationLog and why does it exist? (click for answer)"
    `MutationLog` is core's audit-and-status record created for every GraphQL mutation. openIMIS mutations are **asynchronous**: the `OpenIMISMutation` base class creates a `MutationLog`, runs the work in a service, returns a `clientMutationId` immediately, and the client polls the status. It exists to give every write a durable **audit trail** and a uniform **async contract**.

??? question "Q4: What is json_ext for, and what is the risk of using it? (click for answer)"
    `json_ext` is a `JSONField` on many models that acts as a per-row extension bag, letting a module or deployment attach extra attributes without a schema migration — essential flexibility in a modular system. The risk is that data placed there is **schema-less and easy to hide**: undocumented `json_ext` contents become invisible, un-queryable, and hard to maintain if used carelessly.

??? question "Q5: The custom User model links to three role objects. Name them and their purpose. (click for answer)"
    **InteractiveUser** (a human logging into the UI), **TechnicalUser** (a service/machine account), and **Officer** (the enrolment/field-agent domain actor). The single `User` model unifies them so authentication and integer rights work uniformly across human, machine, and domain roles.

## Further reading

- [Reference → Glossary](../reference/glossary.md) — the complete, alphabetized term list this primer distills from.
- [Modules → Core](../modules/core.md) — where most of the Part B primitives are defined.
- [Security](../security/index.md) — the integer rights/permissions model in depth.
- [Database](../database/index.md) — `validity_from`/`validity_to`, `legacy_id`, and the legacy schema heritage.
- Official concepts on the [openIMIS wiki](https://openimis.atlassian.net/wiki/) — the authoritative source for scheme terminology.
