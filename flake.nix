{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nspawn-nixos.url = "/home/tfc/src/nspawn-example";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" ];
    perSystem = { config, pkgs, system, ... }: {
      packages =
        let
          vmFromModules = modules: (inputs.nixpkgs.lib.nixosSystem {
            inherit modules system;
          }).config.system.build.vm;
        in {
        vm = vmFromModules [
          ./qemu-vm.nix
          ./nginx-php.nix
        ];
        vm-containered = vmFromModules [
          ./qemu-vm.nix
          ({ ... }: { # NixOS config of within the VM
            containers.webserver = {
              autoStart = true;
              privateNetwork = false;
              config = ./nginx-php.nix;
            };
          })
        ];
      };
      apps = {
        vm = {
          type = "app";
          program = "${config.packages.vm}/bin/run-nixos-vm";
        };
        vm-containered = {
          type = "app";
          program = "${config.packages.vm-containered}/bin/run-nixos-vm";
        };
      };
    };
  };
}
