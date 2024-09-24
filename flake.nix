{
  description = "Home Manager configuration of diamond";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-search.url = "github:diamondburned/nix-search";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotfiles = {
      url = "gitlab:diamondburned/dotfiles/hackadoll3";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations = {
        "diamond" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            inherit inputs;
          };
        };
        "jump-server" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./jump-server.nix ];
          extraSpecialArgs = {
            inherit inputs;
          };
        };
      };

      packages.${system} = {
        update-jump-server =
          let
            dst = {
              packagesrc = "/root/diamond/.packagesrc";
              packagesrcRoot = "/root/diamond/.packagesrc.pkgs";
            };

            packages = pkgs.buildEnv {
              name = "jump-server-packages";
              paths = self.homeConfigurations.jump-server.config.home.packages;
            };

            packagesrc = pkgs.writeShellScript "jump-server-bootstrap" ''
              export PATH="$PATH:${pkgs.lib.makeBinPath [ packages ]}"
            '';

            applyRemote = pkgs.writeShellScript "apply-jump-server-remote" ''
              nix build -o ${dst.packagesrc} ${packagesrc}
              nix build -o ${dst.packagesrcRoot} ${packages}
            '';
          in
          pkgs.writeShellScriptBin "apply-jump-server" ''
            nix copy -s --to ssh://jump ${packages} ${packagesrc} ${applyRemote}
            ssh jump ${applyRemote}
          '';
      };
    };
}
