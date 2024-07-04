{
  description = "A template that shows all standard flake outputs";

  # Inputs
  # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-inputs

  # The release branch of the NixOS/nixpkgs repository on GitHub.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  # region AgeNix
  inputs.agenix.url = "github:ryantm/agenix";
  # optional, not necessary for the module
  inputs.agenix.inputs.nixpkgs.follows = "nixpkgs";
  # optionally choose not to download darwin deps (saves some resources on Linux)
  inputs.agenix.inputs.darwin.follows = "";
  # endregion

  inputs.nixos-common.url = "github:allout58-infra/nixos-common";

  # It is also possible to "inherit" an input from another input. This is useful to minimize
  # flake dependencies. For example, the following sets the nixpkgs input of the top-level flake
  # to be equal to the nixpkgs input of the nixops input of the top-level flake:
  # inputs.nixpkgs.url = "nixpkgs";
  # inputs.nixpkgs.follows = "nixops/nixpkgs";

  # Work-in-progress: refer to parent/sibling flakes in the same repository
  # inputs.c-hello.url = "path:../c-hello";

  outputs = all @ {
    self,
    nixpkgs,
    agenix,
    nixos-common,
    ...
  }: let
    system = "x86_64-linux";
  in {
    # Used with `nixos-rebuild --flake .#<hostname>`
    # nixosConfigurations."<hostname>".config.system.build.toplevel must be a derivation
    nixosConfigurations.nix-media = nixpkgs.lib.nixosSystem {
      system = "${system}";
      modules = [
        ./configuration.nix
        ./media-mnt.nix
        ./jellyfin.nix
        # agenix.nixosModules.default
        # nixos-common.nixosModules.users
        # nixos-common.nixosModules.workloads.ssh
        # nixos-common.nixosModules.env.common
        # nixos-common.nixosModules.net.firewall
        # nixos-common.nixosModules.net.tailscale
      ];
    };

    # format the nix code in this flake
    # alejandra is a nix formatter with a beautiful output
    formatter."${system}" = nixpkgs.legacyPackages.${system}.alejandra;
  };
}
