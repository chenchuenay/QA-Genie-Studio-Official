# QA Genie

QA Genie is a production-focused AI-powered QA testcase generation platform built in Flutter.

The system generates realistic manual QA testcases with deterministic repair, forensic recovery, structural validation, fallback intelligence, export integrity, and enterprise-style QA workflows.

## Product Goals

- Replace generic AI testcase generation
- Simulate real tester thinking
- Preserve export-safe deterministic structure
- Recover from malformed AI responses
- Generate realistic workflow-driven testcases
- Support manual testers and junior QA engineers

## Current Product Limits

### CORE PLAN

- 8 testcases per generation
- 1 free generation/day
- +5 rewarded ad generations/day
- Rewarded ads required after free limit

### PRO PLAN

- 16 testcases per generation
- 15 generations/day
- No rewarded ads
- Advanced exports enabled

## Supported Test Types

- POSITIVE
- NEGATIVE
- EDGE
- VALIDATION
- SECURITY
- SESSION
- USABILITY

## Supported Platforms

- Web
- Android
- iOS
- Desktop

## Current AI Pipeline Features

- Structured JSON schema enforcement
- Truncation recovery
- Structural validation
- Deterministic repair
- Fallback testcase generation
- QA realism enforcement
- Export-safe persistence
- SQLite locking protection
- Lineage telemetry

## Major Architectural Systems

- AI Generation Pipeline
- Parser Recovery System
- Structural Validator
- Deterministic Repair Engine
- Realism Humanization Engine
- SQLite Persistence Layer
- Export Mapping Layer
- Monetization Layer
- Telemetry/Forensics Layer

## Critical Files

- lib/engine/generation_service.dart
- lib/core/network/providers/gemini_provider.dart
- lib/core/network/response_parser.dart
- lib/engine/recovery/object_boundary_extractor.dart
- lib/core/validators/structural_case_validator.dart
- lib/core/database/database_service.dart
- lib/engine/fallback/fallback_generator.dart
- lib/core/quality/qa_realism_enforcer.dart

## Critical Generation Rule

QA Genie is architected around a STRICT SINGLE AI REQUEST model.

### Core Constraint

ONLY ONE AI API CALL is allowed per generation request.

The system must:

- recover malformed responses locally
- repair truncated payloads locally
- validate structure locally
- humanize locally
- generate fallback cases locally

The system must NOT:

- retry AI generation automatically
- perform multi-call repair chains
- use secondary AI repair prompts
- spawn additional hidden AI requests
- perform recursive generation loops

## Why This Rule Exists

### Cost Stability

Single-call architecture guarantees predictable API cost scaling.

### Monetization Integrity

Generation limits remain economically enforceable:

- Core: 1 free + 5 rewarded/day
- Pro: 15/day

### Latency Control

Avoids multi-request waiting chains and UI blocking.

### Deterministic Recovery

All corruption recovery must happen inside local deterministic systems:

- ObjectBoundaryExtractor
- StructuralCaseValidator
- DeterministicRepair
- FallbackGenerator

### Engineering Philosophy

QA Genie is designed as a hardened QA workflow engine — not a retry-spamming AI wrapper.

## Current Recovery Stack

Single AI Request
↓
Parser Recovery
↓
Boundary Extraction
↓
Structural Validation
↓
Deterministic Repair
↓
Fallback Generation
↓
Realism Enforcement
↓
Persistence
↓
Export

## Important Engineering Constraint

Any future feature MUST preserve:

- single-request generation
- deterministic local recovery
- export-safe structure
- offline-safe fallback recovery
