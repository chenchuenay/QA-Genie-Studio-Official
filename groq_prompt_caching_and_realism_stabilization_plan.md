# QA Genie — Groq Prompt Stabilization & Realism Phase

## Goal
Stabilize:
- JSON structure
- testcase realism
- deterministic formatting
- parser compatibility
- duplicate reduction
- production consistency

WITHOUT:
- retries
- regeneration loops
- extra API calls
- generation_service.dart rewrites

---

# IMPORTANT REALITY

Groq itself does NOT currently provide Gemini-style native prompt caching.

So for QA Genie:
- we simulate caching locally/backend-side
- reuse a frozen system prompt template
- inject dynamic request data separately

This achieves:
- stable outputs
- lower prompt drift
- more deterministic formatting
- easier debugging

---

# TARGET PRODUCTION ARCHITECTURE

```text
User Input
   ↓
PromptAssembler
   ↓
Frozen System Rules (pseudo-cache)
   ↓
Dynamic User Payload
   ↓
Groq API
   ↓
ResponseParser
   ↓
DeterministicRepair
   ↓
ExportValidator
   ↓
PreviewScreen
```

---

# PHASE 1 — CREATE FROZEN SYSTEM PROMPT

## Create File

```text
lib/core/prompts/system_prompt.dart
```

---

# FULL STRUCTURE

```dart
class SystemPrompt {
  static const String productionRules = r'''
You are a senior QA engineer.

STRICT RULES:

- Return ONLY valid JSON.
- Never use markdown.
- Never explain.
- Never wrap in code blocks.
- Return ONLY a JSON array.
- Every testcase must be unique.
- Use realistic QA workflows.
- Avoid generic wording.
- Use production-level testcases.
- Include edge cases.
- Include validation logic.
- Include negative scenarios.
- Maintain export-safe structure.

REQUIRED JSON STRUCTURE:
[
  {
    "id":"",
    "title":"",
    "module":"",
    "feature":"",
    "platform":"",
    "preconditions":[],
    "steps":[],
    "expectedResult":"",
    "actualResult":"",
    "priority":"High",
    "type":"Functional",
    "status":"Not Executed"
  }
]

STEP RULES:
- Minimum 3 steps.
- Steps must describe real user actions.
- Expected values must be realistic.
- No placeholder text.
- No repeated titles.
- No duplicated steps.
- Use concise QA wording.

REALISM RULES:
- Simulate actual tester behavior.
- Use realistic app flows.
- Validate UI/system reactions.
- Include validation checkpoints.
- Avoid AI-sounding phrases.
- Avoid textbook wording.
- Avoid generic expected results.

OUTPUT:
ONLY RAW JSON ARRAY.
''';
}
```

---

# WHY THIS MATTERS

This becomes your:

```text
pseudo-prompt-cache
```

Meaning:
- exact same instruction order
- exact same structure
- exact same rules
- exact same formatting pressure

Result:
- less parser chaos
- fewer malformed outputs
- more stable testcase quality

---

# PHASE 2 — CREATE PROMPT ASSEMBLER

## Create File

```text
lib/core/prompts/prompt_assembler.dart
```

---

# IMPLEMENTATION

```dart
import 'system_prompt.dart';

class PromptAssembler {
  static String build({
    required String module,
    required String feature,
    required String platform,
    required int count,
    String constraints = '',
  }) {
    return '''
${SystemPrompt.productionRules}

GENERATE:
$count production-level QA testcases.

MODULE:
$module

FEATURE:
$feature

PLATFORM:
$platform

CONSTRAINTS:
$constraints
''';
  }
}
```

---

# PHASE 3 — STOP PROMPT DRIFT

## CURRENT PROBLEM

Most apps:
- concatenate prompts randomly
- mutate wording
- inject unstable formatting
- reorder instructions

This causes:
- unstable JSON
- hallucinations
- schema drift
- random prose

---

# FIX

ALL requests MUST:

```text
use ONE centralized prompt assembler
```

NEVER:
- inline prompt building
- local string concatenation
- screen-specific prompt logic

---

# PHASE 4 — REALISM STABILIZATION

## Current Hidden Problem

AI often generates:

