# Changelog

All notable changes to [Product] are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
How to fill this template (read by /changelog; delete these comments in the written file):
- This is the PRODUCT's changelog at docs/CHANGELOG.md — not the framework's CHANGELOG.md at the
  repository root.
- Newest version first, directly below `## [Unreleased]`. Version headings are exactly
  `## [x.y.z] - YYYY-MM-DD` (ISO date); /release-notes finds a version by that heading.
- Categories, in this order: Added, Changed, Deprecated, Removed, Fixed, Security, then
  Breaking / API. Leave out a category with no entries. `### Internal` closes every version section.
- Category entries are the public part: one line per change, written so a user or an API consumer
  understands it, with references in parentheses at the end. `### Internal` is for the team and is
  never copied into customer-facing notes.
- Group related commits into one entry. Never list commits one by one.
-->

## [Unreleased]

## [x.y.z] - YYYY-MM-DD

### Added

- [New capability, stated as what users or API consumers can now do] ([`design/prd/[feature-slug].md`], [story-NNN])

### Changed

- [Change to existing behaviour; for a plan, price, limit or fee change give old → new and the effective
  date] ([references])

### Deprecated

- [Capability or API field that will be removed later, with the removal version or `Sunset` date and the
  replacement] ([references])

### Removed

- [Capability removed in this version] ([references])

### Fixed

- [The user-visible symptom that no longer occurs] ([BUG-NNNN])

### Security

- [Security or privacy fix, without exploit detail] ([finding or advisory reference])

### Breaking / API

- [Breaking change for users or API consumers: what breaks, who is affected, the migration path]
  ([`docs/api/changes/api-change-YYYY-MM-DD.md`])

### Internal

- Commit range: `[first-hash]..[last-hash]` — [N] commits, [M] customer-facing, [K] without a task reference
- Migrations: [`docs/data/migrations/NNNN-[slug].md` — phases shipped | none]
- Feature flags: [`flag.key` — default | none]
- Refactoring, tooling and infrastructure: [one line each]
- Known issues shipped: [BUG-NNNN (S3-Minor) — summary | none]
- Deferred to a later version: [item — reason — new target]

[Unreleased]: [compare URL — omit when the remote URL is not known]
[x.y.z]: [compare URL — omit when the remote URL is not known]
