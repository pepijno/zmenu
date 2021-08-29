{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    xorg.libX11
    xorg.libX11.dev
    xorg.libX11.out
    xorg.xorgproto
    xorg.libXinerama
    xorg.libXinerama.dev
    xorg.libXft
    xorg.libXft.dev
  ];

  shellHook = ''
      ${pkgs.fish}/bin/fish
  '';
}
