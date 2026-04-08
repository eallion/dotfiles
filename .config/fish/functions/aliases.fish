# Abbreviations
abbr --add c clear
abbr --add d docker
abbr --add g git
abbr --add ga git add
abbr --add gaa git add --all
abbr --add gapa git add --patch
abbr --add gau git add --update
abbr --add gav git add --verbose
abbr --add gap git apply
abbr --add gb git branch
abbr --add gba git branch --all
abbr --add gbd git branch -d
abbr --add gbD git branch -D
abbr --add gbnm git branch --no-merged
abbr --add gbr git branch --remote
abbr --add gbs git bisect
abbr --add gbsb git bisect bad
abbr --add gbsg git bisect good
abbr --add gbsr git bisect reset
abbr --add gbss git bisect start
abbr --add gc git commit -v
abbr --add gca git commit -v -a
abbr --add gcans git commit -v -a --no-edit --amend
abbr --add gcam git commit -a -m
abbr --add gcamend git commit --amend
abbr --add gcan git commit -v --no-edit --amend
abbr --add gcb git checkout -b
abbr --add gcf git config --list
abbr --add gcl git clone --recurse-submodules
abbr --add gcm git commit -m
abbr --add gcms git commit -S -m
abbr --add gcmsg git commit -m
abbr --add gco git checkout
abbr --add gcp git cherry-pick
abbr --add gcpa git cherry-pick --abort
abbr --add gcpc git cherry-pick --continue
abbr --add gd git diff
abbr --add gdc git diff --cached
abbr --add gdca git diff --cached
abbr --add gds git diff --staged
abbr --add gdt git diff-tree --no-commit-id --name-only -r
abbr --add gignore git update-index --assume-unchanged
abbr --add gignored "git ls-files -v | grep '^[[:lower:]]'"
abbr --add gl git pull
abbr --add glg git log --stat
abbr --add glgp git log --stat -p
abbr --add glgga git log --graph --decorate --all
abbr --add glgm git log --graph --max-count=10
abbr --add glod git log --graph --decorate --oneline
abbr --add glol git log --graph --oneline --decorate
abbr --add glols git log --graph --oneline --decorate --stat
abbr --add glp git log --graph --decorate --pretty
abbr --add gm git merge
abbr --add gma git merge --abort
abbr --add gp git push
abbr --add gpd git push --dry-run
abbr --add gpf git push --force-with-lease
abbr --add gpu git push upstream
abbr --add gr git remote
abbr --add gra git remote add
abbr --add grb git rebase
abbr --add grba git rebase --abort
abbr --add grbc git rebase --continue
abbr --add grbi git rebase --interactive
abbr --add grbs git rebase --skip
abbr --add gres git reset
abbr --add grev git revert
abbr --add grh git reset HEAD
abbr --add grhh git reset HEAD --hard
abbr --add groh git reset origin/HEAD --hard
abbr --add grm git rm
abbr --add grmc git rm --cached
abbr --add grmv git remote rename
abbr --add grrm git remote remove
abbr --add grset git remote set-url
abbr --add grt "cd (git rev-parse --show-toplevel ^/dev/null; or echo .)"
abbr --add gru git reset --
abbr --add gs git status
abbr --add gsb git status --branch
abbr --add gsd git sync
abbr --add gsh git show
abbr --add gsi git submodule init
abbr --add gsps git show --pretty=short --show-signature
abbr --add gss git status --short
abbr --add gst git status
abbr --add gsta git stash push
abbr --add gstaa git stash apply
abbr --add gstc git stash clear
abbr --add gstd git stash drop
abbr --add gstl git stash list
abbr --add gsts git stash show --text
abbr --add gsu git submodule update
abbr --add gsw git switch
abbr --add gswc git switch --create
abbr --add gts git tag -s
abbr --add gtv git tag -v
abbr --add gv ghostty --version
abbr --add d docker
abbr --add dc docker compose
abbr --add dcu docker compose up -d
abbr --add dcd docker compose down
abbr --add dcp docker compose pull
abbr --add dclogs docker compose logs -f
abbr --add dcud docker compose up -d
abbr --add dcdown docker compose down
abbr --add dcudf docker compose up -d --force-recreate
abbr --add dcuf docker compose up -d --force-recreate
abbr --add dcup docker compose up -d
abbr --add dcupf docker compose up -d --force-recreate
abbr --add dps docker ps -a
abbr --add dpsa docker ps -a
abbr --add dim docker images
abbr --add dexec docker exec -it
abbr --add dstopall "docker stop (docker ps -q)"
abbr --add drmall "docker rm -f (docker ps -aq)"
abbr --add drmi docker image prune -a
abbr --add dnetrm docker network prune
abbr --add dclean docker system prune -a
abbr --add dbuild docker build --no-cache
abbr --add dcip docker inspect --format="{{.NetworkSettings.IPAddress}}"
abbr --add dlast "docker exec -it (docker ps -lq) bash"
abbr --add dlogs docker logs -f
abbr --add dlf docker logs -f
abbr --add 1 cd -1
abbr --add 2 cd -2
abbr --add 3 cd -3
abbr --add 4 cd -4
abbr --add 5 cd -5
abbr --add 6 cd -6
abbr --add 7 cd -7
abbr --add 8 cd -8
abbr --add 9 cd -9

