#!/bin/bash
# Описание: Запуск приложений через WireGuard в отдельном сетевом namespace (изолирует VPN-трафик от остальной системы)
# Использование: vpnns <команда> [аргументы]
# Примеры:
#   vpnns up <config.conf>     # создать VPN namespace
#   vpnns run firefox          # запустить приложение через VPN
#   vpnns status               # проверить активен ли namespace
#   vpnns down                 # снести VPN namespace
# Зависимости: wireguard-tools, iproute2, sudo
# Категория: network

NS="vpn"
WG_IFACE="wg-vpn"
STATE_DIR="/tmp/vpnns"
CONF_DIR="${VPNNS_CONF_DIR:-$HOME/Templates/vpn}"

# Optional override: vpnns -c <dir> <subcommand> ...
if [[ "${1:-}" == "-c" || "${1:-}" == "--conf-dir" ]]; then
    CONF_DIR="$2"
    shift 2
fi

# Find config with lowest ping (parallel)
find_best() {
    local best_avg=99999 best_conf=""
    local tmp_dir
    tmp_dir=$(mktemp -d /tmp/vpnns-ping-XXXX)

    for conf in "$CONF_DIR"/*.conf; do
        [[ -f "$conf" ]] || continue
        local name
        name=$(basename "$conf" .conf)
        (
            host=$(grep -oP 'Endpoint\s*=\s*\K[^:]+' "$conf")
            result=$(ping -c 3 -W 1 -i 0.2 "$host" 2>/dev/null | tail -1)
            if [[ "$result" == *"min/avg/max"* ]]; then
                avg=$(echo "$result" | grep -oP '[\d.]+/[\d.]+/[\d.]+' | cut -d/ -f2)
                echo "$avg $conf" > "$tmp_dir/$name"
            fi
        ) &
    done
    wait

    for f in "$tmp_dir"/*; do
        [[ -f "$f" ]] || continue
        read -r avg conf < "$f"
        if awk "BEGIN{exit !($avg < $best_avg)}"; then
            best_avg="$avg"
            best_conf="$conf"
        fi
    done
    rm -rf "$tmp_dir"

    if [[ -z "$best_conf" ]]; then
        echo "No reachable servers found" >&2
        exit 1
    fi
    echo "Best server: $(basename "$best_conf" .conf) (${best_avg} ms)" >&2
    echo "$best_conf"
}

up() {
    local conf="$1"
    if [[ -z "$conf" ]]; then
        conf=$(find_best)
    elif [[ ! -f "$conf" ]]; then
        echo "File not found: $conf"
        exit 1
    fi
    conf="$(realpath "$conf")"

    # Check if already up
    if ip netns list 2>/dev/null | grep -q "^$NS "; then
        echo "Namespace '$NS' already exists. Run 'vpnns down' first."
        exit 1
    fi

    local addr dns endpoint_host endpoint_port
    addr=$(grep -oP 'Address\s*=\s*\K\S+' "$conf")
    dns=$(grep -oP 'DNS\s*=\s*\K.*' "$conf")

    # Extract endpoint host for routing
    endpoint_host=$(grep -oP 'Endpoint\s*=\s*\K[^:]+' "$conf")
    endpoint_port=$(grep -oP 'Endpoint\s*=\s*\K\S+' "$conf" | grep -oP ':\K\d+')

    # Resolve endpoint if it's a hostname
    local endpoint_ip
    endpoint_ip=$(getent ahostsv4 "$endpoint_host" 2>/dev/null | head -1 | awk '{print $1}')
    if [[ -z "$endpoint_ip" ]]; then
        echo "Failed to resolve endpoint: $endpoint_host"
        exit 1
    fi

    echo "Setting up VPN namespace..."

    # Create namespace
    sudo ip netns add "$NS"
    sudo ip netns exec "$NS" ip link set lo up

    # Create WireGuard interface
    sudo ip link add "$WG_IFACE" type wireguard

    # Build wg-compatible config (strip wg-quick specific options)
    local wg_conf
    wg_conf=$(mktemp /tmp/wg-strip-XXXX.conf)
    awk '
        /^\[Interface\]/ { section="interface"; print; next }
        /^\[Peer\]/ { section="peer"; print; next }
        section=="interface" && /^(PrivateKey|ListenPort|FwMark)\s*=/ { print; next }
        section=="peer" { print; next }
    ' "$conf" > "$wg_conf"

    sudo wg setconf "$WG_IFACE" "$wg_conf"
    rm -f "$wg_conf"

    # Move interface to namespace
    sudo ip link set "$WG_IFACE" netns "$NS"

    # Configure interface inside namespace
    sudo ip netns exec "$NS" ip addr add "$addr" dev "$WG_IFACE"
    sudo ip netns exec "$NS" ip link set "$WG_IFACE" up
    sudo ip netns exec "$NS" ip route add default dev "$WG_IFACE"

    # Set up DNS inside namespace
    sudo mkdir -p "/etc/netns/$NS"
    : > /tmp/vpnns-resolv.conf
    for d in $(echo "$dns" | tr ',' ' '); do
        echo "nameserver $d" >> /tmp/vpnns-resolv.conf
    done
    sudo mv /tmp/vpnns-resolv.conf "/etc/netns/$NS/resolv.conf"

    # Add route for WireGuard endpoint to go through real interface
    local default_gw default_dev
    default_gw=$(ip route show default | awk '{print $3; exit}')
    default_dev=$(ip route show default | awk '{print $5; exit}')
    if [[ -n "$default_gw" && -n "$default_dev" ]]; then
        sudo ip netns exec "$NS" ip route add "$endpoint_ip/32" via "$default_gw" dev "$default_dev" 2>/dev/null || true
    fi

    # Save state
    mkdir -p "$STATE_DIR"
    echo "$conf" > "$STATE_DIR/config"
    echo "$endpoint_ip" > "$STATE_DIR/endpoint_ip"

    echo "VPN namespace is UP"
    echo "  Config:   $(basename "$conf")"
    echo "  Endpoint: $endpoint_host ($endpoint_ip:$endpoint_port)"
    echo "  Address:  $addr"
    echo ""
    echo "Run apps through VPN:"
    echo "  vpnns run firefox"
    echo "  vpnns run claude"
}

down() {
    echo "Tearing down VPN namespace..."
    sudo ip netns del "$NS" 2>/dev/null
    sudo rm -rf "/etc/netns/$NS"
    rm -rf "$STATE_DIR"
    echo "VPN namespace is DOWN"
}

run_cmd() {
    if ! ip netns list 2>/dev/null | grep -q "^$NS "; then
        up
    fi

    if [[ $# -eq 0 ]]; then
        echo "Usage: vpnns run <command...>"
        exit 1
    fi

    exec sudo ip netns exec "$NS" sudo -u "$USER" HOME="/home/$USER" bash -c 'shopt -s expand_aliases; source ~/.bashrc; eval "$@"' -- "$@"
}

status() {
    if ip netns list 2>/dev/null | grep -q "^$NS "; then
        echo "VPN namespace: ACTIVE"
        if [[ -f "$STATE_DIR/config" ]]; then
            echo "  Config: $(cat "$STATE_DIR/config")"
        fi
        echo ""
        echo "Interface:"
        sudo ip netns exec "$NS" ip addr show "$WG_IFACE" 2>/dev/null
        echo ""
        echo "WireGuard:"
        sudo ip netns exec "$NS" wg show 2>/dev/null
    else
        echo "VPN namespace: INACTIVE"
    fi
}

case "$1" in
    up)     up "$2" ;;
    down)   down ;;
    run)    shift; run_cmd "$@" ;;
    status) status ;;
    *)
        echo "vpnns - split tunnel via WireGuard network namespace"
        echo ""
        echo "Usage:"
        echo "  vpnns [-c <dir>] up                 Auto-select fastest server"
        echo "  vpnns [-c <dir>] up <config.conf>   Start with specific config"
        echo "  vpnns down                          Stop VPN namespace"
        echo "  vpnns run <command>                 Run command through VPN"
        echo "  vpnns status                        Show status"
        echo ""
        echo "Config dir (с *.conf): \$VPNNS_CONF_DIR или -c <dir>"
        echo "По умолчанию: \$HOME/Templates/vpn"
        ;;
esac
