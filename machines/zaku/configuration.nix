{ config, pkgs, ... }: 

{
  # Import other configuration modules
  # (hardware-configuration.nix is autogenerated upon installation)
  # paths in nix expressions are always relative the file which defines them
  imports = [ 
    ../../../hardware-configuration.nix
    ../../private/users.nix
  ];

  # Boot Loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Localization
  time.timeZone = "US/Denver";
  i18n = {
    consoleFont = "roboto-mono";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  # Desktop (XServer + LightDM + i3-gaps)
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.libinput.enable = true; # touchpad support
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.windowManager = {
    i3 = { enable = true; package = pkgs.i3-gaps; };
    default = "i3";
  };

  # Nvidia and Graphics
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.driSupport32Bit = true;

  # Enable Sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;

  # Packages
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec {

      # Enable Unstable Channel
      unstable = import (fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz) {
        config = config.nixpkgs.config;
      };

      # Set Unstable Packages
      discord = unstable.discord;
      firefox = unstable.firefox;
      google-chrome = unstable.google-chrome;
      steam = unstable.steam;

      # Other Overrides
      polybar = pkgs.polybar.override { i3Support = true; }; 
    };
  };

  environment.systemPackages = with pkgs; [
    audacity
    clipit
    compton
    deluge
    discord
    feh
    firefox
    gimp
    git
    google-chrome
    imagemagick
    libreoffice
    lxappearance
    networkmanagerapplet
    obs-studio
    pango
    polybar
    psmisc
    qutebrowser
    ranger
    rofi
    scrot
    steam
    termite
    thunderbird
    tmux
    unzip
    vim
    vscode
    wget
  ];
	
  # Fonts
  fonts = {
    enableFontDir = true;
    fontconfig = {
      enable = true;
      defaultFonts.monospace = [ "roboto-mono" ];
      defaultFonts.sansSerif = [ "roboto" ];
      defaultFonts.serif = [ "roboto-slab" ];
    };
    fonts = with pkgs; [
      roboto
      roboto-mono
      roboto-slab
    ];
  };
						
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # OpenSSH Service
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    permitRootLogin = "no";
    passwordAuthentication = false;
    extraConfig = "
      # Allow Local Lan to login with password authentication
      Match address 192.168.8.0/24
        PasswordAuthentication yes
    ";
  };

  # Fail2ban Service
  services.fail2ban = {
    enable = true;
    jails.DEFAULT = ''
      ignoreip = 127.0.0.1/8,192.168.8.0/24
      bantime = 3600
      maxretry = 4
    '';
    jails.sshd = ''
      filter = sshd
      action = iptables[name=ssh, port=22, protocol=tcp]
      enabled = true
    '';
    jails.sshd-dos = ''
      filter = sshd-ddos
      action = iptables[name=ssh, port=22, protocol=tcp]
      bantime = 7200
      enabled = true
    '';
    jails.port-scan = ''
      filter = port-scan
      action = iptables-allports[name=port-scan]
      bantime = 7200
      enabled = true
    '';
  };

  environment.etc."fail2ban/filter.d/port-scan.conf".text = ''
    [Definition]
    failregex = rejected connection: .* SRC=<HOST>
  '';

  # CUPS Service (Printing)
  #services.printing.enable = true; # uses CUPS

  # Firewall / Networking
  networking.hostName = "zaku";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  #networking.firewall.allowedUDPPorts = [  ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOs release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}
