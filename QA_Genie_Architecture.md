# QA GENIE — CANONICAL ENGINEERING SPECIFICATION

Version: vNext Deterministic Pipeline Stable  
Architecture Mode: Deterministic AI-Assisted QA Workflow Engine  
Platforms Supported: Web / Mobile / API  
Environment Modes: DEV / PROD  
Primary Stack: Flutter + Firebase + SQLite

Core Philosophy:

- deterministic over autonomous
- orchestration over recursion
- single AI request per generation
- fallback without deception
- AI assists workflow, never controls workflow
- low operational cost
- solo-maintainable architecture
- production-grade exports
- auditable pipeline behavior
- observable recovery system
- rollback-safe engineering

---

# 1. PRODUCT IDENTITY

QA Genie is a deterministic testcase generation and export platform for professional QA workflows.

It is NOT:

- autonomous AI agent framework
- recursive multi-agent system
- self-healing AI orchestrator
- vector-search RAG engine
- autonomous planning engine
- AI coding assistant

It IS:

- deterministic QA workflow accelerator
- structured testcase generation engine
- enterprise export platform
- forensic-friendly pipeline system
- production-grade QA productivity suite

Core User Goals:

- generate realistic QA testcases
- reduce repetitive testcase writing
- preserve real QA workflow patterns
- support Web/Mobile/API testing
- export safely to enterprise systems
- maintain deterministic structure
- preserve testcase intent integrity

---

# 2. CORE GENERATION PRINCIPLES

## Single AI Call Rule

Each generation operation allows:

- maximum ONE AI provider request
- NO recursive prompting
- NO AI self-correction loops
- NO chained AI orchestration
- NO retry storms

If AI fails:

- deterministic recovery pipeline activates
- parsers attempt salvage
- repair engine restores structure
- fallback generator fills missing cases
- pipeline NEVER recursively calls AI repeatedly

---

## Deterministic Recovery Philosophy

Recovery is ALWAYS deterministic.

The system NEVER pretends:

- fallback outputs are raw AI outputs
- repaired outputs are untouched AI outputs
- generated content came from successful provider completion

Internally:

- forensic metadata preserves true origin
- pipeline events preserve recovery path
- audit logs preserve repair actions

Externally:

- testcase realism remains production quality
- users NEVER see "fallback" wording
- users NEVER see internal recovery details
- outputs ALWAYS remain enterprise QA style

---

## 80/20 Distribution Strategy

Default testcase distribution:

- 80% realistic happy/business flows
- 20% negative/risk/security/validation coverage

Constraint rules override defaults.

If user provides constraints:

- constraints become highest priority
- planner must adapt distribution
- scenario selection must focus constraints
- planner preserves requested intent strictly

Examples:

Security constraints:
→ security-heavy distribution

Boundary constraints:
→ boundary-heavy distribution

Validation constraints:
→ validation-heavy distribution

---

# 3. GENERATION MODES

## CORE MODE

Purpose:
free tier

Limits:

- 8 testcases per generation
- 1 free generation initially
- +5 rewarded generations/day
- 1 free testcase export lifetime
- +50 rewarded exports/day
- 1 free summary export lifetime
- +50 rewarded summary exports/day

Pipeline:

- same validators
- same repair engine
- same export quality
- same deterministic recovery

Differences vs PRO:

- smaller suite size
- reduced advanced diversity
- lower parallel processing limits

---

## PRO MODE

Limits:

- 16 testcases per generation
- 15 generations/day
- unlimited testcase exports
- unlimited summary exports

Additional Enhancements:

- deeper category diversity
- richer negative coverage
- expanded security scenarios
- higher realism variance
- stronger edge-case distribution

---

# 4. PLATFORM SUPPORT

## WEB

Focus Areas:

- browser workflows
- session handling
- UI navigation
- accessibility
- form validation
- state persistence
- security flows

Terminology:

- click
- page
- modal
- form
- browser
- navigation

---

## MOBILE

Focus Areas:

- gestures
- lifecycle
- interruptions
- permissions
- orientation
- app state transitions
- connectivity handling

Terminology:

- tap
- swipe
- foreground/background
- app relaunch
- device permissions

---

## API

Focus Areas:

- endpoint behavior
- status codes
- authorization
- payload validation
- schema integrity
- malformed requests
- throttling
- token validation

