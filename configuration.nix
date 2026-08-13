{
  config,
  lib,
  pkgs,
  zen-browser,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfree = true;

  fileSystems."/home/rsacramento/Vader" = {
    device = "/dev/disk/by-uuid/60a4b844-fa4c-4e08-a865-2aef749ef586";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  systemd.tmpfiles.rules = [
    "Z /home/rsacramento/Vader 0755 rsacramento users -"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-generations 5";
  };

  networking.hostName = "zeus"; # Define your hostname.
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Lisbon";

  services.displayManager.ly.enable = true;
  services.displayManager.defaultSession = "mango";
  services.xserver.videoDrivers = [ "amdgpu" ];

  console.keyMap = "pt-latin1";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.udisks2.enable = true;
  services.devmon.enable = true;

  services.openssh.enable = true;
  programs.ssh = {
    startAgent = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  users.users.rsacramento = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "power"
    ];
    packages = with pkgs; [
      tree
    ];
  };

  environment.systemPackages = with pkgs; [
    neovim
    zsh
    bat
    wget
    git
    foot
    feh
    yazi
    pavucontrol
    steam
    mangohud
    protonplus
    wl-clipboard
    swaybg
    unstable.ghostty
    unstable.opencode
    kdePackages.breeze
    zen-browser.packages.${pkgs.system}.default
  ];

  programs.firefox.enable = true;
  programs.mango.enable = true;
  programs.zsh.enable = true;
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  programs.dconf.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = "26.05";
}
