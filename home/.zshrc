bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char

HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Load shell configurations
[ -f ~/.shell_export ] && source ~/.shell_export
[ -f ~/.shell_alias ] && source ~/.shell_alias
[ -f ~/.shell_eval ] && source ~/.shell_eval

# Private shell configurations
[ -f ~/.shell_profile ] && source ~/.shell_profile
