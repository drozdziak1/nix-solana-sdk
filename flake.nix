{
  description = "A very basic flake";

  inputs = {
    solana-bin-src = {
      url = "https://github.com/solana-labs/solana/releases/download/v1.6.7/solana-release-x86_64-unknown-linux-gnu.tar.bz2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, solana-bin-src }:
    (
      let
        system = "x86_64-linux";
        rustVersion = "1.51.0";
        pkgs = import nixpkgs { inherit system; };
      in
        {

          packages."${system}" = {
            solana-bpf-tools-bin = pkgs.callPackage (
              import
                ./solana-bpf-tools.nix
            ) {
              solana-bpf-tools-bin-src = builtins.fetchurl {
                url =
                  https://github.com/solana-labs/bpf-tools/releases/download/v1.6/solana-bpf-tools-linux.tar.bz2;
                sha256 = "sha256:1rdr1n18y5ipbqllaiir25h2j9m6yj0dnlv9lxqklx6d5gfvj2i0";
              };
            };
            solana-bin = pkgs.callPackage ./solana-bin.nix { inherit solana-bin-src; };
          };
          defaultPackage."${system}" = self.packages."${system}".solana-bin;
        }
    );
}
