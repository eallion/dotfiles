#!/bin/bash
# 显示远程会话信息
# 检查是否是通过 SSH 登录（通过判断 SSH_CLIENT 或 SSH_TTY 环境变量是否存在）
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    # SSH_CLIENT 格式通常为: <客户端IP> <本地端口> <远程端口>
    # 提取客户端 IP 地址
    CLIENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')
    
    # 尝试设置时区，如果系统不支持 Asia/Shanghai，则保持默认
    # 使用 TZ 变量临时设置
    
    echo "--- 远程会话信息 ---"
    echo "用户: $(whoami)"
    echo "主机: $(hostname)"
    echo "系统: $(uname -sro)"
    echo "客户端 IP: $CLIENT_IP"
    
    # 获取时间，尝试使用 TZ
    CURRENT_TIME=$(TZ='Asia/Shanghai' date +'%Y-%m-%d %H:%M:%S (UTC+8)' 2>/dev/null)
    if [ -z "$CURRENT_TIME" ]; then
        # 如果命令失败（可能是 date 不支持 TZ 或者是 busybox），回退到默认 date
         CURRENT_TIME=$(date)
    fi
     
    echo "登录时间 (北京时间): $CURRENT_TIME"
    echo "----------------------"
fi
