{
  description = "Minimal reproduction for Genie failing on symlinked repo-relative imports";

  inputs = {
    effect-utils.url = "github:overengineeringstudio/effect-utils";
    nixpkgs.follows = "effect-utils/nixpkgs";
    flake-utils.follows = "effect-utils/flake-utils";
  };

  outputs =
    {
      self,
      effect-utils,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        genie = effect-utils.packages.${system}.genie;
      in
      {
        apps.repro = {
          type = "app";
          program = "${pkgs.writeShellApplication {
              name = "repro";
              runtimeInputs = [
                genie
                pkgs.coreutils
                pkgs.gnugrep
              ];
              text = ''
                set -euo pipefail

                tmpdir="$(mktemp -d)"
                cleanup() {
                  rm -rf "$tmpdir"
                }
                trap cleanup EXIT

                mkdir -p "$tmpdir/real-repo" "$tmpdir/linked"
                cp ${self}/fixtures/package.json.genie.ts "$tmpdir/real-repo/package.json.genie.ts"
                ln -s ../real-repo "$tmpdir/linked/repo"
                ln -s ${effect-utils} "$tmpdir/linked/effect-utils"

                set +e
                output="$(${genie}/bin/genie --cwd "$tmpdir/linked/repo" --writeable --output json 2>&1)"
                status=$?
                set -e

                printf '%s\n' "$output"

                if [ "$status" -eq 0 ]; then
                  echo "expected genie to fail, but it succeeded" >&2
                  exit 1
                fi

                printf '%s\n' "$output" | grep -F "GenieImportError:" >/dev/null || {
                  echo "genie failed, but not with a GenieImportError" >&2
                  exit 1
                }

                printf '%s\n' "$output" | grep -F "Cannot find module '../effect-utils/genie/external.ts'" >/dev/null || {
                  echo "genie failed, but not with the expected symlinked import error" >&2
                  exit 1
                }

                printf '%s\n' "repro confirmed"
              '';
            }}/bin/repro";
        };
      }
    );
}
