{ config, lib, pkgs, zen-browser, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "zeus"; # Define your hostname.
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Lisbon";

  services.displayManager.ly.enable = true;
  services.displayManager.defaultSession = "mango";

  console.keyMap = "pt-latin1";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.openssh.enable = true;
  programs.ssh = {
    startAgent = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  users.users.rsacramento = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" "power" ]; 
    packages = with pkgs; [
      tree
    ];
  };

  programs.firefox.enable = true;
  programs.mango.enable = true;

  environment.systemPackages = with pkgs; [
    neovim 
    wget
    git
    ghostty
    zen-browser.packages.${pkgs.system}.default
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes"];
  system.stateVersion = "26.05";
}

