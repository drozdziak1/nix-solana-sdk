{ stdenv, solana-bpf-tools-bin-src, openssl, zlib, llvmPackages, autoPatchelfHook }:
stdenv.mkDerivation {
  src = solana-bpf-tools-bin-src;
  sourceRoot = ".";
  name = "solana-bpf-tools";
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ zlib openssl stdenv.cc.cc.lib ];
  version = "v1.7";
  installPhase = ''
    cp -r . $out
  '';
}
