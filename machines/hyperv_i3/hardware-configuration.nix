{ config, lib, pkgs, ...}:

{
    imports = [ ];

    boot.initrd.availableKernelModules = [ "sd_mod" "sr_mod" "hv_storvsc" ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
    };

    fileSystems."/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
    };

    swapDevices = [ {
        device = "/dev/disk/by-label/swap";
    } ];

    nix.maxJobs = lib.mkDefault 4;
    services.xserver.videoDrivers = [ "fbdev" ];
}