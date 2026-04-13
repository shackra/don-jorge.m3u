{ lib, pkgs, config, ... }:
with lib;

let
  channelModule =
    { ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          description = "Name of the channel";
        };
        url = mkOption {
          type = types.str;
          description = "URL of the M3U playlist";
        };
        headers = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "HTTP headers to inject";
        };
        logo = mkOption {
          type = types.str;
          default = "";
          description = "URL to the channel logo";
        };
        group = mkOption {
          type = types.str;
          default = "";
          description = "Group title";
        };
      };
    };
in
{
  options.services.don-jorge = {
    enable = mkEnableOption "Don Jorge M3U playlist proxy service";
    package = mkOption {
      type = types.package;
      default = pkgs.don-jorge;
      description = "Don Jorge package";
    };
    address = mkOption {
      type = types.str;
      default = ":8080";
      description = "Listen address";
    };
    channels = mkOption {
      type = types.listOf (types.submodule channelModule);
      default = [ ];
      description = "List of TV channels";
    };
  };

  config =
    let
      cfg = config.services.don-jorge;
    in
    mkIf cfg.enable {
      systemd.services.don-jorge = {
        description = "Don Jorge M3U Playlist Proxy";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
          ExecStart =
            let
              cleanedChannels = map (
                ch:
                {
                  inherit (ch) name url;
                }
                // (optionalAttrs (ch.headers != { }) { inherit (ch) headers; })
                // (optionalAttrs (ch.logo != "") { inherit (ch) logo; })
                // (optionalAttrs (ch.group != "") { inherit (ch) group; })
              ) cfg.channels;

              channelsYaml = pkgs.writeText "channels.yaml" (
                generators.toYAML { } { channels = cleanedChannels; }
              );
            in
            "${cfg.package}/bin/don-jorge -channels ${channelsYaml} -addr ${cfg.address}";
        };
      };
    };
}
