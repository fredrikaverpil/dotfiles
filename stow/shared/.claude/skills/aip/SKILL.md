---
name: aip
description: Google API Improvement Proposals (AIP) reference. Use BEFORE designing or reviewing APIs, protobuf definitions, or any work involving Google API design standards. Fetches relevant AIP rules from https://google.aip.dev for the task at hand.
---

# Google API Improvement Proposals (AIP)

When working on API design, protobuf definitions, or any task involving Google
API standards, refresh your understanding of the relevant AIP rules.

## Critical Rule

**NEVER assume you know what an AIP rule says from memory.** Always fetch and
read the actual AIP documentation before applying or referencing any rule. Your
memory of AIP rules may be inaccurate or outdated.

## Process

1. **Browse the AIP index** - Go to https://google.aip.dev/general to see all
   available AIP guidelines
2. **Identify relevant AIPs** - Based on the task at hand, determine which AIP
   rules may apply
3. **Fetch and read the relevant AIPs** - Use WebFetch to retrieve the specific
   AIP pages. Do NOT skip this step, even if you think you know what the rule
   says
4. **Apply the standards** - Ensure your work follows the AIP guidelines as
   documented

## When to Invoke This Skill

- Designing new API endpoints or protobuf messages
- Reviewing API changes in PRs
- Implementing resource-oriented services
- Naming fields, methods, or resources
- Working with `google.api` annotations
