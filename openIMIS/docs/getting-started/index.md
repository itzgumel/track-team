# Getting Started

This is the on-ramp. Three short chapters take you from "I have heard of openIMIS" to "I have a working local environment and I know what the words mean." Do them in order the first time; return to any of them as reference later.

!!! tip "You are here"
    You have read the [course home page](../index.md) and you have the big-picture layer diagram in your head. Good. Now we fill in the *why*, the *vocabulary*, and the *how do I run this*.

## What this section covers

<div class="oi-grid" markdown="1">

<div class="oi-card" markdown="1">
### <a href="overview.md">Platform Overview</a>
What openIMIS is, the real-world problem it solves, the health-financing ecosystem it models, and how it evolved from a monolithic .NET/MSSQL system into a modular Django/React platform. Start here.
</div>

<div class="oi-card" markdown="1">
### <a href="terminology.md">Terminology Primer</a>
The domain and platform vocabulary a new developer must know: insuree vs. individual, policy vs. product, contribution vs. payment, rights, `MutationLog`, `json_ext`, and more.
</div>

<div class="oi-card" markdown="1">
### <a href="setup.md">Set Up a Dev Environment</a>
Clone the assembly repos, understand the `openimis.json` manifest, boot the stack with Docker, and run the backend and frontend locally with editable module installs.
</div>

</div>

## How much time to budget

| Chapter | Reading | Hands-on |
| --- | --- | --- |
| [Platform Overview](overview.md) | ~20 min | — |
| [Terminology Primer](terminology.md) | ~15 min | keep it open as a reference |
| [Set Up a Dev Environment](setup.md) | ~15 min | 30–60 min the first time |

## What comes next

Once you can load the app in a browser and you recognize the vocabulary, move on to the [Architecture](../architecture/overview.md) section, where we open up the plugin system and explain how ~47 independent repositories become one running application. If GraphQL is new to you, the [GraphQL](../graphql/index.md) chapter teaches it from zero before you need it in anger.

!!! note "A reminder on scope"
    This is a community handbook, not official documentation. Where details are version-dependent, we point you to the authoritative repositories under [github.com/openimis](https://github.com/openimis). See the full disclaimer on the [home page](../index.md).
