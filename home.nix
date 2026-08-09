{config, pkgs, ... }: 

{
    home.username = "rsacramento";
    home.homeDirectory = "/home/rsacramento";
    home.stateVersion = "26.05";
    programs.git = {
        enable = true;
	settings = {
	    user = {
		name = "Ricardo Sacramento";
		email = "ricardo.sacramento@outlook.com";
	    };
	    init.defaultBranch = "master";
	};
    };
    programs.zsh = {
	enable = true;
	shellAliases = {
	    btw = "echo I use nixos, btw";
	};
    };
    home.packages = with pkgs; [
	ghostty
	neovim
	ripgrep
	nodejs
	discord
	steam
	pulseaudio
    ];
}
