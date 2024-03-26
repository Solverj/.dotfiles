export PATH=$PATH:~/go/bin/
autoload -Uz compinit promptinit
compinit
promptinit
prompt clint
[[ -s /etc/profile.d/autojump.sh ]] && source /etc/profile.d/autojump.sh
export FZF_BASE=/usr/bin
bindkey '\e[H'  beginning-of-line
bindkey '\e[F'  end-of-line
bindkey '\e[3~' delete-char
plugins=(
    git
    colored-man-pages
    fzf 
    zsh-fzf-history-se
)
export EDITOR='nvim'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

alias vim="nvim"
alias gal='gcloud auth login'
alias gaal='gcloud auth application-default login'
alias l="ls -lha"
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
setopt appendhistory # Immediately append history instead of overwriting
setopt histignorealldups # If a new command is a duplicate, remove the older one
HISTFILE=~/.zhistory
HISTSIZE=1000
SAVEHIST=1000
