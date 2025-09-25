alias nv=nvim
alias py=python

function ips {
    # ifconfig | awk '/inet /{ print $2 }'
    ip addr | grep -oP 'inet \K[\d.]+'
}
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