```text
"Verify application works correctly"
```

This sounds fake.

---

# REALISTIC QA STYLE

GOOD:

```text
Tap Login button with valid credentials
Observe dashboard loading state
Verify authenticated user lands on Home screen
```

BAD:

```text
Check system functionality
Ensure application behaves correctly
Validate user can login
```

---

# FIX REALISM USING HARD RULES

Add to prompt:

```text
Avoid generic QA phrases.
Use observable tester actions.
Use measurable validation outcomes.
Describe actual workflow behavior.
```

---

# PHASE 5 — ENFORCE STEP QUALITY

## FILE TO TOUCH

```text
response_parser.dart
```

---

# CURRENT ISSUE

Weak AI outputs survive validation.

---

# ADD VALIDATION

Reject steps containing:

```text
works correctly
behaves correctly
properly
successfully
as expected
```

unless:
- accompanied by measurable validation
- UI state
- data state
- navigation state

---

# EXAMPLE FILTER

```dart
static bool _isGenericStep(String text) {
  final lower = text.toLowerCase();

  const banned = [
    'works correctly',
    'behaves correctly',
    'as expected',
    'properly',
    'successfully',
  ];

  return banned.any(lower.contains);
}
```

---

# PHASE 6 — DIVERSITY ENGINE

## Hidden Current Problem

AI duplicates intent:

```text
Login with valid email
Login with correct email
Login using registered account
```

These are same testcase.

---

# FIX

Before accepting testcase:

normalize:
- title
- first action
- intent
- target behavior

Then reject semantic duplicates.

You already partially do this.

Need stronger normalization.

---

# PHASE 7 — TEMPERATURE STABILIZATION

## FOR GROQ

Use:

```text
temperature: 0.2–0.4
```

NOT:

```text
0.8+
```

Why:

High temperature:
- more creativity
- more malformed JSON
- more hallucinations
- less deterministic structure

QA generation needs:

```text
controlled diversity
```

NOT creativity.

---

# RECOMMENDED PRODUCTION SETTINGS

| Setting | Value |
|---|---|
| temperature | 0.3 |
| max_tokens | 7000–9000 |
| top_p | 0.9 |
| retries | 0 |
| regen | disabled |
| streaming | false |

---

# PHASE 8 — MODEL RECOMMENDATION

## BEST CURRENT CHOICE

### Production:

```text
llama-3.3-70b-versatile
```

Reason:
- stable JSON
- good reasoning
- cheap
- Groq speed
- realistic outputs
- lower hallucination rate

---

## AVOID FOR PROD

```text
llama-3.1-8b
```

Reason:
- weaker reasoning
- repetitive
- generic QA cases
- weaker structure

---

# PHASE 9 — OUTPUT HARDENING

## Add final enforcement before export

Files:

```text
export_mapper.dart
deterministic_repair.dart
```

---

# ENFORCE

- minimum step count
- no empty expected results
- no duplicate titles
- normalized priorities
- stable export schema
- sanitized multiline fields

---

# PHASE 10 — PRODUCTION SUCCESS METRICS

## GOOD TARGETS

| Metric | Target |
|---|---|
| parser success | >95% |
| malformed outputs | <3% |
| duplicate cases | <5% |
| fallback usage | <10% |
| export crashes | 0 |
| average generation | <5 sec |

---

# MOST IMPORTANT RULE

DO NOT:
- add retries
- add multiple provider calls
- add regen loops
- add AI repair calls

Your architecture goal:

```text
ONE CALL → deterministic stabilization → export-safe output
```

THAT is scalable.

---

# PRIORITY EXECUTION ORDER

| Priority | Task |
|---|---|
| P0 | frozen system prompt |
| P0 | centralized prompt assembler |
| P0 | low temperature |
| P1 | realism enforcement |
| P1 | duplicate normalization |
| P1 | parser stabilization |
| P2 | export hardening |
| P2 | metrics logging |

---

# FINAL RESULT

After these changes:

QA Genie becomes:
- deterministic
- scalable
- cheap to operate
- parser-stable
- production-safe
- realistic
- export-safe
- ad-monetizable
- low-maintenance

WITHOUT expensive AI orchestration.