Rules:

- avoid UI wording
- use request/response terminology
- avoid button/click/tap wording
- emphasize protocol correctness

---

# 5. DETERMINISTIC PIPELINE ARCHITECTURE

Pipeline Flow:

EnvironmentAuthority  
↓  
SecurityBridge  
↓  
PipelineOrchestrator  
↓  
ScenarioPlanner  
↓  
PromptComposer  
↓  
SecurityFilter  
↓  
PIIScrubber  
↓  
AI Generation Stage  
↓  
ResponseClassifier  
↓  
AIResponseParser  
↓  
MalformedJsonSalvager  
↓  
PartialCaseExtractor  
↓  
SchemaNormalizer  
↓  
StructuralValidator  
↓  
SemanticValidator  
↓  
DeterministicRepair  
↓  
PartialSuiteExpander  
↓  
QaRealismEnforcer  
↓  
ExportSafetyValidator  
↓  
FinalizedTestCase  
↓  
ExportMapper  
↓  
ExportAdapters

---

# 6. PIPELINE ORCHESTRATOR

File:
`lib/engine/orchestration/pipeline_orchestrator.dart`

Purpose:
single routing authority

Responsibilities:

- coordinate stages only
- enforce pipeline order
- control retries
- route recovery behavior
- preserve deterministic execution
- emit forensic events

Critical Rule:

ONLY orchestrator may:

- trigger retries
- trigger fallback
- trigger partial expansion
- switch recovery stages

No hidden stage recursion allowed.

---

# 7. GENERATION OUTCOME CONTRACT

File:
`lib/engine/models/generation_outcome.dart`

Purpose:
canonical pipeline state model

Outcome Types:

- fullSuccess
- partialSuccess
- malformedResponse
- emptyResponse
- transportFailure
- providerFailure
- fallbackRecovered

Purpose:

prevent spaghetti recovery logic.

Entire pipeline decisions route through:

GenerationOutcome

---

# 8. FAILURE CLASSIFIER

File:
`lib/engine/recovery/failure_classifier.dart`

Purpose:
central recovery intelligence

Responsibilities:

- classify provider failures
- determine retry eligibility
- detect salvageable responses
- determine fallback routing
- distinguish transport vs provider failures

Rules:

429:
→ retry once only

503:
→ retry once only

Malformed partial JSON:
→ salvage parser

Partial valid suite:
→ partial expansion

Completely empty valid response:
→ full deterministic fallback

---

# 9. PARSING LAYER

Directory:
`lib/engine/parsers/`

Purpose:
isolated response interpretation layer

## AI RESPONSE PARSER

Responsibilities:

- clean structured parsing
- canonical extraction
- schema interpretation

---

## MALFORMED JSON SALVAGER

Responsibilities:

- repair broken brackets
- repair commas
- repair malformed arrays
- recover partial JSON fragments

NEVER invent business logic.

---

## PARTIAL CASE EXTRACTOR

Responsibilities:

- recover valid cases only
- preserve usable outputs
- discard corrupted fragments safely

---

## SCHEMA NORMALIZER

Responsibilities:

- normalize old/new schemas
- enforce canonical shape
- preserve invariant fields

---

## RESPONSE CLASSIFIER

Responsibilities:

detect:

- full response
- partial response
- empty response
- malformed response
- provider failure

---

# 10. SCENARIO PLANNER

File:
`lib/engine/planners/scenario_planner.dart`

Purpose:
source of testcase intent

Responsibilities:

- enforce 80/20 distribution
- enforce constraint dominance
- define deterministic skeletons
- assign category locks
- preserve testcase intent
- maintain platform realism

Planner Output:

Intent Skeletons

Each contains:

- category
- type
- priority
- platform
- feature
- module
- title intent
- constraint context

---

# 11. CATEGORY LOCKING SYSTEM

Purpose:
prevent testcase drift during repair/fallback

Critical Rule:

negative/security testcase intent MUST NEVER mutate into happy-path testcase.

Protected Fields:

- categoryLock
- constraints
- original intent

Locked Categories:

- Security
- Validation
- Boundary
- Negative
- Session

Repair engine MUST preserve:

- rejection expectations
- failure expectations
- validation intent
- security behavior
- edge-case behavior

---

# 12. PROMPT COMPOSER

File:
`lib/engine/prompts/prompt_composer.dart`

