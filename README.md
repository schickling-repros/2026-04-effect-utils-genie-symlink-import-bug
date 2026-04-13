# effect-utils Genie - symlinked repo-relative import bug

Genie fails when a `.genie.ts` file is executed from a symlinked repo member and that file imports a sibling path such as `../effect-utils/...`.

## Reproduction

```bash
nix run .#repro
```

## Expected

Genie should preserve the logical `--cwd` path or otherwise resolve relative imports in `.genie.ts` files so sibling paths under the symlinked workspace layout continue to work.

## Actual

Genie resolves the `.genie.ts` file from its physical realpath and the relative import is evaluated from that physical location, which makes the sibling path disappear and produces:

```text
Cannot find module '../effect-utils/genie/external.ts'
```

The repro command exits successfully only after it verifies that exact failure.

## Versions

- effect-utils / genie: `github:overengineeringstudio/effect-utils`
- Nix runtime: current system `nix run`
- OS: reproduced on macOS arm64

## Related Issue

https://github.com/overengineeringstudio/effect-utils/issues/558
