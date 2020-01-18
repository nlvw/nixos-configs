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
  time.timeZone = "America/Denver";
  i18n = {
    consoleFont = "roboto-mono";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  # Desktop (XServer + LightDM + i3-gaps)
  services.xserver = {
    enable = true;
    layout = "us";
    libinput.enable = true; # touchpad support

    desktopManager = {
      xterm.enable = false;
      default = "none";
      lightdm = {
        enable = true;
        background = "/etc/nixos/nixos-configs/resources/images/wall2.jpg";
        greeters.gtk = {
          enable = true;
          clock-format = "%a, %d %b %y, %I:%M %p";
          indicators = [ "~host" "~spacer" "~clock" "~spacer" "~session" "~a11y" "~power" ];
          extraConfig = "
            default-user-image = /etc/nixos/nixos-configs/resources/images/nixos-logo-only-hires.png
            font-name = Roboto Mono 16
            a11y-states=+font
          ";
        };
      };
    }; # end desktopManager

    windowManager = {
      i3 = {
        enable = true;
        package = pkgs.i3-gaps;
      };
      default = "i3";
    };
  }; # end services.xserver

  # Graphics
  hardware.opengl.enable = true;
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
      #unstable = import (fetchTarball channel:nixos-unstable) {
      #  config = config.nixpkgs.config;
      #};

      # Set Unstable Packages
      #discord = unstable.discord;
      #firefox = unstable.firefox;
      #google-chrome = unstable.google-chrome;
      #steam = unstable.steam;

      # Other Overrides
      polybar = pkgs.polybar.override { i3Support = true; };
    };
  };

  environment.systemPackages = with pkgs; [
    breeze-gtk			# Theme
    breeze-qt5			# Theme
    breeze-icons		# Theme
    #clipit			# Clipboard Manager
    compton			# Tranparency for I3
    copyq			# Clipboard Manager
    deluge			# Torrent Client/Daemon
    discord			# Chat/Voip
    dunst			# Notification Daemon
    feh				# Image Viewer (i3 background)
    firefox			# Browser (Secondary)
    fzf				# Fuzzy File Finder (Vim/Ranger)
    gimp			# Image Editor
    git				# Version Control CLI
    gnupg			# Encryption Software
    #google-chrome		# Browser (Primary)
    htop			# CLI Tool (Processes)
    iotop			# CLI Tool (Processes)
    imagemagick			# CLI Image Processor (used with lockscreen)
    libnotify			# Notification Library (Dunst Dependancy)
    libreoffice			# Office Document Suite
    neovim			# Vim alternative/rewrite
    networkmanagerapplet	# Systray Applet for Network Manager
    pango			# Text Layout Engine Library...
    pandoc			# Document Conversion
    pamixer			# Pulse Audio Tool
    pasystray			# Pusle Audio System Tray App
    pavucontrol			# Pulse AUdio Tool
    polybar			# Status Bar (i3)
    psmisc			# Multi Tool Package Concerning Proc (fuser, kallall,pstree, prtstat)
    qt5ct			# QT Themeing Daemon (Because QT doesn't have a file config for themes...)
    #qutebrowser			# Browser (Keyboard Focused / Lightweight)
    ranger			# CLI File Broweser
    rofi			# Menu App (Windows Switcher, App Launcher, and demenu replacement)
    scrot			# Screenshot Capture Utility
    shellcheck			# Bash/SH Linting (Vim/Neovim Plugin Depend)
    steam			# Games!
    termite			# Terminal Emulator
    tmux			# Screen Multiplexer
    unclutter			# Hide Mouse When Idle Daemon
    unzip			# Zip Archive Handler
    vim				# CLI Text Editor / IDE
    vscode			# GUI Text Editor / IDE
    wget			# Easy Curl Alternative
    zathura			# PDF Viewer
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
      corefonts
      nerdfonts
      powerline-fonts
      source-code-pro
      roboto
      roboto-mono
      roboto-slab
      ubuntu_font_family
    ];
  };

  # started in user sessions (login config).
  programs.bash.enableCompletion = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.ssh.startAgent = true;

  # OpenSSH Service
  services.openssh = { enable = false; };

  # Virtualization and Containerization
  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = false;
    };

    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    lxd.enable = true;
  };

  # CUPS Service (Printing)
  #services.printing.enable = true; # uses CUPS

  # Firewall / Networking
  networking = {
    hostName = "hizack";
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowPing = false;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOs release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?
}
