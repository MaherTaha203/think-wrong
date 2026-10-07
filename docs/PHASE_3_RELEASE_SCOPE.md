# THINK WRONG — Phase 3 Production Release Engineering

## 0. Scope Lock

Phase 3 begins only after Phase 2 Productization / Release Readiness was closed on master.

### In scope

1. Production Android release configuration:
   - production signing configuration without committing secrets;
   - release AAB export;
   - version-code/version-name release policy;
   - release artifact verification.
2. Android release CI:
   - reproducible release build;
   - signing supplied only through protected GitHub secrets/environment;
   - artifact integrity checks;
   - no debug keystore in production workflow.
3. iOS release readiness:
   - validate Godot iOS export configuration;
   - bundle identifier and version policy;
   - identify the required macOS/Xcode/signing inputs;
   - do not claim an iOS build until it is actually exported and verified.
4. Store-readiness audit:
   - Android package/AAB metadata;
   - iOS bundle metadata;
   - privacy/disclosure requirements only where applicable;
   - release assets and metadata required for submission.
5. Release-candidate verification:
   - full regression;
   - graphical QA;
   - Android release artifact;
   - platform-specific smoke checks where execution is available.

### Explicitly out of scope

- New puzzles.
- P01–P05 redesign or tuning without evidence.
- Monetization implementation.
- Ads, analytics, backend, accounts, multiplayer, or virtual currency.
- Unrelated UI polish.
- Changes to ONE LINE.
- Store submission performed without the owner's explicit authorization.
- Committing signing keys, certificates, provisioning profiles, passwords, API tokens, or other secrets.

## 1. Current Baseline

Master is the authoritative baseline. Phase 2 closed with fresh GitHub evidence on the current master merge.

Verified:
- CI regression suite: PASS.
- Web Playtest: PASS.
- Android debug APK export: PASS.
- GitHub Pages deployment: PASS.
- Human/mobile gate: accepted by project decision.
- Application ID: `com.mahertaha.thinkwrong`.
- App version: `0.1.0`.
- Content version: `1`.
- Save-data version: `1`.
- Current Android export is debug APK only.

## 2. Initial Gap Classification

| Area | Status | Classification |
| --- | --- | --- |
| Android production signing | Not implemented | REQUIRED |
| Android AAB export | Not implemented | REQUIRED |
| Production release CI | Not implemented | REQUIRED |
| Release version policy | Not formalized | REQUIRED |
| Release artifact verification | Debug-only today | REQUIRED |
| iOS export configuration | Not present in export presets | REQUIRED for iOS release |
| iOS signing/Xcode execution | External environment required | BLOCKER until macOS/Xcode credentials are available |
| Store submission | Not started | OUT OF SCOPE until release candidate is approved |
| New gameplay/content | None required | OUT OF SCOPE |
| Monetization/analytics/backend | None required | OUT OF SCOPE |

## 3. Release Security Rules

- No signing secret is committed to Git.
- No keystore, certificate, provisioning profile, or password is stored in repository files.
- Debug signing is never reused as production signing.
- CI release jobs fail closed when required signing inputs are absent.
- Release artifacts are generated only from a reviewed commit.
- Production release changes follow branch → PR → CI → review → merge → post-merge verification.

## 4. Phase 3 Gate Order

1. Scope lock — this document.
2. Full release configuration audit.
3. Decide Android release version/code.
4. Implement the smallest Android release configuration.
5. Add protected signing path to CI without secrets in source.
6. Directly verify release export.
7. Run full regression and graphical QA.
8. Verify AAB metadata and artifact integrity.
9. Audit iOS configuration and external requirements.
10. Create a release candidate only after all available platform gates pass.
11. Store submission remains a separate owner-authorized gate.

## 5. Current Decision

Do not bump the public version, add store metadata, or modify gameplay yet.

The first implementation target is the smallest safe **Android production AAB pipeline**, with signing isolated from the repository. iOS remains a parallel release-readiness track and cannot be marked PASS until an actual macOS/Xcode export and signing environment is available.
