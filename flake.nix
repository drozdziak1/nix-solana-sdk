{
  description = "A very basic flake";

  inputs = {
    solana-src = {
      url = "github:solana-labs/solana/v1.6.6";
      # url = "/home/drozdziak1/code/rust/solana";
      flake = false;
    };
    solana-rust-src = {
      url = "github:solana-labs/rust/solana-1.50";
      flake = false;
    };
    cargo2nix = { url = "github:cargo2nix/cargo2nix"; flake = false; };
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, solana-src, solana-rust-src, cargo2nix, rust-overlay }:
    (
      let
        system = "x86_64-linux";
        rustVersion = "1.51.0";
        pkgs = import nixpkgs {
          inherit system; overlays = [
          rust-overlay.overlay
          (import "${cargo2nix}/overlay")
        ];
        };
        cargo2nix-imported = pkgs.callPackage cargo2nix { inherit rust-overlay; };

        # The symlinks in solana's source directory upset the later cargo2nix nbuild
        solana-src-hardlinked = pkgs.stdenv.mkDerivation {
          name = "solana-src-hardlinked";
          src = solana-src;
          buildInputs = with pkgs; [ bash coreutils ];
          buildPhase = ''
            find -type l -exec bash -c 'ln -f "$(readlink -m "$0")" "$0"' {} \;
          '';
          installPhase = ''cp -r . $out'';
        };
        solana-workspace = pkgs.rustBuilder.makePackageSet' {
          packageFun = import ./Cargo.solana.nix;
          rustChannel = rustVersion;
          workspaceSrc = solana-src-hardlinked;
          packageOverrides = pkgs: pkgs.rustBuilder.overrides.all ++ [
            (
              pkgs.rustBuilder.rustLib.makeOverride {
                name = "add-binutils";
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
            cargo-build-bpf = (solana-workspace.workspace.solana-cargo-build-bpf {}).bin;
            solana-rust = pkgs.callPackage (import ./solana-rust.nix) {inherit solana-rust-src;};
          };

          defaultPackage."${system}" = self.packages."${system}".cargo-build-bpf;

          devShell."${system}" = pkgs.mkShell {
            buildInputs = with pkgs; [ rust-bin.stable."${rustVersion}".default libudev openssl cargo2nix-imported.package ];
          };

        }
    );
}