Purpose:
convert deterministic skeletons into controlled AI prompts

Responsibilities:

- inject category intent
- inject platform rules
- inject constraints
- reduce hallucinations
- reduce drift
- enforce schema structure

Rules:

- JSON only
- strict schema
- realistic QA terminology
- no generic wording
- no backend wording for UI tests

---

# 13. VALIDATION SYSTEM

## STRUCTURAL VALIDATOR

Purpose:
hard schema integrity enforcement

Checks:

- required fields
- valid IDs
- non-empty steps
- export-safe structure
- step count integrity
- invariant schema order

---

## SEMANTIC VALIDATOR

Purpose:
detect garbage AI outputs

Detects:

- robotic phrasing
- meaningless wording
- repetitive structure
- duplicate testcase intent
- placeholder content

Banned Examples:

- "works correctly"
- "system processes successfully"
- "click button"
- "enter details"

Platform-aware rules apply.

---

## EXPORT SAFETY VALIDATOR

Purpose:
final invariant firewall

Checks:

- export-safe schema
- invariant ordering
- step integrity
- required field preservation
- mapper compatibility

---

# 14. DETERMINISTIC REPAIR ENGINE

File:
`lib/engine/recovery/deterministic_repair.dart`

Purpose:
repair malformed output WITHOUT additional AI calls

Responsibilities:

- normalize titles
- repair steps
- inject missing structure
- restore category intent
- preserve negative expectations
- normalize wording
- repair placeholders

NEVER:

- call AI again
- remove locked intent
- convert negative to positive flow
- invent unrelated business logic

---

# 15. PARTIAL SUITE EXPANSION

File:
`lib/engine/recovery/partial_suite_expander.dart`

Purpose:
preserve valid AI outputs while filling missing cases deterministically

Example:

AI returned:
6 valid cases out of 10

Pipeline:

- preserve 6 valid
- generate only missing 4

Benefits:

- lower drift
- preserves provider realism
- reduces unnecessary regeneration
- better forensic visibility

---

# 16. DETERMINISTIC FALLBACK GENERATOR

File:
`lib/engine/recovery/deterministic_case_generator.dart`

Purpose:
generate realistic fallback cases when AI fails

Triggers:

- 429 retry exhausted
- 503 retry exhausted
- empty response
- unusable malformed response
- catastrophic parse failure

Rules:

- deterministic only
- platform-aware
- constraint-aware
- preserve category intent
- preserve 80/20 distribution
- preserve realism quality

Generated cases MUST:

- look enterprise-grade
- match platform terminology
- match feature intent
- avoid robotic structure

Users MUST NEVER detect fallback origin visually.

---

# 17. QA REALISM ENFORCER

Purpose:
remove AI-looking phrasing

Responsibilities:

- enforce enterprise QA wording
- vary sentence structures
- humanize action wording
- enforce platform terminology

Rules:

Web/Mobile:
→ UX terminology

API:
→ protocol terminology

Avoid:

- robotic phrasing
- repetitive wording
- generic actions

---

# 18. FORENSIC PIPELINE SYSTEM

Purpose:
production-grade debugging visibility

Files:

- pipeline_event.dart
- pipeline_audit_logger.dart
- pipeline_audit_report.dart

Tracks:

- provider latency
- retries
- repair operations
- validation failures
- fallback triggers
- partial expansion
- export failures

Internal forensic logs preserve:

- AI response status
- recovery mode
- repair history
- fallback origin
- routing decisions

These logs are INTERNAL ONLY.

Users NEVER see them.

---

# 19. TESTCASE EXECUTION WORKFLOW

QA Genie intentionally mirrors real QA execution workflow.

Generated testcases are considered:

PRE-EXECUTION TEST ASSETS

Meaning:

- execution has NOT happened yet
- tester must execute manually
- tester records execution outcome
- tester owns final execution reporting

---

## Actual Result Rules

Field:
`actualResult`

Default Value:
empty string

Purpose:

- intentionally blank before execution
- filled manually during QA execution
- preserves authentic QA workflow

System MUST NEVER:

- auto-fill actual results
- invent execution outcomes
- generate fake execution observations

---

## Status Rules

Field:
`status`

Default Value:

`Not Executed`

Allowed Values:

- Not Executed
- PASS
- FAIL
- BLOCKED
- SKIPPED

