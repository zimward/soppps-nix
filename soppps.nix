{ pkgs ? import <nixpkgs> { } }:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "soppps";
  version = "0.1.0";
  src = ./soppps;
  cargoLock.lockFile = ./soppps/Cargo.lock;
}
