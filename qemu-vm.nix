{ config, modulesPath, ... }:

{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  virtualisation.forwardPorts = [
    { from = "host"; host.port = 8080; guest.port = 80; }
  ];

  networking.firewall.enable = false;

  users.users.root.initialPassword = "";
}
