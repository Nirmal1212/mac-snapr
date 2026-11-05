# Releasing Snapr

Nothing here is automated end to end on purpose: keys and uploads stay with the maintainer.

## One-time setup

1. **Sparkle EdDSA keys.** After `swift package resolve`, run the tool Sparkle ships:
   ```bash
   .build/artifacts/sparkle/Sparkle/bin/generate_keys        # stores the private key in your login keychain
   .build/artifacts/sparkle/Sparkle/bin/generate_keys -p     # prints the PUBLIC key
   ```
   Keep the private key out of the repository. Back it up (`generate_keys -x <file>` exports it) in a password manager.
   For CI, store the exported key as a secret and write it to a temp file for `SPARKLE_ED_KEY_FILE`.
2. **Developer ID** certificate in your keychain, and a `notarytool` keychain profile
   (`xcrun notarytool store-credentials snapr-notary`).
3. **Hosting.** Decide where `appcast.xml` is served (HTTPS only; e.g. GitHub Pages) and set the real owner in
   `packaging/homebrew/snapr.rb.template`.

## Cut a release

```bash
export VERSION=0.2.0
export BUILD_NUMBER=2                                  # must increase every release (Sparkle compares it)
export SIGN_IDENTITY="Developer ID Application: Name (TEAMID)"
export SU_FEED_URL=https://example.com/snapr/appcast.xml
export SU_PUBLIC_ED_KEY=<public key from generate_keys -p>
scripts/package.sh                                     # dist/Snapr.app + dist/Snapr-$VERSION.dmg
```

`package.sh` embeds `Sparkle.framework` in `Contents/Frameworks`, adds the `@executable_path/../Frameworks` rpath,
and signs inside-out (Autoupdate, Updater.app, framework, app). Without `SU_FEED_URL` and `SU_PUBLIC_ED_KEY` it
warns and builds with updates disabled. With the default ad-hoc identity the hardened runtime is off, because
library validation would otherwise reject Sparkle; only Developer ID builds are notarizable.

Notarize and staple (the DMG, then the app inside is covered by the ticket):

```bash
xcrun notarytool submit dist/Snapr-$VERSION.dmg --keychain-profile snapr-notary --wait
xcrun stapler staple dist/Snapr-$VERSION.dmg
```

Generate the appcast from a folder holding every released DMG you want to offer:

```bash
mkdir -p release && cp dist/Snapr-$VERSION.dmg release/
scripts/make-appcast.sh release https://github.com/OWNER/mac-snapr/releases/download/v$VERSION/
# writes release/appcast.xml, signed with your private key
```

Upload the DMG to the GitHub Release and `appcast.xml` to the feed location.

## Homebrew cask

```bash
scripts/render-cask.sh dist/Snapr-$VERSION.dmg $VERSION > Casks/snapr.rb   # in your tap checkout
brew audit --cask --new Casks/snapr.rb && brew install --cask ./Casks/snapr.rb
```

The cask declares `auto_updates true` because Sparkle updates the app in place.

## Notes

- `SUEnableAutomaticChecks` is intentionally not set, so Sparkle asks users for permission with its own prompt before checking automatically.
- `softprops/action-gh-release` is pinned to the commit behind `v2` (verified with `ls-remote`); re-verify when bumping.
- Updates are the only network use. Users can turn automatic checks off in Settings.
- Never commit private keys, exported key files or notarization credentials.
- The CI release job reads the public repository variables `SU_FEED_URL` and `SU_PUBLIC_ED_KEY` and builds with the
  ad-hoc identity. Developer ID signing and notarization in CI would need a certificate secret and are not set up.
  BUILD_NUMBER in CI is the run number; prefer building releases locally until that is settled.
