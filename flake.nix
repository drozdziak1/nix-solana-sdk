{
  description = "A very basic flake";

  inputs = {
    solana-src = {
      url = "github:solana-labs/solana/v1.6.6";
      flake = false;
    };
    cargo2nix = { url = "github:cargo2nix/cargo2nix"; flake = false; };
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, solana-src, cargo2nix, rust-overlay }:
    (
      let
        system = "x86_64-linux";
        cargo2nix = import cargo2nix {
          inherit rust-overlay;
        };
        pkgs = import nixpkgs {
          inherit system; overlays = [
          rust-overlay.overlay
        ];
        };
      in
        {

          packages."${system}".solana-sdk = pkgs.hello;

          defaultPackage."${system}" = self.packages."${system}".solana-sdk;

          devShell."${system}" = pkgs.mkShell {
            buildInputs = with pkgs; [ rust-bin.stable."1.50.0".default libudev openssl ];
          };

        }
    );
}
