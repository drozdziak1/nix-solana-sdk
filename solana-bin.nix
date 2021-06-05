{ autoPatchelfHook
, cargo-build-bpf
, libudev
, linuxPackages
, makeWrapper
, ocl-icd
, openssl
, solana-bin-src
, solana-bpf-tools
, stdenv
, writeScriptBin
, zlib
, bpfToolsVersion
, bpfToolsCacheDirTarget ? ".cache/solana/${bpfToolsVersion}/bpf-tools"
}:
let
  # Eelco forgive me for I have sinned.
  fake-rustup = writeScriptBin "rustup" ''
    echo bpf something-something
    echo fake-rustup called >> /dev/stderr
  '';
in
stdenv.mkDerivation {
  name = "solana-bin";
  src = solana-bin-src;
  version = "1.7.1";
  autoPatchelfIgnoreMissingDeps = "1"; # lib_sgx_*.so libs seem non-essential
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    fake-rustup
    libudev
    makeWrapper
    ocl-icd
    openssl
    stdenv.cc.cc.lib
    zlib
  ];
  inherit bpfToolsCacheDirTarget;
  postBuild = ''
    set -x
    cp -r . $out
    cp ${cargo-build-bpf}/bin/cargo-build-bpf $out/bin
    solanaHome=$out/bpf-tools-home
    bpfToolsCacheSource=$out/bin/sdk/bpf/dependencies
    mkdir -p $solanaHome/$bpfToolsCacheDirTarget $bpfToolsCacheSource 

    cp -r ${solana-bpf-tools}/* $solanaHome/$bpfToolsCacheDirTarget

    pushd $bpfToolsCacheSource
    ln -sf $solanaHome/$bpfToolsCacheDirTarget $(pwd)
    readlink ./bpf-tools # confirm the link is correct
    popd

    wrapProgram $out/bin/cargo-build-bpf \
      --set HOME $solanaHome \
      --set CARGO $solanaHome/$bpfToolsCacheDirTarget/rust/bin/cargo \
      --set CARGO_HOME /tmp/nix-solana-sdk-home \
      --set RUSTC $solanaHome/$bpfToolsCacheDirTarget/rust/bin/rustc
    set +x
  '';
  installPhase = "true";
}
