## ADDED Requirements
### Requirement: Self-Contained App Bundle
The packaging script SHALL produce an app bundle that embeds Sparkle.framework, resolves it through the `@executable_path/../Frameworks` rpath, and is signed inside-out so `codesign --verify --strict` passes.

#### Scenario: Package
- **WHEN** `scripts/package.sh` runs
- **THEN** `Snapr.app/Contents/Frameworks/Sparkle.framework` exists, the app launches, and the signature verifies

### Requirement: No Committed Secrets
The repository SHALL NOT contain signing keys; the EdDSA public key, feed URL and signing identity SHALL be supplied by environment variables at release time.

#### Scenario: Missing configuration
- **WHEN** `SU_FEED_URL` or `SU_PUBLIC_ED_KEY` is unset
- **THEN** the package script still builds, omits the Sparkle keys, and warns that updates are disabled

### Requirement: Appcast Generation
The repository SHALL provide a script that generates an EdDSA-signed `appcast.xml` from a directory of release archives.

#### Scenario: Generate
- **WHEN** the maintainer runs `scripts/make-appcast.sh <dir>` with the private key available
- **THEN** `appcast.xml` is written to that directory

### Requirement: Homebrew Cask
The repository SHALL provide a cask template and a script rendering it with a release version and DMG checksum, declaring `auto_updates true`.

#### Scenario: Render
- **WHEN** `scripts/render-cask.sh <dmg> <version>` runs
- **THEN** it prints a cask with the DMG's sha256 and version, with valid Ruby syntax
