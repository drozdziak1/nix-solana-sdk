{ autoPatchelfHook
, libudev
, linuxPackages
, ocl-icd
, openssl
, solana-bin-src
, stdenv
, zlib
}:
stdenv.mkDerivation {
  name = "solana-bin";
  src = solana-bin-src;
  nativeBuildInputs = [ autoPatchelfHook ];
  autoPatchelfIgnoreMissingDeps = "1"; # lib_sgx_*.so libs seem non-essential
  buildInputs = [
    libudev
    ocl-icd
    openssl
    stdenv.cc.cc.lib
    zlib
  ];
  version = "1.6.7";
  installPhase = ''cp -r . $out'';
}
