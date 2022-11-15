source ~/.bashrc
source ~/.profile
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fpath=(~/.zsh/zsh-completions/src $fpath)
autoload -Uz compinit && compinit
eval "$(starship init zsh)"
plugins=( git extract fasd zsh-autosuggestions zsh-syntax-highlighting docker docker-compose)