{
  lib,
  config,
  ...
}: let
  cfg = config.soppps;
in {
  options = {
    soppps = {
      files = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        description = ''
          List of files to be processed. can use unix globs.
        '';
      };
      package = lib.mkOption {
        description = "soppps package to use";
        type = lib.types.package;
      };
    };
  };
  config.systemd.services.soppps = {
    wantedBy = ["sysinit.target"];
    after = ["sops-install-secrets.service"];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ["${cfg.package}/bin/soppps"];
      RemainAfterExit = true;
    };
  };
}
