# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# initiate zinit by either downloading or pointing towards where it's located
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
# zsh-fzf-history-search
#zinit ice lucid wait'0'
#zinit light joshskidmore/zsh-fzf-history-search
# Plugin history-search-multi-word loaded with investigating.
zinit load zdharma-continuum/history-search-multi-word
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

bindkey '\e[H'  beginning-of-line
bindkey '\e[F'  end-of-line
bindkey '\e[3~' delete-char
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

export PATH=$PATH:~/go/bin/
export FZF_BASE=/usr/bin
export MANPAGER='nvim +Man!'

export GOPRIVATE='github.com/Mattilsynet*'
export GOROOT='/usr/lib/go'
export GOPATH='/home/solve/go'
export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
export EDITOR='nvim'
export GONOPROXY='github.com/Mattilsynet*'
export GONOSUMDB='github.com/Mattilsynet*'
export PATH=$PATH:~/opt/nvim-linux64/bin
export PATH=$PATH:/opt/google-cloud-cli/bin
alias vim="nvim"
alias v="vim"
alias gal='gcloud auth login'
alias gaal='gcloud auth application-default login'
alias ls="ls --color"
alias l="ls -lha --color"
alias gmtv="go mod tidy && go mod vendor"
HISTFILE=~/.zhistory
HISTSIZE=5000
SAVEHIST=5000
HISTDUP=erase
setopt appendhistory # Immediately append history instead of overwriting
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':autocomplete:*' default-context history-incremental-search-backward
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
# Make thefuck command available
eval $(thefuck --alias)
eval "$(zoxide init --cmd cd zsh)"
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
