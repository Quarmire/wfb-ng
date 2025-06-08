let
  pkgs = import (fetchTarball "channel:nixpkgs-unstable") {};
  stdenv = pkgs.stdenv;
  lib = pkgs.lib;
  fetchFromGitHub = pkgs.fetchFromGitHub;
  fetchpatch = pkgs.fetchpatch;
  replaceVars = pkgs.replaceVars;

  libpcap = pkgs.libpcap;
  libsodium = pkgs.libsodium;
  coreutils = pkgs.coreutils;
  iw = pkgs.iw;
  iproute2 = pkgs.iproute2;
  networkmanager = pkgs.networkmanager;
  bash = pkgs.bash;
  libevent = pkgs.libevent;
  pkg-config = pkgs.pkg-config;
  
  pythonEnv = pkgs.python313.withPackages (ps: with ps; [
    twisted
    pyroute2
    msgpack
  ]);
  python = pythonEnv;

  version = "25.01.1";

in stdenv.mkDerivation {
  pname = "wfb-ng";
  version = version;

  src = fetchFromGitHub {
    owner = "svpcom";
    repo = "wfb-ng";
    rev = "wfb-ng-${version}";
    hash = "sha256-0QeyBsj81s06WZT+3U/g1OAs/e6+vn5ScXSYJg3TfwA=";
  };

  patches = [
    (replaceVars ./patch_paths.patch { inherit networkmanager iw iproute2 bash; })
    (replaceVars ./patch_makefile.patch { inherit bash python pkg-config; })
    (replaceVars ./test_proxy_path_to_nix.patch { inherit coreutils; })
    (replaceVars ./service_paths_to_nix.patch { inherit coreutils; })
  ];

  nativeBuildInputs = [ pkg-config pythonEnv ];

  buildInputs = [ libpcap libsodium libevent pythonEnv ];

  # environmnent vars for make and setup.py
  VERSION=version;
  COMMIT="tag-wfb-ng-${version}";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/${pythonEnv.libPrefix}/site-packages/wfb_ng
    cp -r wfb_ng/*.py $out/lib/${pythonEnv.libPrefix}/site-packages/wfb_ng/
    mkdir -p $out/bin
    cp {wfb_tun,wfb_keygen,wfb_tx,wfb_rx,wfb_tx_cmd} $out/bin
    mkdir -p $out/scripts
    cp -r scripts/* $out/scripts

    runHook postInstall
  '';

}