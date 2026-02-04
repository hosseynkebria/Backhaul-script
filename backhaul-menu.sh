#!/usr/bin/env bash
set -euo pipefail

APP_NAME="backhaul"
BIN_PATH="/usr/local/bin/backhaul"
CONFIG_DIR="/etc/backhaul"
SERVICE_NAME="backhaul"
DEFAULT_TOKEN="Backhaul-Default-Token"
DEFAULT_TUNNEL_COUNT="4"
DEFAULT_TUNNEL_PORT_START="9000"
DEFAULT_TUNNEL_PORT_COUNT="4"

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    echo "Please run as root." >&2
    exit 1
  fi
}

prompt() {
  local message="$1"
  local default_value="${2-}"
  local input
  if [[ -n "$default_value" ]]; then
    read -r -p "$message [$default_value]: " input
    echo "${input:-$default_value}"
  else
    read -r -p "$message: " input
    echo "$input"
  fi
}

ensure_config_dir() {
  mkdir -p "$CONFIG_DIR"
}

ensure_binary() {
  if [[ ! -x "$BIN_PATH" ]]; then
    echo "Binary not found at $BIN_PATH."
    echo "Please place the backhaul binary there before enabling the service."
  fi
}

choose_protocol() {
  echo "Select protocol:"
  echo "1) tcp"
  echo "2) udp"
  echo "3) ws"
  echo "4) wss"
  echo "5) grpc"
  echo "6) quic"
  echo "7) custom"
  local choice
  choice=$(prompt "Protocol option" "1")
  case "$choice" in
    1) echo "tcp" ;;
    2) echo "udp" ;;
    3) echo "ws" ;;
    4) echo "wss" ;;
    5) echo "grpc" ;;
    6) echo "quic" ;;
    7) prompt "Custom protocol" ;;
    *) echo "tcp" ;;
  esac
}

calc_tunnel_port_end() {
  local start="$1"
  local count="$2"
  echo $((start + count - 1))
}

write_env_file() {
  local env_file="$1"
  shift
  : > "$env_file"
  for kv in "$@"; do
    echo "$kv" >> "$env_file"
  done
}

create_service() {
  local mode="$1"
  local env_file="$2"
  local unit_path="/etc/systemd/system/${SERVICE_NAME}-${mode}.service"

  cat > "$unit_path" <<'UNIT'
[Unit]
Description=Backhaul Service
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=ENV_FILE_REPLACE
ExecStart=BIN_PATH_REPLACE $BACKHAUL_ARGS
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
UNIT

  sed -i "s#ENV_FILE_REPLACE#${env_file}#g" "$unit_path"
  sed -i "s#BIN_PATH_REPLACE#${BIN_PATH}#g" "$unit_path"

  systemctl daemon-reload
  systemctl enable "${SERVICE_NAME}-${mode}.service"
  systemctl restart "${SERVICE_NAME}-${mode}.service"
}

configure_server() {
  require_root
  ensure_config_dir
  ensure_binary

  local bind_address
  bind_address=$(prompt "Bind address (IPv4 or IPv6, use :: for IPv6)" "::")
  local listen_port
  listen_port=$(prompt "Listen port" "7000")
  local protocol
  protocol=$(choose_protocol)
  local token
  token=$(prompt "Token" "$DEFAULT_TOKEN")
  local tunnel_count
  tunnel_count=$(prompt "Tunnel count" "$DEFAULT_TUNNEL_COUNT")
  local tunnel_port_start
  tunnel_port_start=$(prompt "Tunnel port start" "$DEFAULT_TUNNEL_PORT_START")
  local tunnel_port_count
  tunnel_port_count=$(prompt "Tunnel port count" "$DEFAULT_TUNNEL_PORT_COUNT")
  local tunnel_port_end
  tunnel_port_end=$(calc_tunnel_port_end "$tunnel_port_start" "$tunnel_port_count")

  local env_file="$CONFIG_DIR/server.env"
  write_env_file "$env_file" \
    "BACKHAUL_ARGS=server \\\n      --protocol ${protocol} \\\n      --listen ${bind_address}:${listen_port} \\\n      --token ${token} \\\n      --tunnel-count ${tunnel_count} \\\n      --tunnel-ports ${tunnel_port_start}-${tunnel_port_end}"

  echo "Server configuration saved to $env_file"
  create_service "server" "$env_file"
}

configure_client() {
  require_root
  ensure_config_dir
  ensure_binary

  local server_address
  server_address=$(prompt "Server address (IPv4 or IPv6)" "::1")
  local server_port
  server_port=$(prompt "Server port" "7000")
  local protocol
  protocol=$(choose_protocol)
  local token
  token=$(prompt "Token" "$DEFAULT_TOKEN")
  local local_bind
  local_bind=$(prompt "Local bind address" "127.0.0.1")
  local local_port
  local_port=$(prompt "Local bind port" "8000")
  local tunnel_count
  tunnel_count=$(prompt "Tunnel count" "$DEFAULT_TUNNEL_COUNT")
  local tunnel_port_start
  tunnel_port_start=$(prompt "Tunnel port start" "$DEFAULT_TUNNEL_PORT_START")
  local tunnel_port_count
  tunnel_port_count=$(prompt "Tunnel port count" "$DEFAULT_TUNNEL_PORT_COUNT")
  local tunnel_port_end
  tunnel_port_end=$(calc_tunnel_port_end "$tunnel_port_start" "$tunnel_port_count")

  local env_file="$CONFIG_DIR/client.env"
  write_env_file "$env_file" \
    "BACKHAUL_ARGS=client \\\n      --protocol ${protocol} \\\n      --remote ${server_address}:${server_port} \\\n      --token ${token} \\\n      --local ${local_bind}:${local_port} \\\n      --tunnel-count ${tunnel_count} \\\n      --tunnel-ports ${tunnel_port_start}-${tunnel_port_end}"

  echo "Client configuration saved to $env_file"
  create_service "client" "$env_file"
}

restart_service() {
  require_root
  local mode
  mode=$(prompt "Which service to restart? (server/client)" "server")
  systemctl restart "${SERVICE_NAME}-${mode}.service"
  systemctl status "${SERVICE_NAME}-${mode}.service" --no-pager
}

show_config() {
  require_root
  local mode
  mode=$(prompt "Which config to show? (server/client)" "server")
  local env_file="$CONFIG_DIR/${mode}.env"
  if [[ -f "$env_file" ]]; then
    echo "==== $env_file ===="
    cat "$env_file"
  else
    echo "Config not found: $env_file"
  fi
}

menu() {
  echo "Backhaul setup menu"
  echo "1) Configure Server"
  echo "2) Configure Client"
  echo "3) Restart Service"
  echo "4) Show Config"
  echo "5) Exit"
  local choice
  choice=$(prompt "Choose" "1")
  case "$choice" in
    1) configure_server ;;
    2) configure_client ;;
    3) restart_service ;;
    4) show_config ;;
    5) exit 0 ;;
    *) echo "Invalid option" ;;
  esac
}

main() {
  while true; do
    menu
    echo
  done
}

main "$@"