if type -q rg
    abbr --add grep rg
end

if type -q nvim
    abbr --add vim nvim
end

abbr --add icat "kitten icat"
abbr --add kssh "kitten ssh"
abbr --add md mkdir -p
abbr --add python python3
abbr --add rd rmdir
abbr --add sqlite sqlite3
abbr --add ugz tar -xzvf

# Command wrappers
function mcd
    if test (count $argv) -lt 1
        echo "用法: mcd 目录名" >&2
        return 1
    end

    mkdir -p -- $argv[1]
    and cd -- $argv[1]
end

function gz
    if test (count $argv) -lt 1
        echo "用法: gz 文件或目录" >&2
        return 1
    end

    tar -czvf "$argv[1].tar.gz" "$argv[1]"
end

function warn_rm
    if type -q trash
        echo "🚨 警告：rm 功能已禁用！" >&2
        echo " " >&2
        echo "请使用安全的 'trash file' 命令将文件放入回收站。" >&2
        echo "用 '\\rm file' 可强制使用系统 rm 功能。" >&2
        return 1
    else
        echo "🚨 警告：rm 功能已禁用！" >&2
        echo " " >&2
        echo "请安装 'trash-cli' 以使用回收站代替 rm。" >&2
        echo " " >&2
        if type -q apt
            echo "• sudo apt install trash-cli" >&2
        else if type -q yum
            echo "• sudo yum install trash-cli" >&2
        else if type -q brew
            echo "• brew install trash-cli" >&2
        else if type -q pacman
            echo "• sudo pacman -S trash-cli" >&2
        else
            echo "请前往 https://github.com/andreafrancia/trash-cli 安装 'trash-cli' 。" >&2
        end
        echo " " >&2
        echo "用 '\\rm file' 可强制使用系统 rm 功能。" >&2
        return 1
    end
end

function l
    if type -q eza
        eza -lbF --git $argv
    else
        command ls -lbF $argv
    end
end

function lS
    if type -q eza
        eza -1 $argv
    else
        command ls -1 $argv
    end
end

function la
    if type -q eza
        eza -lbhHigUmuSa --time-style=long-iso --git --color-scale $argv
    else
        command ls -lAh $argv
    end
end

function ll
    if type -q eza
        eza -liangh --git $argv
    else
        command ls -laF $argv
    end
end

function ls
    if type -q eza
        eza $argv
    else
        command ls --color=auto $argv
    end
end

function lt
    if type -q eza
        eza --tree --level=2 $argv
    else
        command find . -maxdepth 2 -type d $argv
    end
end

function lx
    if type -q eza
        eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale $argv
    else
        command ls -lAh $argv
    end
end

function cat
    if type -q bat
        bat --paging=never -p $argv
    else
        command cat $argv
    end
end

function cp
    command cp -iv $argv
end

function mv
    command mv -iv $argv
end

function rd
    command rmdir $argv
end

function rm
    warn_rm
end

function sqlite
    command sqlite3 $argv
end

function ugz
    tar -xzvf $argv
end

function up
    sudo apt update; and sudo apt upgrade -y; and sudo apt autoremove; and sudo apt autoclean
    and type -q flatpak; and flatpak update -y
end

function multicd_cn
    cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end

abbr --add dotdot_cn --regex '^。{2,}$' --function multicd_cn

function git_log_pretty
    # 打印自适应宽度的横线 (使用 ─ 字符更美观)
    set_color grey
    string repeat -n $COLUMNS "─"
    set_color normal
    git log --graph --oneline --decorate \
        --format=format:'%C(bold green)%h%C(reset) - %C(bold blue)%ad%C(reset) %C(white)%s%C(reset)%C(bold yellow)%d%C(reset)' \
        --date=human \
        -10 $argv
end

abbr -a glog git_log_pretty

# docker stats --no-stream 的内存使用总和计算
abbr -a dsns "docker stats --no-stream --format \"table {{.ID}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}\" | awk -v host_total=(awk '/MemTotal/ {print \$2}' /proc/meminfo) \"NR==1 {print \\\$0; next} {print \\\$0; if (match(\\\$0, /[0-9.]+[KMG]?i?B[ ]+\\/[ ]+[0-9.]+[KMG]?i?B/)) {str = substr(\\\$0, RSTART, RLENGTH); split(str, parts, \\\"/\\\"); match(parts[1], /[0-9.]+/); u_val = substr(parts[1], RSTART, RLENGTH); u_unit = substr(parts[1], RSTART+RLENGTH); gsub(/[ ]/, \\\"\\\", u_unit); if (u_unit ~ /GiB/) u_val *= 1024; else if (u_unit ~ /KiB/) u_val /= 1024; else if (u_unit ~ /B\\\$/ && u_unit !~ /MiB/ && u_unit !~ /KiB/) u_val /= (1024*1024); u_sum += u_val;}} END {host_total_mib = host_total / 1024; if (host_total_mib > 0) printf \\\"\nTotal Memory Usage: %.2f MiB (%.2f%% of Host Total)\n\\\", u_sum, (u_sum / host_total_mib) * 100; else printf \\\"\nTotal Memory Usage: %.2f MiB\n\\\", u_sum;}\""
