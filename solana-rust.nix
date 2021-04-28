{ pkgs, solana-rust-src }:
let
  attrs-done = pkgs.rustc.overrideAttrs (
    oa: {
      src = solana-rust-src;
    }
  );
  args-done = attrs-done.override { version = "solana"; };
in
args-done
