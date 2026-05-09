# QA Genie Engine Law

QA Genie is a deterministic QA workflow platform, not a generic AI wrapper.

The product survives only if test case quality is trusted, exports are stable,
generation feels human-authored, platform realism never breaks, AI costs stay
controlled, and abuse remains manageable.

## Core Product Goal

Generate execution-ready, platform-correct, export-safe manual test cases.

The user should feel: "A QA engineer prepared this."

## Non-Negotiable Rules

1. Single source of truth

All preview, summary, history, and export layers consume `TestCaseModel`.
No UI-only row schemas or export-specific mutable models should become source
data.

2. One AI call per generation

One generation request may make at most one AI call. No retry storms, recursive
generation, chained enrichment, or multi-pass prompting. Deterministic repair
fills gaps.

3. Deterministic architecture

The same module, feature, platform, mode, and seed should produce predictable
suite patterns.

4. Platform firewall

Platform contamination is a hard reject, not a partial cleanup.

5. Export adapters are read-only

Export adapters must not mutate `TestCaseModel`. They render immutable views of
the canonical data and must be null-safe.

## Pipeline

```text
User Input
-> Scenario Planner
-> Distribution Engine
-> AI Enrichment (single API call)
-> Quality Filter
-> Platform Firewall
-> Deduplication
-> Deterministic Repair
-> Final Validation
-> Export Layer
```

## Platform Firewall

Web forbids API/mobile language such as JWT, bearer token, adb, swipe, tap,
mobile permission, and HTTP response body.

Mobile forbids desktop browser language such as cookie, browser refresh, hover,
ctrl+f5, and right click.

API forbids UI language such as click button, navigate page, tap screen, and
form filling.

The firewall must keep expanding from exact tokens toward concept families.
Equivalent wording still counts as contamination when it implies the wrong
execution surface.

## Semantic QA Intelligence

The deterministic layer must reason about domain and risk before it reasons
about wording. Auth, payment, file handling, discovery, profile, and general
workflows should receive different priorities, expected results, and failure
checks.

Expected results must describe observable outcomes such as validation feedback,
state persistence, redirects, session changes, response schema, timing behavior,
or saved references. Generic success language is not acceptable.

Deterministic repair cases should be indistinguishable from AI-enriched cases.
Repair exists to preserve count and quality, not to add filler.

## Product Bias

Prefer fewer trusted test cases over many weak AI-generated cases. Trust is the
real product.
