{
  pkgs ? (
    let
      inherit (builtins) fetchTree fromJSON readFile;
      inherit ((fromJSON (readFile ./flake.lock)).nodes) nixpkgs gomod2nix;
    in
    import (fetchTree nixpkgs.locked) {
      overlays = [
        (import "${fetchTree gomod2nix.locked}/overlay.nix")
      ];
    }
  ),
  buildGoApplication ? pkgs.buildGoApplication,
}:

buildGoApplication {
  pname = "don-jorge";
  version = "0.1.0";

  src = ./.;
  modules = ./gomod2nix.toml;

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "M3U playlist proxy service with header injection";
    license = "MIT";
    mainProgram = "don-jorge";
  };
}
