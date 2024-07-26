{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    "${inputs.dotfiles}/Scripts/nix/cfg/gtk/home.nix"
    "${inputs.dotfiles}/Scripts/nix/cfg/git/home.nix"
    "${inputs.dotfiles}/Scripts/nix/cfg/foot/home.nix"
    "${inputs.dotfiles}/Scripts/nix/cfg/nvim/home.nix"
    "${inputs.dotfiles}/Scripts/nix/cfg/zellij/home.nix"
  ];

  nixpkgs.overlays = [ (import "${inputs.dotfiles}/Scripts/nix/overlays/overrides-all.nix") ];
  nixpkgs.config.allowUnfree = true;

  # Retain Nix channels compatibility.
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  # Lock global Nixpkgs registry version.
  nix.registry = {
    nixpkgs.to = rec {
      type = "path";
      path = inputs.nixpkgs;
      narHash = builtins.readFile (
        pkgs.runCommandLocal "get-nixpkgs-hash" { }
          "${pkgs.nix}/bin/nix-hash --type sha256 --sri ${path} > $out"
      );
    };
  };

  gtk.font.name = lib.mkForce "Cantarell";

  xdg.configFile."nvim/arts" = lib.mkForce {
    source = "${inputs.dotfiles}/Scripts/nix/static/arts";
    recursive = true;
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "diamond";
  home.homeDirectory = "/home/diamond";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    nixfmt-rfc-style
    wl-clipboard
    glab
		yamlfmt

    inputs.nix-search.packages.${pkgs.system}.default
  ];

  home.file = { };

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_QPA_PLATFORM = "wayland";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bash = {
    enable = true;
    enableVteIntegration = true;
    bashrcExtra = builtins.readFile ./bashrc;
    historyFileSize = 1000000;
    historySize = 100000;
    shellAliases = {
      "ll" = "ls -la";
      "l" = "ls";
    };
  };

  programs.git.signing.signByDefault = lib.mkForce false;

  programs.go = {
    enable = true;
    goPath = ".go";
  };

  xdg.configFile."foot/foot.ini".source = lib.mkForce (
    pkgs.writeText "foot.ini" (
      builtins.replaceStrings
        [
          "font=monospace"
          ""
        ]
        [
          "font=Inconsolata"
          ""
        ]
        (builtins.readFile "${inputs.dotfiles}/Scripts/nix/cfg/foot/foot.ini")
    )
  );

  dconf.settings."org/gnome/desktop/peripherals/keyboard" = {
    delay = 200;
    repeat-interval = 20;
  };
}
