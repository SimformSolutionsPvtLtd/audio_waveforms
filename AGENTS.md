# audio_waveforms: maintainer guide for coding agents

These instructions are for working **on** the package. Guidance for apps that **use** it ships in `skills/audio-waveforms-expert/`.

## Keep these in sync with any change

When a public API, default, platform requirement or known limitation changes, update in the same PR:

1. `README.md` and `doc/documentation.md`.
2. `CHANGELOG.md` (format: `Feature [#n](...) - ...`, `Fixed [#n](...) - ...`).
3. `example/`.
4. **`skills/audio-waveforms-expert/`.** It ships to users with the package, so a stale skill makes their coding agents write broken code. The limitations and symptom tables in `references/troubleshooting.md` cite open issues and PRs: when one is fixed, remove or adjust its row and the matching rule in `SKILL.md`.

## Package skill (`skills/`)

The skill follows [Dart package skills](https://dart.dev/tools/pub/package-skills); users install it with `dart run skills@ get`.

- Directory name = frontmatter `name` = package name with `_` replaced by `-`, then `-<topic>` (`audio-waveforms-expert`). The `skills` CLI skips skills without the prefix.
- Frontmatter holds `name` and `description` only. The description says what the skill does and when to use it (max 1024 characters).
- Keep `SKILL.md` under 500 lines. Task-specific or fast-changing content (tests, limitations, error tables) lives in `references/`, linked from `SKILL.md` with a path relative to the skill root and a note on when to read it.
- State behavior that is verified in `lib/` and the native code, not what the docs claim. Don't label issues "open" in the skill: the text is frozen in the pub archive.
- `skills/` must not be excluded by `.gitignore` or a `.pubignore`.

Examples must compile. Run the snippet check from the package root before merging any change to `skills/`. It extracts every Dart block, analyzes it against this checkout and runs the test snippet:

```bash
dart run tool/check_skill_snippets.dart
```

Validate with [`skills_lint`](https://pub.dev/packages/skills_lint). It needs Dart 3.12 or later, so install it globally instead of adding a dev dependency:

```bash
dart pub global activate skills_lint
dart pub global run skills_lint --ignore-config -d skills --check-relative-paths --check-relative-paths-within-skill=true --published-skill-name --published-skill-name-pubspec_path=pubspec.yaml --pub-archive-includes-skill --check-trailing-whitespace --disallowed-field
```

## Pull requests

Follow `.github/pull_request_template.md`: a Conventional Commit title (`feat:`, `fix:`, `docs:`; add `!` for breaking changes).
