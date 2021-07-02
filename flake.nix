{
  description = "Nix tools for Solana";

  inputs = {
    solana-bin-src = {
      url = https://github.com/solana-labs/solana/releases/download/v1.7.1/solana-release-x86_64-unknown-linux-gnu.tar.bz2;
      flake = false;
    };
    solana-src = {
      url = github:drozdziak1/solana/toolchain-envs;
      flake = false;
    };
    cargo2nix = {
      url = github:cargo2nix/cargo2nix;
      flake = false;
    };
    rust-overlay = {
      url = github:oxalica/rust-overlay;
    };
  };

  outputs = { self, nixpkgs, solana-bin-src, solana-src, rust-overlay, cargo2nix }:
    (
      let
        system = "x86_64-linux";
        rustChannel = "1.52.0";
        bpfToolsVersion = "v1.8";
        cargo2nix-imported = pkgs.callPackage cargo2nix { inherit rust-overlay rustChannel; };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlay
            (import "${cargo2nix}/overlay")
          ];
        };

        # The symlinks in solana's source directory upset the later cargo2nix nbuild
        solana-src-hardlinked = pkgs.stdenv.mkDerivation {
          name = "solana-src-hardlinked";
          src = solana-src;
          phases = "unpackPhase buildPhase installPhase";
          buildInputs = with pkgs; [ bash coreutils ];
          buildPhase = ''
            find -type l -exec bash -c 'ln -f "$(readlink -m "$0")" "$0"' {} \;
          '';
          installPhase = ''cp -r . $out'';
        };
        solana-sdk = pkgs.rustBuilder.makePackageSet' {
          inherit rustChannel;
          packageFun = import ./Cargo.solana.nix;
          workspaceSrc = solana-src-hardlinked;
          packageOverrides = pkgs: pkgs.rustBuilder.overrides.all ++ [
            (
              pkgs.rustBuilder.rustLib.makeOverride {
                name = "add-jemalloc";
                overrideAttrs = oa: {
                  propagatedNativeBuildInputs =
                    oa.propagatedNativeBuildInputs or [] ++ (
                      with pkgs; [
                        jemalloc
                      ]
                    );
                };
              }
            )
          ];
        };
      in
        {

          packages."${system}" = {
            # Inject customized cargo-build-bpf build from sources
            cargo-build-bpf = (solana-sdk.workspace.solana-cargo-build-bpf {}).bin;
            solana-bpf-tools-bin = pkgs.callPackage (
              import
                ./solana-bpf-tools-bin.nix
            ) {
              solana-bpf-tools-bin-src = builtins.fetchurl {
                url = "https://github.com/solana-labs/bpf-tools/releases/download/${bpfToolsVersion}/solana-bpf-tools-linux.tar.bz2";
                sha256 = "sha256:104m1c584085dmqsbg1gvcjr55yvnl9nf7yfd5pbrixhm418rn94";
              };
            };
            solana-bpf-tools-rust = pkgs.stdenv.mkDerivation {
              src = self.packages."${system}".solana-bpf-tools-bin;
              name = "solana-bpf-tools-rust";
              installPhase = ''
                cp -r rust $out
              '';
              fixupPhase = "true";
            };
            solana-bin = pkgs.callPackage ./solana-bin.nix {
              inherit solana-bin-src bpfToolsVersion;
              cargo-build-bpf = self.packages."${system}".cargo-build-bpf;
              solana-bpf-tools = self.packages."${system}".solana-bpf-tools-bin;
            };
          };
          defaultPackage."${system}" = self.packages."${system}".solana-bin;

          devShell."${system}" = pkgs.mkShell {
            buildInputs = with pkgs; [ rust-bin.stable."${rustChannel}".default libudev openssl cargo2nix-imported.package ];
          };
          overlay = final: prev: rec {
            inherit (self.packages."${system}") solana-bpf-tools-rust;
            solanaRustChannel = {
              cargo = solana-bpf-tools-rust;
              rustc = solana-bpf-tools-rust;
              rust-src = null;
            };
          };
        }
    );
}
