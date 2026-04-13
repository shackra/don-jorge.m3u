{ lib }:

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
          description = "HTTP headers to inject when proxying";
        };
        logo = mkOption {
          type = types.str;
          default = "";
          description = "URL to the channel logo image";
        };
        group = mkOption {
          type = types.str;
          default = "";
          description = "Group title for the channel";
        };
      };
    };
in
{
  options.services.don-jorge = {
    enable = mkEnableOption "Don Jorge M3U playlist proxy service";

    package = mkOption {
      type = types.package;
      defaultText = "pkgs.don-jorge";
      description = "Don Jorge package to use";
    };

    address = mkOption {
      type = types.str;
      default = ":8080";
      description = "Address and port to listen on";
    };

    channels = mkOption {
      type = types.listOf (types.submodule channelModule);
      default = [ ];
      description = "List of TV channels to serve";
    };
  };

  config =
    { config, pkgs, ... }:
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
              makeChannel =
                ch:
                (removeAttrs ch [
                  "logo"
                  "group"
                ])
                // (optionalAttrs (ch.headers != { }) { headers = ch.headers; })
                // (optionalAttrs (ch.logo != "") { logo = ch.logo; })
                // (optionalAttrs (ch.group != "") { group = ch.group; });
              channelsYaml = pkgs.writeText "channels.yaml" (
                generators.toYAML { } {
                  channels = map makeChannel cfg.channels;
                }
              );
            in
            "${cfg.package}/bin/don-jorge -channels ${channelsYaml} -addr ${cfg.address}";
        };
      };
    };
}
