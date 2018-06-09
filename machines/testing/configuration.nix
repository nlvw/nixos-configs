{ config, pkgs, ... }: 

{
	# Import other configuration modules
	# (hardware-configuration.nix is autogenerated upon installation)
	# paths in nix expressions are always relative the file which defines them
	imports = [ 
		../../../hardware-configuration.nix
		../../private/hostname.nix
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

	# Host Name
	networking.hostName = "nixos-testing";

	# Networking
	networking.networkmanager.enable = true;
	
	# Packages
	environment.systemPackages = with pkgs; [
		git
		ranger
		tmux
		unzip
		vim
		wget
	];
	
	# Fonts
	fonts = {
		enableFontDir = true;
		fontconfig {
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
 
	# Additional Services/Daemons (also installs?)
	services.openssh.enable = true;

	# Firewall
	networking.firewall.enable = true;
	networking.firewall.allowedTCPPorts = [ 22 ];
	#networking.firewall.allowedUDPPorts = [ ...];
    
	# This value determines the NixOS release with which your system is to be
	# compatible, in order to avoid breaking some software such as database
	# servers. You should change this only after NixOs release notes say you
	# should.
	system.stateVersion = "18.03"; # Did you read the comment?
}
