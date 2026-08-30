# nix-pandoc-bin

A Nix flake distributing pre-built `pandoc` executables straight from [jgm/pandoc releases](https://github.com/jgm/pandoc/releases).
No compiling Haskell.

Created because nixpkgs' own `pandoc` package lags behind upstream releases.
See [NixOS/nixpkgs#461018](https://github.com/NixOS/nixpkgs/issues/461018).

## Layout

- `version.txt` — the pandoc version, read via `builtins.readFile`.
- `hashes.json` — `nixpkgs-platform -> sha256 (SRI)` map of each platform's release asset.
  Hashed as unpacked with `fetchzip`, i.e. `nix-prefetch-url --unpack`.
- `flake.nix` — a constant attrset maps each supported `nixpkgs` platform to its asset filename suffix on the release page.
  It builds the download URL from that and fetches/repackages it as `packages.<system>.default`.

Supported systems: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`.
`x86_64-darwin` is **not** supported.
nixpkgs dropped it in the 26.11 unstable branch, so `import nixpkgs { system = "x86_64-darwin"; }` fails at eval time.
See the [26.11 release notes](https://nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.11).

## Automation

- `.github/workflows/update-pandoc.yml` — every 3 hours, checks for a new pandoc release.
  If found, it bumps `version.txt`/`hashes.json` and commits.
- `.github/workflows/update-flake-inputs.yml` — daily `nix flake update --commit-lock-file`.
  Gated on `nix flake check` passing.
