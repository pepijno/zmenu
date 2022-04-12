{
  description = "Implementation of dmenu in zig";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";

        buildInputs = with pkgs; [
          zig
          xorg.libX11
          xorg.libX11.dev
          xorg.libX11.out
          xorg.xorgproto
          xorg.libXinerama
          xorg.libXinerama.dev
          xorg.libXft
          xorg.libXft.dev
        ];
      in
      rec {
        # `nix build`
        packages = {
          zmenu = pkgs.stdenv.mkDerivation {
            inherit buildInputs;
            name = "zmenu";
            src = self;

            installPhase = ''
              zig build
            '';
          };
        };
        defaultPackage = packages.zmenu;

        # `zig run`
        apps.zmenu = utils.lib.mkApp {
          drv = packages.zmenu;
        };
        defaultApp = apps.zmenu;

        # `zig develop`
        devShell = pkgs.mkShell {
          inherit buildInputs;
        };
      });
}
