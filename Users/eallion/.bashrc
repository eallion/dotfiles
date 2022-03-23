alias c=clear
alias g=git
alias ga="git add"
alias gaa="git add --all"
alias gam="git am"
alias gama="git am --abort"
alias gamc="git am --continue"
alias gams="git am --skip"
alias gamscp="git am --show-current-patch"
alias gap="git apply"
alias gapa="git add --patch"
alias gapt="git apply --3way"
alias gau="git add --update"
alias gav="git add --verbose"
alias gb="git branch"
alias gbD="git branch -D"
alias gba="git branch -a"
alias gbd="git branch -d"
alias gbl="git blame -b -w"
alias gbnm="git branch --no-merged"
alias gbr="git branch --remote"
alias gbs="git bisect"
alias gbsb="git bisect bad"
alias gbsg="git bisect good"
alias gbsr="git bisect reset"
alias gbss="git bisect start"
alias gc="git commit -v"
alias "gc!"="git commit -v --amend"
alias gca="git commit -v -a"
alias "gca!"="git commit -v -a --amend"
alias gcam="git commit -a -m"
alias "gcan!"="git commit -v -a --no-edit --amend"
alias "gcans!"="git commit -v -a -s --no-edit --amend"
alias gcb="git checkout -b"
alias gcd="git checkout develop"
alias gcf="git config --list"
alias gcl="git clone --recurse-submodules"
alias gclean="git clean -id"
alias gcm="git commit -a -m"
alias gcmsg="git commit -m"
alias "gcn!"="git commit -v --no-edit --amend"
alias gco="git checkout"
alias gcount="git shortlog -sn"
alias gcp="git cherry-pick"
alias gcpa="git cherry-pick --abort"
alias gcpc="git cherry-pick --continue"
alias gcs="git commit -S"
alias gcsm="git commit -s -m"
alias gd="git diff"
alias gdca="git diff --cached"
alias gdcw="git diff --cached --word-diff"
alias gds="git diff --staged"
alias gdt="git diff-tree --no-commit-id --name-only -r"
alias gdw="git diff --word-diff"
alias gf="git fetch"
alias gfa="git fetch --all --prune"
alias gfg="git ls-files | grep"
alias gfo="git fetch origin"
alias gg="git gui citool"
alias gga="git gui citool --amend"
alias ggpur=ggu
alias ghh="git help"
alias gignore="git update-index --assume-unchanged"
alias gignored="git ls-files -v | grep "^[[:lower:]]""
alias gist="nocorrect gist"
alias github="web_search github"
alias givero="web_search givero"
alias gk="\gitk --all --branches"
alias gl="git log --graph --pretty="\""%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"\"
alias glg="git log --stat"
alias glgg="git log --graph"
alias glgga="git log --graph --decorate --all"
alias glgm="git log --graph --max-count=10"
alias glgp="git log --stat -p"
alias glo="git log --oneline --decorate"
alias globurl="noglob urlglobber "
alias glod="git log --graph --pretty="\""%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"\"
alias glods="git log --graph --pretty="\""%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"\"" --date=short"
alias glog="git log --oneline --decorate --graph"
alias gloga="git log --oneline --decorate --graph --all"
alias glol="git log --graph --pretty="\""%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"\"
alias glola="git log --graph --pretty="\""%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"\"" --all"
alias glols="git log --graph --pretty="\""%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"\"" --stat"
alias glp=_git_log_prettily
alias gm="git merge"
alias gma="git merge --abort"
alias gmt="git mergetool --no-prompt"
alias gmtvim="git mergetool --no-prompt --tool=vimdiff"
alias goodreads="web_search goodreads"
alias google="web_search google"
alias gp="git push"
alias gpd="git push --dry-run"
alias gpf="git push --force-with-lease"
alias "gpf!"="git push --force"
alias gpoat="git push origin --all && git push origin --tags"
alias gpristine="git reset --hard && git clean -dffx"
alias gpu="git push upstream"
alias gpv="git push -v"
alias gr="git remote"
alias gra="git remote add"
alias grb="git rebase"
alias grba="git rebase --abort"
alias grbc="git rebase --continue"
alias grbd="git rebase develop"
alias grbi="git rebase -i"
alias grbs="git rebase --skip"
alias grep="grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}"
alias grev="git revert"
alias grh="git reset"
alias grhh="git reset --hard"
alias grm="git rm"
alias grmc="git rm --cached"
alias grmv="git remote rename"
alias grrm="git remote remove"
alias grs="git restore"
alias grset="git remote set-url"
alias grss="git restore --source"
alias gru="git reset --"
alias grup="git remote update"
alias grv="git remote -v"
alias gsb="git status -sb"
alias gsd="git svn dcommit"
alias gsh="git show"
alias gsi="git submodule init"
alias gsps="git show --pretty=short --show-signature"
alias gsr="git svn rebase"
alias gss="git status -s"
alias gst="git status"
alias gsta="git stash push"
alias gstaa="git stash apply"
alias gstall="git stash --all"
alias gstc="git stash clear"
alias gstd="git stash drop"
alias gstl="git stash list"
alias gstp="git stash pop"
alias gsts="git stash show --text"
alias gstu="git stash --include-untracked"
alias gsu="git submodule update"
alias gsw="git switch"
alias gswc="git switch -c"
alias gtl="gtl(){ git tag --sort=-v:refname -n -l "${1}*" }; noglob gtl"
alias gts="git tag -s"
alias gtv="git tag | sort -V"
alias gunignore="git update-index --no-assume-unchanged"
alias gunwip="git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1"
alias gup="git pull --rebase"
alias gupa="git pull --rebase --autostash"
alias gupav="git pull --rebase --autostash -v"
alias gupv="git pull --rebase -v"
alias gwch="git whatchanged -p --abbrev-commit --pretty=medium"
alias la="ls -lAh"
alias ll="ls -lh"
alias ls="ls --color=tty"
alias lsa="ls -lah"
alias edit="'C:/Program Files (x86)/Notepad++/notepad++.exe' -nosession -noPlugin"
eval "$(starship init bash)"