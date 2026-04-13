{ lib }:

with lib;

let
  channelSubmodule =
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
          description = "HTTP headers to inject when proxying (e.g., Origin, Referer)";
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

  mkServiceModule =
    { packages }:
    { config, ... }:

    let
      cfg = config.services.don-jorge;
    in
    {
      config = mkIf cfg.enable {
        systemd.services.don-jorge = {
          description = "Don Jorge M3U Playlist Proxy";
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = "5s";

            ExecStart =
              let
                channelToYAML =
                  ch:
                  let
                    base = {
                      name = ch.name;
                      url = ch.url;
                    };
                    withHeaders = if ch.headers == { } then base else base // { headers = ch.headers; };
                    withLogo = if ch.logo == "" then withHeaders else withHeaders // { logo = ch.logo; };
                    withGroup = if ch.group == "" then withLogo else withLogo // { group = ch.group; };
                  in
                  withGroup;
                channelsYaml = packages.writeText "channels.yaml" (
                  generators.toYAML { } {
                    channels = map channelToYAML cfg.channels;
                  }
                );
              in
              "${cfg.package}/bin/don-jorge -channels ${channelsYaml} -addr ${cfg.address}";
          };
        };
      };
    };
in

{
  options = {
    services.don-jorge = {
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
        type = types.listOf (types.submodule channelSubmodule);
        default = [ ];
        description = "List of TV channels to serve";
        example = literalExpression ''
          [
            {
              name = "Teletica";
              url = "https://cdn01.teletica.com/stream/playlist.m3u8";
              headers = {
                Origin = "https://bradmax.com";
                Referer = "https://bradmax.com";
              };
              logo = "https://example.com/teletica.png";
              group = "Costa Rica";
            }
            {
              name = "Opa TV";
              url = "https://example.com/stream/playlist.m3u8";
            }
          ]
        '';
      };
    };
  };

  config = { config, pkgs, ... }: mkServiceModule { inherit pkgs; } { inherit config; };
}
