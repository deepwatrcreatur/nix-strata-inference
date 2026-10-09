{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.services.strata-inference;
in
{
  options.services.strata-inference = {
    enable = lib.mkEnableOption "Strata Qwen3.8-Flash-Next 125B inference service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.strata-inference or (pkgs.callPackage ../package.nix { });
      description = "The Strata inference package to use.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host address to bind the API server.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on for the OpenAI/Anthropic API.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/strata";
      description = "Directory for Strata cache, state, and runtime data.";
    };

    modelsDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/strata/models";
      description = "Directory where GGUF model files and MTP weights reside.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional custom configuration JSON file path.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to open the API port in the firewall.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "strata";
      description = "User account under which Strata runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "strata";
      description = "Group account under which Strata runs.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        CUDA_VISIBLE_DEVICES = "0";
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      };
      description = "Environment variables passed to the Strata service.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional command-line arguments passed to strata-inference.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = lib.mkIf (cfg.user == "strata") {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = false;
      extraGroups = [ "video" "render" ];
    };

    users.groups.${cfg.group} = lib.mkIf (cfg.group == "strata") { };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.modelsDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.strata-inference = {
      description = "Strata Local MoE Inference Engine";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = cfg.environment;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart =
          let
            configArg = lib.optionalString (cfg.configFile != null) "--config ${cfg.configFile}";
          in
          "${cfg.package}/bin/strata-inference --host ${cfg.host} --port ${toString cfg.port} --models-dir ${cfg.modelsDir} ${configArg} ${lib.escapeShellArgs cfg.extraArgs}";
        Restart = "on-failure";
        RestartSec = "5s";
        LimitMEMLOCK = "infinity";
        LimitNOFILE = 1048576;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