Purpose:

reflect real execution lifecycle.

Generated cases ALWAYS start as:

`Not Executed`

---

## Editable Workflow System

ALL testcase fields remain editable by user at ALL times.

Editable Everywhere:

- preview screen
- master table
- summary report
- export preview
- saved suites

Editable Fields Include:

- title
- preconditions
- testData
- steps
- expectedResult
- actualResult
- status
- priority
- type

---

## Master Source Synchronization

Architecture Rule:

single editable source of truth

Meaning:

- edits auto-sync to canonical master state
- exports read latest edited values
- summary screens read latest edited values
- suite persistence stores latest edited values

There MUST NEVER be:

- stale export copies
- detached preview state
- duplicated testcase state
- independent screen-level testcase versions

Canonical Authority:

`FinalizedTestCase`

---

# 20. SINGLE SOURCE OF TRUTH

Canonical Entity:
FinalizedTestCase

ALL exports map ONLY from:

FinalizedTestCase

Invariant Fields:

- id
- title
- preconditions
- testData
- steps
- expectedResult
- actualResult
- priority
- status
- type

Field order MUST NEVER mutate.

---

# 21. EXPORT SYSTEM

## EXPORT MAPPER

Single mapping authority.

Formats:

- Excel
- PDF
- Jira CSV
- Xray JSON

Purpose:

prevent export drift.

---

## EXPORT ADAPTERS

### CSV Adapter

Jira-compatible CSV

### JSON Adapter

Xray-compatible JSON

### PDF Adapter

Deterministic paginated PDF export

### Excel Adapter

Enterprise spreadsheet export

Rules:

- exports NEVER mutate schema
- exports NEVER invent fields
- exports ALWAYS preserve invariant ordering

---

# 22. DATABASE ARCHITECTURE

Primary:
SQLite

Tables:

- suites
- test_cases
- forensic_logs
- usage_metrics

Rules:

- deterministic migrations
- mutex-safe writes
- schema versioning mandatory
- rollback-safe persistence

Future:

heavy writes may move to isolates.

---

# 23. ENVIRONMENT SYSTEM

ONLY TWO MODES:

- DEV
- PROD

NO:

- staging
- hybrid enforcement
- partial production modes

---

## DEV MODE

Purpose:
internal development/testing

Behavior:

- verbose logs
- relaxed security
- local authority
- mock rewards
- mock quotas

Pipeline remains identical.

---

## PROD MODE

Purpose:
real production enforcement

Behavior:

- server authority mandatory
- app check mandatory
- cloud quotas mandatory
- abuse detection enabled
- PII scrubbing enabled

---

# 24. SECURITY MODEL

Architecture:
Zero-Trust Client

Client NEVER authoritative for:

- rewards
- quotas
- entitlement
- generation authorization

Authority:
Firebase Cloud Functions

---

## SECURITY BRIDGE

Single security gateway.

Responsibilities:

- token validation
- quota validation
- entitlement verification
- reward verification
- environment separation

---

## APP CHECK

Production Requirements:

- Firebase App Check
- Play Integrity
- App Attest

Purpose:
prevent tampered clients.

---

## PII SCRUBBER

Purpose:
prevent sensitive data leakage

Detects:

- emails
- API keys
- tokens
- UUIDs
- sensitive identifiers

Runs BEFORE prompt generation.

---

## SECURITY FILTER

Purpose:
prevent prompt injection

Responsibilities:

- malicious instruction stripping
- dangerous payload filtering
- payload size enforcement
- prompt sanitation

---

# 25. TESTCASE IDENTITY RULES

Users NEVER see:

- fallback labels
- repair labels
- AI source labels
- recovery labels

Testcase IDs ALWAYS follow:

`TC_{MODULE}_{INDEX}`

Example:

`TC_LOGIN_001`

This rule applies to:

- AI outputs
- repaired outputs
- fallback outputs
- expanded outputs

Internal forensic metadata separately preserves true origin.

---

# 26. LONG-TERM ARCHITECTURE GOAL

Architecture must remain:

- observable
- auditable
- deterministic
- modular
- replaceable
- solo-maintainable

Future provider swaps:

- Gemini
- OpenAI
- local models

must require changing ONLY:

- AI stage
- parser layer

Entire engine must remain stable independently of provider.

