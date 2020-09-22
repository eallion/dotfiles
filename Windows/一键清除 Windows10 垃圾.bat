@echo off
color 0a
TITLE ：Win10系统垃圾清除大师 by 云爸

echo 正在为您清理系统垃圾档桉，请稍等...... 

echo 清理垃圾档桉，速度由档桉大小决定。没到最后请不要自行关闭视窗

echo 请勿自行关闭视窗。

echo 正在清除系统垃圾，请稍等......

echo 删除补丁备份目录

RD %windir%\$hf_mig$ /Q /S

echo 把更新解压缩档桉的名称改为2950800.txt

dir %windir%\$NtUninstall* /a:d /b >%windir%\2950800.txt

echo 从2950800.txt中读取资料夹列表并且删除资料夹

for /f %%i in (%windir%\2950800.txt) do rd %windir%\%%i /s /q

echo 删除2950800.txt

del %windir%\2950800.txt /f /q

echo 删除更新安装记录内容（下面的del /f /s /q %systemdrive%\*.log已经包含删除此类档桉）

del %windir%\KB*.log /f /q

echo 删除系统碟目录下暂存档

del /f /s /q %systemdrive%\*.tmp

echo 删除系统碟目录下暂存档

del /f /s /q %systemdrive%\*._mp

echo 删除系统碟目录下日志档桉

del /f /s /q %systemdrive%\*.log

echo 删除系统碟目录下GID档桉(属于暂存档，具体作用不详)

del /f /s /q %systemdrive%\*.gid

echo 删除系统碟下scandisk（磁碟扫描）留下的无用档桉

del /f /s /q %systemdrive%\*.chk

echo 删除系统碟下old档桉

del /f /s /q %systemdrive%\*.old

echo 删除回收站的无用档桉

del /f /s /q %systemdrive%\recycled\*.*

echo 删除系统碟下备份档桉

del /f /s /q %windir%\*.bak

echo 删除应用程式暂存档

del /f /s /q %windir%\prefetch\*.*

echo 删除系统维护等操作产生的暂存档

rd /s /q %windir%\temp & md %windir%\temp

echo 删除当前用户的COOKIE（IE）

del /f /q %userprofile%\cookies\*.*

echo 删除internet暂存档

del /f /s /q "%userprofile%\local settings\temporary internet files\*.*"

echo 删除当前用户日常操作临时档桉

del /f /s /q "%userprofile%\local settings\temp\*.*"

echo 删除访问记录（开始选单中的裡面的东西）

del /f /s /q "%userprofile%\recent\*.*"

echo

echo ★☆ 恭喜您！清理全部完成！☆★

echo.