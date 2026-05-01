{ lib, ... }:
{
  programs.zsh.initContent = lib.mkAfter ''
    # Key bindings
    bindkey "^[[H" beginning-of-line
    bindkey "^[[F" end-of-line
    bindkey "^[[3~" delete-char
    bindkey "^[[1;3C" forward-word
    bindkey "^[[1;3D" backward-word

    # Functions
    function git_smart_rebase() {
        GIT_STASH_MESSAGE="git_smart_rebase: $RANDOM"
        git stash push -m "$GIT_STASH_MESSAGE"
        git fetch && git rebase
        git stash list | (grep "''${GIT_STASH_MESSAGE}" && git stash pop) || true
    }

    function mkt() {
      mkdir {nmap,content,exploits,scripts}
    }

    function extractPorts() {
      ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
      ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"
      echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
      echo -e "\t[*] IP Address: $ip_address"  >> extractPorts.tmp
      echo -e "\t[*] Open ports: $ports\n"  >> extractPorts.tmp
      if command -v wl-copy &> /dev/null; then
        echo $ports | tr -d '\n' | wl-copy
      elif command -v xclip &> /dev/null; then
        echo $ports | tr -d '\n' | xclip -sel clip
      fi
      echo -e "[*] Ports copied to clipboard\n"  >> extractPorts.tmp
      cat extractPorts.tmp; rm extractPorts.tmp
    }

    function cman() {
      env \
      LESS_TERMCAP_mb=$'\e[01;31m' \
      LESS_TERMCAP_md=$'\e[01;31m' \
      LESS_TERMCAP_me=$'\e[0m' \
      LESS_TERMCAP_se=$'\e[0m' \
      LESS_TERMCAP_so=$'\e[01;44;33m' \
      LESS_TERMCAP_ue=$'\e[0m' \
      LESS_TERMCAP_us=$'\e[01;32m' \
      man "$@"
    }

    function fzf-lovely() {
      if [ "$1" = "h" ]; then
        fzf -m --reverse --preview-window down:20 --preview '[[ $(file --mime {}) =~ binary ]] &&
          echo {} is a binary file ||
          (bat --style=numbers --color=always {} ||
           highlight -O ansi -l {} ||
           coderay {} ||
           rougify {} ||
           cat {}) 2> /dev/null | head -500'
      else
        fzf -m --preview '[[ $(file --mime {}) =~ binary ]] &&
          echo {} is a binary file ||
          (bat --style=numbers --color=always {} ||
           highlight -O ansi -l {} ||
           coderay {} ||
           rougify {} ||
           cat {}) 2> /dev/null | head -500'
      fi
    }

    function rmk() {
      scrub -p dod $1
      shred -zun 10 -v $1
    }
  '';
}
