self: {
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.soppps;
in {
  options = {
    soppps = {
      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          List of files to be processed. can use unix globs.
        '';
      };
      configFile = lib.mkOption {
        description = ''
          Configuration file of soppps
        '';
      };
      package = lib.mkOption {
        description = "soppps package to use";
        default = self.packages.${pkgs.system}.default;
        type = lib.types.package;
      };
    };
  };
  config.soppps.configFile = builtins.toFile "config" (lib.concatStringsSep "\n" cfg.files);
  config.systemd.services.soppps = {
    wantedBy = ["sysinit.target"];
    after = ["sops-install-secrets.service"];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ["${cfg.package}/bin/soppps ${cfg.configFile}"];
      RemainAfterExit = true;
    };
  };
}
