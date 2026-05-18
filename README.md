# QA Genie

<p align="center">
  <b>Production-focused AI-assisted QA generation platform</b><br>
  Deterministic orchestration • Realistic test cases • Forensic observability • Export-safe workflows
</p>

---

# About the Creator

QA Genie is independently designed, engineered, tested, refined, and continuously evolved by:

## Enay Kumar
- QA-focused builder
- Manual testing enthusiast
- Workflow-driven product thinker
- Real-world QA realism advocate
- Developer + Tester + Product Owner of QA Genie

This project was not built as a generic “AI app”.

It was built from the perspective of someone actively studying:
- software testing realities
- execution pain points
- weak AI-generated QA outputs
- repetitive test-case problems
- export workflow friction
- debugging failures
- production-level QA process expectations

QA Genie reflects the mindset of:
> “AI should assist QA engineers — not replace QA thinking.”

---

# Vision

QA Genie exists to solve one core problem:

> Most AI-generated test cases look impressive at first glance but fail in real QA execution workflows.

Traditional AI outputs often produce:
- generic assertions
- unrealistic scenarios
- repetitive flows
- shallow validations
- weak negative testing
- broken exports
- unusable execution structures

QA Genie was built to push beyond “prompt → response”.

The platform aims to behave more like:
```text
a controlled QA generation pipeline
```

instead of a simple AI wrapper.

---

# Core Philosophy

## 1. AI Is Probabilistic Input — Not Trusted Truth

AI providers can generate:
- malformed outputs
- repetitive cases
- fake validations
- weak assertions
- broken JSON
- hallucinated logic
- export-breaking structures

QA Genie assumes AI responses are:
```text
recoverable raw material
```

not authoritative truth.

Everything passes through:
- parsing
- validation
- deduplication
- repair
- fallback generation
- normalization
- export-safe formatting

---

## 2. Deterministic-Oriented Architecture

The system prioritizes:
- predictability
- repairability
- forensic traceability
- export stability

over:
- uncontrolled autonomy
- endless retries
- hidden AI mutation

AI generation is intentionally constrained and stabilized.

---

## 3. One Provider Call Per Generation

Each generation session attempts to complete using:
```text
ONE AI provider call
```

Why:
- lower latency
- lower cost
- simpler orchestration
- reproducible debugging
- easier forensic tracing
- reduced prompt drift

The pipeline repairs outputs locally instead of repeatedly asking the provider again.

---

# High-Level Architecture

```text
User Input
    ↓
Prompt Construction
    ↓
AI Provider Request
    ↓
Raw Response Capture
    ↓
Parser
    ↓
Validator
    ↓
Deduplication
    ↓
Deterministic Repair
    ↓
Fallback Generation
    ↓
Normalization
    ↓
Preview / Editing
    ↓
Export
```

---

# Core Generation Goals

QA Genie focuses on generating:

- realistic QA flows
- execution-ready scenarios
- meaningful assertions
- session-aware behavior
- security-oriented edge cases
- structured exports
- editable outputs
- deterministic expected results

The platform intentionally avoids:
- vague test cases
- fake demo scenarios
- “Verify button works”
- meaningless validations
- shallow AI filler content

---

# Test Case Realism Philosophy

QA Genie attempts to mimic how experienced testers actually think.

## Prioritized Scenarios

### Functional
- login validation
- role access
- navigation
- form validation
- CRUD flows
- business rules

### Negative
- invalid credentials
- malformed inputs
- duplicate submissions
- expired sessions
- unauthorized access
- empty states

### Security-Oriented
- session hijacking awareness
- access boundary validation
- token expiration
- rate limiting
- injection-oriented input checks

### Reliability
- retry flows
- stale data
- interrupted operations
- browser refresh behavior
- state inconsistency

---

# Deterministic Repair Pipeline

One of QA Genie’s core architectural pillars.

Instead of endlessly regenerating AI output, the system repairs valid portions locally.

## Repair Goals
- preserve usable AI creativity
- stabilize exports
- normalize structures
- remove repetitive patterns
- strengthen assertions
- repair malformed cases

## Repair Examples
- fixing missing expected results
- normalizing steps
- removing duplicates
- fixing malformed structures
- improving weak validations
- repairing export-breaking fields

The repair system reduces provider dependency while improving consistency.

