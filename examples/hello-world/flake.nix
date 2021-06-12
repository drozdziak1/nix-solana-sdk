{
  description = "example packaging of a trivial Solana program";
  inputs = {
    nix-solana-sdk =
      {
        url = path:./../..;
      };
    cargo2nix = {
      url = github:cargo2nix/cargo2nix;
      flake = false;
    };
    rust-overlay = {
      url = github:oxalica/rust-overlay;
    };
  };

  outputs = { self, nixpkgs, nix-solana-sdk, cargo2nix, rust-overlay }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        crossSystem = "bpfel-none-none-none";
        overlays =
          [
            rust-overlay.overlay
            (import "${cargo2nix}/overlay")
            nix-solana-sdk.overlay # Hey kids, you need rust-overlay and cargo2nix as well!
          ];
      };
    in
      {
        packages."${system}" = {
          hello-world = (
            pkgs.rustBuilder.makePackageSet {
              rustChannel = pkgs.solanaRustChannel;
              packageFun = import ./Cargo.nix;
              workspaceSrc = ./.;
            }
          ).workspace.hello-world {};
        };
        defaultPackage."${system}" = self.packages."${system}".hello-world;
      };
}
