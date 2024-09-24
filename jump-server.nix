{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    "${inputs.dotfiles}/Scripts/nix/cfg/nvim/home.nix"
    "${inputs.dotfiles}/Scripts/nix/cfg/zellij/home.nix"
  ];

  home = {
    stateVersion = "24.05";
    username = "root";
    homeDirectory = "/root";
  };

  nixpkgs = {
    overlays = [
      (import "${inputs.dotfiles}/Scripts/nix/overlays/overrides-all.nix")
      (inputs.nixgl.overlay)
    ];
    config.allowUnfree = true;
  };

  xdg.configFile."nvim/arts" = lib.mkForce {
    source = "${inputs.dotfiles}/Scripts/nix/static/arts";
    recursive = true;
  };

  programs.neovim = {
    withRuby = lib.mkForce false;
    withNodeJs = lib.mkForce false;
  };
}