---

# Fallback Generation System

Fallback generation exists to guarantee pipeline continuity.

Triggered during:
- parser failures
- malformed provider responses
- insufficient valid cases
- validator over-rejection
- incomplete AI output

Fallback cases are:
```text
deterministically generated locally
```

not regenerated from the provider.

This allows QA Genie to recover gracefully from partial AI failure.

---

# Export Architecture

QA Genie exports are designed for real QA workflows.

## Supported Formats
- Excel
- CSV
- Jira
- Xray
- PDF

## Export Goals
- stable schema
- deterministic column ordering
- execution-ready structure
- editable outputs
- minimal cleanup effort

---

# Canonical Test Case Structure

All generated test cases follow invariant structure:

```json
{
  "id": "",
  "title": "",
  "preconditions": [],
  "testData": "",
  "steps": [],
  "expectedResult": "",
  "Actual Results": "",
  "priority": "",
  "status": "",
  "type": ""
}
```

This structure is intentionally preserved for:
- export consistency
- editing workflows
- persistence stability
- QA execution alignment

---

# AI Provider Architecture

Currently supported providers:
- Groq
- Gemini

Runtime selection:

```bash
flutter run --dart-define=AI_PROVIDER=groq
```

or

```bash
flutter run --dart-define=AI_PROVIDER=gemini
```

---

# Forensic Observability System

QA Genie includes a local forensic logging architecture for development and QA builds.

Purpose:
> Allow another engineer or AI system to fully diagnose a failed generation without requiring screenshots, prompts, or manually pasted logs.

---

# Forensic Files

## Verbose Pipeline Dumps

```text
core_pipeline.txt
pro_pipeline.txt
```

Contain:
- full prompts
- raw AI responses
- parser traces
- validator traces
- repair traces
- fallback traces
- final outputs
- performance telemetry
- UI errors
- token analytics

These files:
```text
overwrite every generation
```

They represent:
```text
latest forensic snapshot only
```

---

## Analytical Logs

```text
core_analytical_logs.txt
pro_analytical_logs.txt
```

Contain:
- compact telemetry history
- performance trends
- fallback frequency
- provider behavior
- repair metrics

These logs:
```text
append historically
```

---

# Forensic Design Principles

The observability system follows strict separation boundaries.

## TelemetryCollector
- memory only
- no filesystem access
- no UI dependencies

## Formatter
- deterministic rendering only
- no mutation
- no business logic

## Writer
- filesystem only
- atomic writes
- safe overwrite/append behavior

## Guarantees
- no telemetry-caused crashes
- no BuildContext dependency
- no business-logic mutation
- production-safe disable switch
- overwrite verbose dumps
- append analytical logs

---

# Development Philosophy

QA Genie intentionally prioritizes:

```text
traceability
repairability
predictability
realism
export safety
```

over:
- maximum automation
- uncontrolled AI autonomy
- flashy demo behavior

The goal is:
```text
controlled AI-assisted QA generation
```

not autonomous AI testing fantasy.

---

# Current Engineering Focus

Active architectural refinement areas:
- validator strengthening
- repair intelligence
- forensic truthfulness
- export stability
- deterministic orchestration
- execution realism
- fallback quality
- parser resilience

---

# Project Structure

```text
lib/
├── app/
├── core/
│   ├── error/
│   ├── export/
│   ├── logging/
│   ├── network/
│   └── utils/
│
├── engine/
│   ├── deterministic_repair.dart
│   ├── distribution_engine.dart
│   ├── fallback_generator.dart
│   ├── generation_service.dart
│   ├── scenario_planner.dart
│   └── validators/
│
├── features/
├── presentation/
└── main.dart
```

---

# Intended Users

QA Genie is designed for:
- QA engineers
- manual testers
- automation testers
- freelancers
- startups
- low-resource QA teams
- independent testers

---

# Build Philosophy

The system is intentionally optimized for:
- low operational cost
- local debugging
- reproducible outputs
- deterministic repair
- realistic QA workflows
- export-safe execution

---

# Long-Term Goal

QA Genie aims to become:

```text
A reliable AI-assisted QA generation system
that produces execution-quality outputs
instead of generic AI-generated filler.
```

---

# License

Private project.
All rights reserved.

Developed and maintained by Enay Kumar.
