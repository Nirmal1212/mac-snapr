# Spec Delta

## Purpose
Keep the public landing page accurate and consistent with the shipped build, its release notes and the README.

## ADDED Requirements

### Requirement: Release Status Accuracy
The landing page SHALL describe the app's release status as it is published, naming the current beta version and labelling it as a beta, and SHALL NOT state that no release has shipped once a release exists.

#### Scenario: Beta published
- **WHEN** a visitor opens the landing page and a beta release exists on the Releases page
- **THEN** the page shows a "Beta" label near the hero and the current version name, and contains no text saying no release has shipped

### Requirement: Privacy and Update Statements Match the Build
The landing page SHALL state network and update behavior exactly as the current release notes do, and SHALL describe update checks as unavailable in a build that ships without a Sparkle feed.

#### Scenario: Beta without update feed
- **WHEN** the current release notes say the beta has no automatic updates and no network access
- **THEN** the privacy section and FAQ say the same, and do not claim a daily update check or an optional update check in that build

### Requirement: Install Guidance Is Complete
The landing page SHALL give the concrete current DMG file name, the supported chip types, the Gatekeeper steps, the Accessibility grant, and the known need to re-grant Accessibility after each ad-hoc-signed update.

#### Scenario: Install section
- **WHEN** a visitor reads the install section
- **THEN** it names `Snapr-0.1.0-beta.2.dmg` (or the current version), says Apple silicon and Intel are supported, and explains how to re-grant Accessibility after updating

#### Scenario: Single Gatekeeper source
- **WHEN** the FAQ addresses the macOS first-launch warning
- **THEN** it links to the Install section instead of repeating the steps

### Requirement: Social Preview Metadata
The landing page SHALL provide Open Graph and Twitter card metadata with an absolute canonical URL and an absolute image URL.

#### Scenario: Link shared on LinkedIn
- **WHEN** the site URL is pasted into a social network
- **THEN** the preview shows the title, description and a large image resolved from `https://nirmal1212.github.io/mac-snapr/`

### Requirement: Docs Consistency
The README and `site/README.md` SHALL NOT contradict the landing page about release status, install steps or screenshots.

#### Scenario: Release status
- **WHEN** a release exists
- **THEN** the README status line and the site pre-launch checklist reflect it
