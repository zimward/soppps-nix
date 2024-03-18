{
  description = "Secure Operations PostProceSsor";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystem = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    packages = forAllSystem (system: {
      default = nixpkgs.legacyPackages.${system}.callPackage ./soppps.nix {};
    });
    nixosModules = {
      soppps = import ./soppps-service.nix {
        lib = nixpkgs.lib;
        config.soppps.package = self.packages.x86_64-linux.default;
      };
      default = self.nixosModules.soppps;
    };
  };
}
