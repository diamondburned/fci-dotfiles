{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  importOrDefault = file: default: if builtins.pathExists file then import file else default;
in

{
  imports = [
    "${inputs.dotfiles}/Scripts/nix/cfg/gtk/home.nix"
    "${inputs.dotfiles}/Scripts/nix/cfg/git/home.nix"
    "${inputs.dotfiles}/Scripts/nix/cfg/foot/home.nix"
    "${inputs.dotfiles}/Scripts/nix/cfg/nvim/home.nix"
    "${inputs.dotfiles}/Scripts/nix/cfg/zellij/home.nix"
    ./secret-ssh.nix
  ];

  nixpkgs.overlays = [
    (import "${inputs.dotfiles}/Scripts/nix/overlays/overrides-all.nix")
    (inputs.nixgl.overlay)
  ];
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

  gtk.font.name = lib.mkForce "Lato";

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
		croc
    glab
		yq-go
    nodePackages.prettier

    inputs.nix-search.packages.${pkgs.system}.default

    go
    gopls
    gotools

    nixgl.nixGLIntel
    nixgl.nixVulkanIntel
  ];

  home.file = { };

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_QPA_PLATFORM = "wayland";
    RIPGREP_CONFIG_PATH = "${config.home.homeDirectory}/.config/ripgrep/ripgreprc";
    GOBIN = "${config.home.homeDirectory}/.go/bin";
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
    bashrcExtra =
      with lib;
      with builtins;
      concatStringsSep "\n" (flatten [
        (builtins.readFile ./bashrc)
        (map (f: builtins.readFile "${./bash-modules}/${f}") (
          mapAttrsToList (name: type: name) (
            filterAttrs (name: type: type == "regular") (builtins.readDir ./bash-modules)
          )
        ))
        ''
          export PATH="$PATH:${./bin}"
        ''
      ]);
    historyFileSize = 1000000;
    historySize = 100000;
    shellAliases = {
      "vfzf" = "vim $(fzf)";
      "ag" = "rg";
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
    repeat-interval = 25;
  };

  programs.ssh = {
    enable = true;
    compression = true;
    hashKnownHosts = true;
  };

  programs.fzf = {
    enable = true;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--glob=!vendor" # Ignore Go vendor directories always.
      "--glob=!.git"
      "--max-columns=150"
      "--max-columns-preview"
      "--smart-case"
    ];
  };
}
