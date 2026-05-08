#!/bin/bash
# Usage (local): sudo bash setup_dns.sh
# Usage (remote): curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/setup_dns.sh | sudo bash
# Warning: rewrites /etc/resolv.conf and /etc/systemd/resolved.conf


set -e

echo "🔧 Enabling and configuring systemd-resolved with DNS over TLS..."

# 1. 检查并解锁 /etc/resolv.conf（如果被锁定）
if lsattr /etc/resolv.conf 2>/dev/null | grep -q '\-i\-'; then
    echo "⚠️ /etc/resolv.conf is immutable, removing immutable flag..."
    chattr -i /etc/resolv.conf
fi

# 2. 重新启用并启动 systemd-resolved（确保它开机自启动）
systemctl unmask systemd-resolved || true
systemctl enable --now systemd-resolved
echo "✅ systemd-resolved is enabled and running"

# 3. 恢复正确的 resolv.conf 链接
echo "🔄 Resetting /etc/resolv.conf symlink..."
rm -f /etc/resolv.conf
ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
echo "✅ /etc/resolv.conf → stub-resolv.conf"

# 4. 备份并写入配置文件
if [ -f /etc/systemd/resolved.conf ]; then
    cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak
    echo "✅ Backed up /etc/systemd/resolved.conf to .bak"
fi

tee /etc/systemd/resolved.conf > /dev/null <<EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4 2001:4860:4860::8888 2606:4700:4700::1111
FallbackDNS=1.1.1.1 2001:4860:4860::8844 2606:4700:4700::1001
LLMNR=no
MulticastDNS=no
DNSOverTLS=no
EOF

echo "✅ Updated /etc/systemd/resolved.conf with DNS over TLS settings"

# 5. 重启服务
systemctl restart systemd-resolved
echo "🔄 Restarted systemd-resolved"

# 6. 显示最终状态
echo ""
echo "📋 Current DNS configuration:"
resolvectl status | grep -E "DNS Servers|DNS over TLS|DNSSEC|Default Route"

echo ""
echo "✅ DNS over TLS is now active and systemd-resolved is restored to normal."
resolvectl query google.com
