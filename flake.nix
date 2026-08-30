{
  description = "Pre-built pandoc executables, fetched directly from https://github.com/jgm/pandoc/releases";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    let
      # Single source of truth for the pandoc version, kept in its own file
      # so the update workflow can bump it with a plain text edit.
      version = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ./version.txt);

      # nixpkgs-platform -> sha256 (SRI) of that platform's release asset.
      hashes = builtins.fromJSON (builtins.readFile ./hashes.json);

      # nixpkgs-platform -> the platform-specific suffix of the asset file
      # name, as it appears on https://github.com/jgm/pandoc/releases/tag/${version}
      # (every asset is named "pandoc-${version}-${suffix}").
      platformAssetSuffixes = {
        x86_64-linux = "linux-amd64.tar.gz";
        aarch64-linux = "linux-arm64.tar.gz";
        aarch64-darwin = "arm64-macOS.zip";
      };

      assetUrl = suffix: v: "https://github.com/jgm/pandoc/releases/download/${v}/pandoc-${v}-${suffix}";

      # nixpkgs-platform -> function producing the download URL for a given version.
      platformUrls = builtins.mapAttrs (_: assetUrl) platformAssetSuffixes;
    in
    flake-utils.lib.eachSystem (builtins.attrNames platformUrls) (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # fetchzip unpacks the archive (zip or tar.gz, both are supported)
        # and strips the single top-level "pandoc-${version}[-arch]/" directory,
        # so $src already contains "bin/" and "share/" directly.
        src = pkgs.fetchzip {
          url = platformUrls.${system} version;
          hash = hashes.${system};
        };
      in
      {
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          pname = "pandoc-bin";
          inherit version src;

          outputs = [ "out" "man" ];

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp -r bin $out/bin
            chmod +x $out/bin/*
            if [ -d share ]; then
              cp -r share $out/share
            fi

            runHook postInstall
          '';

          meta = {
            description = "Pandoc, a universal document converter (upstream pre-built binary)";
            homepage = "https://pandoc.org";
            downloadPage = "https://github.com/jgm/pandoc/releases/tag/${version}";
            license = pkgs.lib.licenses.gpl2Plus;
            sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
            platforms = builtins.attrNames platformUrls;
            mainProgram = "pandoc";
          };
        };
      }
    )
    // {
      # Exposed so the update workflow can build asset URLs itself without
      # duplicating this platform -> filename-suffix mapping in bash/jq.
      lib.platformAssetSuffixes = platformAssetSuffixes;
    };
}