## QA Genie core structure

QA_Genie:
└── lib/
├── app/
│ ├── app.dart
│ ├── config/
│ │ └── app_config.dart
│ ├── router/
│ │ └── app_router.dart
│ ├── startup/
│ │ └── app_dependencies.dart
│ └── theme/
│ ├── app_colors.dart
│ ├── app_radius.dart
│ ├── app_spacing.dart
│ ├── app_text.dart
│ ├── app_theme.dart
│ └── premium_theme.dart
├── core/
│ ├── config/
│ │ └── app_environment.dart
│ ├── constants/
│ │ └── app_limits.dart
│ ├── database/
│ │ ├── database_service.dart
│ │ ├── dump_writer.dart
│ │ └── migrations/
│ │ └── schema_v1.dart
│ ├── error/
│ │ ├── exceptions.dart
│ │ ├── ui_error_service.dart
│ │ └── ui_error_store.dart
│ ├── network/
│ │ ├── api_client.dart
│ │ ├── cloud_authority_service.dart
│ │ └── connectivity_service.dart
│ ├── security/
│ │ ├── anti_abuse_heuristics.dart
│ │ ├── pii_scrubber.dart
│ │ ├── security_bridge.dart
│ │ └── security_filter.dart
│ └── utils/
│ ├── dialog_utils.dart
│ ├── finalized_test_case_adapter.dart
│ ├── id_generator.dart
│ ├── platform_utils.dart
│ ├── priority_utils.dart
│ ├── stable_hash.dart
│ └── test_data_factory.dart
├── data/
│ ├── datasources/
│ │ └── local/
│ │ └── local_db_source.dart
│ ├── dto/
│ │ └── generation_dto.dart
│ ├── models/
│ │ └── test_case_model.dart
│ └── repositories/
│ ├── export_repository.dart
│ └── suite_repository.dart
├── domain/
│ ├── entities/
│ │ ├── finalized_test_case.dart
│ │ ├── test_case.dart
│ │ ├── test_step.dart
│ │ └── test_suite.dart
│ ├── enums/
│ │ ├── case_source.dart
│ │ ├── execution_intent.dart
│ │ ├── export_format.dart
│ │ ├── generation_mode.dart
│ │ └── test_case_origin.dart
│ └── usecases/
│ ├── export_test_cases_use_case.dart
│ ├── export_validation_service.dart
│ ├── generate_test_cases_use_case.dart
│ ├── get_history_use_case.dart
│ └── save_suite_use_case.dart
├── engine/
│ ├── adapters/
│ │ └── platform_adapter.dart
│ ├── builders/

    │   ├── business/
    │   │   └── business_area.dart
    │   ├── expected_result/
    │   │   └── composer.dart
    │   ├── flows/
    │   │   ├── generic_flow.dart
    │   │   └── scenario_expander.dart
    │   ├── forensics/
    │   │   ├── models/
    │   │   │   └── pipeline_event.dart
    │   │   ├── pipeline_audit_logger.dart
    │   │   ├── pipeline_audit_report.dart
    │   │   ├── pipeline_observer.dart
    │   │   └── trace_id_generator.dart
    │   ├── generators/
    │   │   └── data_generator.dart
    │   ├── humanization/
    │   │   └── qa_heuristics_engine.dart
    │   ├── knowledge/

    │   ├── models/
    │   │   ├── generation_outcome.dart
    │   │   └── pipeline_models.dart
    │   ├── observations/
    │   │   └── observation_generator.dart
    │   ├── orchestration/
    │   │   ├── pipeline_orchestrator.dart
    │   │   └── stages/
    │   │       ├── ai_generation_stage.dart
    │   │       ├── coverage_analysis_stage.dart
    │   │       ├── fallback_stage.dart
    │   │       ├── finalization_stage.dart
    │   │       ├── parsing_stage.dart
    │   │       ├── repair_stage.dart
    │   │       └── validation_stage.dart
    │   ├── parsers/
    │   │   ├── ai_response_parser.dart
    │   │   ├── malformed_json_salvager.dart
    │   │   ├── partial_case_extractor.dart
    │   │   ├── response_classifier.dart
    │   │   └── schema_normalizer.dart
    │   ├── planners/
    │   │   ├── coverage_planner.dart
    │   │   └── prompt_planner.dart
    │   ├── prompts/
    │   │   ├── prompt_cache_manager.dart
    │   │   ├── prompt_composer.dart
    │   │   └── system_prompt.dart
    │   ├── recovery/
    │   │   ├── ai_repair_engine.dart
    │   │   ├── deterministic_case_generator.dart
    │   │   └── partial_suite_expander.dart
    │   ├── scenario/
    │   │   ├── scenario_engine.dart
    │   │   └── scenario_rules.dart
    │   ├── services/
    │   │   └── generation_metrics.dart
    │   ├── title/
    │   │   └── title_composer.dart
    │   ├── utils/
    │   │   └── pdf_text_sanitizer.dart
    │   └── validators/
    │       ├── export_safety_validator.dart
    │       ├── realism_validator.dart
    │       ├── semantic_validator.dart
    │       └── structural_validator.dart
    ├── features/
    │   ├── auth/
    │   │   └── ui/
    │   │       └── auth_screen.dart
    │   ├── beta/
    │   │   ├── logic/
    │   │   │   └── beta_manager.dart
    │   │   └── ui/
    │   │       └── beta_expired_screen.dart
    │   ├── bugs/
    │   │   └── ui/
    │   │       └── bug_report_overlay.dart
    │   ├── export/
    │   │   ├── adapters/
    │   │   │   ├── csv_adapter.dart
    │   │   │   ├── excel_adapter.dart
    │   │   │   ├── json_adapter.dart
    │   │   │   └── pdf_adapter.dart
    │   │   ├── common/
    │   │   │   └── export_mapper.dart
    │   │   ├── folder/
    │   │   │   └── export_folder_service.dart
    │   │   └── writers/
    │   │       ├── file_writer.dart
    │   │       └── share_service.dart
    │   ├── forensics/
    │   │   ├── diagnostics_persistence_service.dart
    │   │   └── production_diagnostics_screen.dart
    │   ├── generation/
    │   │   └── ui/
    │   │       ├── screens/
    │   │       │   └── home_screen.dart
    │   │       └── widgets/
    │   │           └── master_table.dart
    │   ├── monetization/
    │   │   ├── ads/
    │   │   │   └── ad_service.dart
    │   │   ├── logic/
    │   │   │   └── usage_manager.dart
    │   │   └── ui/
    │   │       ├── rate_us_dialog.dart
    │   │       ├── test_mode_screen.dart
    │   │       ├── upgrade_coming_soon_screen.dart
    │   │       └── upgrade_screen.dart
    │   ├── suites/
    │   │   └── ui/
    │   │       └── screens/
    │   │           ├── suite_preview_screen.dart
    │   │           └── suites_screen.dart
    │   └── summary/
    │       └── ui/
    │           ├── summary_report_preview_screen.dart
    │           └── summary_report_screen.dart
    ├── firebase/
    │   ├── analytics/
    │   │   └── analytics_service.dart
    │   ├── app_check/
    │   │   └── app_check_service.dart
    │   ├── cloud_functions/
    │   │   └── functions_service.dart
    │   └── firebase_options.dart
    ├── main.dart
    └── shared/
        ├── animations/
        │   └── shimmer_loading.dart
        ├── badges/
        │   └── pro_badge.dart
        ├── dialogs/
        │   ├── export_bottom_sheet.dart
        │   ├── export_preview_dialog.dart
        │   ├── export_success_dialog.dart
        │   └── guidelines_dialog.dart
        ├── effects/
        │   └── press_effect.dart
        ├── navigation/
        │   └── main_screen.dart
        └── widgets/
            └── qa_button.dart

firebase:
QA_Genie:
└── functions/
├── index.js
├── package-lock.json
└── package.json

FORENSIC TESTS FOR DEVLOPMENT AND TESTING/
lib:
└── test/
└── forensic_tests/
├── headless/
│ ├── exports/
│ │ └── full_export_test.dart
│ ├── generation/
│ │ ├── generation_pipeline_test.dart
│ │ └── live_mass_generation_test.dart
│ └── inputs/
│ └── generation_inputs.dart
├── support/
│ ├── forensic_runner.dart
│ └── live_http.dart
└── test_results/
├── export_files/
└── gen_results/
├── core_analytical_logs.txt
├── core_pipeline.txt
├── pro_analytical_logs.txt
└── pro_pipeline.txt
