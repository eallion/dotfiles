# My dotfiles

Windows public setting

# 备忘录

### 激活 Windows

> Key: https://learn.microsoft.com/zh-cn/windows-server/get-started/kms-client-activation-keys

```
slmgr /upk

slmgr /ipk NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J

slmgr /skms kms.eallion.com

slmgr /ato

slmgr /dlv
```

### 激活 Office

> Key: https://learn.microsoft.com/zh-cn/DeployOffice/vlactivation/gvlks?redirectedfrom=MSDN

```
cd "C:\Program Files\Microsoft Office\Office16"

cscript ospp.vbs /sethst:kms.eallion.com

cscript ospp.vbs /act
```

### 安装 Scoop

```bash
# PowerShell non-Admin
set-executionpolicy remotesigned -scope currentuser

$env:SCOOP='D:\Scoop'
[environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')
iwr -useb get.scoop.sh | iex

scoop bucket add main extras nerd-fonts versions
scoop bucket add dorado https://github.com/chawyehsu/dorado

scoop install aria2 clink curl git grep sudo tar vim vscode wget 

scoop update *
scoop cleanup *
scoop cache rm *

scoop list > apps_backup.txt
```

### Git 签名

```
gpg --full-gen-key

gpg --list-secret-keys --keyid-format LONG "eallions@gmail.com"

gpg --armor --export 4AEA00A342C24CA3

git config --global user.signingkey 4AEA00A342C24CA3

git config --global commit.gpgsign true
```