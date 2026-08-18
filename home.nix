{
  config,
  pkgs,
  lib,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/personal/nixos/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    mango = "mango";
    nvim = "nvim";
    tmux = "tmux";
    ghostty = "ghostty";
    starship = "starship";
  };
in
{
  home.username = "rsacramento";
  home.homeDirectory = "/home/rsacramento";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    neovim
    less
    tmux
    ripgrep
    rust-analyzer
    rustfmt
    clippy
    lua-language-server
    gopls
    clang-tools
    nodejs
    rustc
    cargo
    discord
    fzf
    gcc
    gnumake
    gh
    wmenu
    nitch
    thunar
    unzip
    starship
    qmk
    google-chrome
    colloid-gtk-theme
    colloid-icon-theme
  ];

  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs;

  home.file.".local/bin".source = ./config/bin;

  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          name = "Ricardo Sacramento";
          email = "ricardo.sacramento@outlook.com";
        };
        init.defaultBranch = "master";
      };
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history.size = 10000;

      shellAliases = {
        btw = "echo I use nixos, btw";
        dot = "cd ~/.dotfiles";
        home = "cd ~";
        work = "cd ~/work";
        personal = "cd ~/personal";
        conf = "cd ~/.config";
        l = "ls -o -hX --group-directories-first --color=auto";
        la = "ls -o -AhX --group-directories-first --color=auto";
        v = "nvim";
        vim = "nvim";
        cat = "bat $1";
        diskspace = "ncdu";
        tmuxa = "tmux attach -t $1";
        sshhades = "ssh rsacramento@192.168.1.252 -p 1818 -i ~/.ssh/hades";
        lock = "betterlockscreen -l";
        sp = "systemctl suspend";
      };

      localVariables = {
        XDG_CURRENT_DESKTOP = "mango";
        EDITOR = "nvim";
        PAGER = "less";
      };

      initContent = ''
        eval "$(starship init zsh)"
        bindkey -s ^f "tmux-sessionizer\n"
        bindkey '^ ' autosuggest-accept
        bindkey '^r' history-incremental-search-backward
        nitch
      '';
    };
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.colloid-gtk-theme;
      name = "Colloid-Dark";
    };
    iconTheme = {
      package = pkgs.colloid-icon-theme;
      name = "Colloid-Dark";
    };
    cursorTheme = {
      package = pkgs.kdePackages.breeze;
      name = "breeze_cursors";
      size = 24;
    };
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.opencode/bin"
    "${config.home.homeDirectory}/.local/bin"
  ];

  home.activation.installTpm = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    TPM_DIR="$HOME/.tmux/plugins/tpm"

    if [ ! -d "$TPM_DIR/.git" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$TPM_DIR")"
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone \
        https://github.com/tmux-plugins/tpm.git \
        "$TPM_DIR"
    fi
  '';
}
