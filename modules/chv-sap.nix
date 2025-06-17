# Ensures libvirt and Cloud Hypervisor are set with the proper sources for SAP
# (for gardenlinux).

# Function returning a NixOS Module
{ self }:

# NixOS Module start
{ pkgs, ... }:
{
  virtualisation.libvirtd.package = pkgs.libvirt;
  nixpkgs.overlays = [
    (prev: final: {
      inherit (self.packages.${pkgs.system}) cloud-hypervisor;
    })
  ];
}
