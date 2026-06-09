#!/usr/bin/env bash
# BestTraceV6.sh - Linux VPS IPv6 回程路由一键测试
# Usage:
#   bash besttracev6.sh              # 测试默认 IPv6 节点
#   bash besttracev6.sh -i 240e::1   # 测试单个自定义 IPv6 地址
#   bash besttracev6.sh -a           # 测试默认 IPv6 节点 + IPv6 连通性
#   bash besttracev6.sh -h           # 查看帮助

set -Eeuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
PLAIN='\033[0m'

ROWS_CT=()
ROWS_CU=()
ROWS_CM=()
ROWS_EDU=()
ROWS_OTHER=()

RUN_CONNECTIVITY_CHECK=0
CUSTOM_IP=''
NEXTTRACE_BIN='nexttrace'

# 默认国内 IPv6 测试点：用于回程路由观察，地址可能随运营商策略变化，仅供参考。
IP_LIST=(
  '240e:18:10:a01::1'
  '2408:80f0:4100:2005::3'
  '2409:8080:0:4:2f1:293::'
  '2001:da8:2:5::2'
)
IP_ADDR=(
  '电信IPv6'
  '联通IPv6'
  '移动IPv6'
  '教育网IPv6'
)
ISP_CODES=(
  'CT'
  'CU'
  'CM'
  'EDU'
)

usage() {
  cat <<'EOF'
BestTraceV6.sh - Linux VPS IPv6 回程路由一键测试

用法:
  bash besttracev6.sh              测试默认 IPv6 节点
  bash besttracev6.sh -i <IPv6>    测试单个自定义 IPv6 地址
  bash besttracev6.sh -a           额外执行 IPv6 连通性检查
  bash besttracev6.sh -h           查看帮助

依赖:
  - curl
  - nexttrace，若未安装会自动尝试通过 https://nxtrace.org/nt 安装
EOF
}

print_banner() {
  echo -e "${GREEN}#############################################################${PLAIN}"
  echo -e "${GREEN}#          BestTraceV6.sh - Linux VPS IPv6 回程测试          #${PLAIN}"
  echo -e "${GREEN}#          基于 nexttrace，支持自定义 IPv6 测试点           #${PLAIN}"
  echo -e "${GREEN}#############################################################${PLAIN}"
}

next_line() {
  echo -e "${SKYBLUE}----------------------------------------------------------------------${PLAIN}"
}

strip_ansi() {
  sed -E 's/\x1b\[[0-9;]*m//g'
}

is_ipv6() {
  local ip=$1
  [[ "$ip" == *:* ]]
}

need_cmd() {
  local cmd=$1
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${RED}错误：缺少命令 ${cmd}${PLAIN}" >&2
    exit 1
  fi
}

ensure_nexttrace() {
  if command -v "$NEXTTRACE_BIN" >/dev/null 2>&1; then
    return 0
  fi

  echo -e "${YELLOW}未检测到 nexttrace，正在尝试安装...${PLAIN}"
  need_cmd curl
  curl -fsSL https://nxtrace.org/nt | bash

  if ! command -v "$NEXTTRACE_BIN" >/dev/null 2>&1; then
    echo -e "${RED}错误：nexttrace 安装失败，请手动安装后重试。${PLAIN}" >&2
    exit 1
  fi
}

check_ipv6_connectivity() {
  echo -e "${YELLOW}>>> [IPv6 连通性检查]${PLAIN}"

  if ip -6 route show default 2>/dev/null | grep -q .; then
    echo -e "   默认 IPv6 路由：${GREEN}存在${PLAIN}"
  else
    echo -e "   默认 IPv6 路由：${RED}不存在${PLAIN}"
  fi

  if ping -6 -c 3 -W 2 2606:4700:4700::1111 >/dev/null 2>&1; then
    echo -e "   外网 IPv6 Ping：${GREEN}可达${PLAIN}"
  else
    echo -e "   外网 IPv6 Ping：${RED}不可达${PLAIN}"
  fi

  next_line
}

analyze_route() {
  local log_content=$1
  local isp_type=$2
  local target_name=$3
  local target_ip=$4

  local clean_content
  clean_content=$(printf '%s' "$log_content" | strip_ansi)

  local has_as4809 has_as9929 has_as4837 has_cmin2 has_cmi has_cernet domestic_segment domestic_has_4809
  has_as4809=$(printf '%s' "$clean_content" | grep -E 'AS4809|59\.43\.' || true)
  has_as9929=$(printf '%s' "$clean_content" | grep -E 'AS9929|AS10099' || true)
  has_as4837=$(printf '%s' "$clean_content" | grep -E 'AS4837|219\.158\.' || true)
  has_cmin2=$(printf '%s' "$clean_content" | grep -E 'AS58807' || true)
  has_cmi=$(printf '%s' "$clean_content" | grep -E 'AS58453|AS9808|223\.120\.' || true)
  has_cernet=$(printf '%s' "$clean_content" | grep -Ei 'AS4538|CERNET|education|edu' || true)
  domestic_segment=$(printf '%s' "$clean_content" | grep -Ei 'China|CN|Beijing|Shanghai|Guangzhou|Shenzhen|Chengdu|Anhui|Sichuan|Guangdong' || true)
  domestic_has_4809=$(printf '%s' "$domestic_segment" | grep -E 'AS4809|59\.43\.' || true)

  local ret_color_type=''

  echo -e "${YELLOW}>>> [智能分析] 线路判定 (目标: ${isp_type})：${PLAIN}"

  if [[ -n "$domestic_has_4809" ]]; then
    echo -e "   类型：${GREEN}${BOLD}电信 CN2 GIA / 精品网特征 (AS4809)${PLAIN}"
    echo '   详情：检测到国内段 AS4809 / 59.43 特征。'
    ret_color_type="${GREEN}CN2/GIA特征${PLAIN}"
  elif [[ -n "$has_as9929" ]]; then
    echo -e "   类型：${GREEN}${BOLD}联通 9929 / A网特征${PLAIN}"
    echo '   详情：检测到 AS9929 / AS10099。'
    ret_color_type="${GREEN}联通9929${PLAIN}"
  elif [[ -n "$has_cmin2" ]]; then
    echo -e "   类型：${GREEN}${BOLD}移动 CMIN2 特征 (AS58807)${PLAIN}"
    echo '   详情：检测到移动高端精品网 AS58807。'
    ret_color_type="${GREEN}移动CMIN2${PLAIN}"
  elif [[ -n "$has_as4809" ]]; then
    echo -e "   类型：${YELLOW}${BOLD}电信 CN2 / AS4809 特征${PLAIN}"
    echo '   详情：检测到 AS4809，但未确认国内段。'
    ret_color_type="${YELLOW}CN2特征${PLAIN}"
  elif [[ -n "$has_as4837" ]]; then
    echo -e "   类型：${SKYBLUE}联通 4837 / 169 骨干特征${PLAIN}"
    ret_color_type="${SKYBLUE}联通4837${PLAIN}"
  elif [[ -n "$has_cmi" ]]; then
    echo -e "   类型：${SKYBLUE}移动 CMI 特征${PLAIN}"
    ret_color_type="${SKYBLUE}移动CMI${PLAIN}"
  elif [[ -n "$has_cernet" ]]; then
    echo -e "   类型：${SKYBLUE}教育网 CERNET 特征${PLAIN}"
    ret_color_type="${SKYBLUE}教育网${PLAIN}"
  else
    case "$isp_type" in
      CT)
        echo -e "   类型：${RED}电信普通 IPv6 / 未识别精品网特征${PLAIN}"
        ret_color_type="${RED}电信普通${PLAIN}"
        ;;
      CU)
        echo -e "   类型：${RED}联通普通 IPv6 / 未识别精品网特征${PLAIN}"
        ret_color_type="${RED}联通普通${PLAIN}"
        ;;
      CM)
        echo -e "   类型：${PURPLE}移动普通 IPv6 / 未识别精品网特征${PLAIN}"
        ret_color_type="${PURPLE}移动普通${PLAIN}"
        ;;
      EDU)
        echo -e "   类型：${SKYBLUE}教育网 IPv6 / CERNET${PLAIN}"
        ret_color_type="${SKYBLUE}教育网${PLAIN}"
        ;;
      *)
        echo '   类型：其他/混合网络'
        ret_color_type='其他网络'
        ;;
    esac
  fi

  local summary_line
  summary_line=$(printf '%-14s %-39s %-20b' "$target_name" "$target_ip" "$ret_color_type")

  case "$isp_type" in
    CT) ROWS_CT+=("$summary_line") ;;
    CU) ROWS_CU+=("$summary_line") ;;
    CM) ROWS_CM+=("$summary_line") ;;
    EDU) ROWS_EDU+=("$summary_line") ;;
    *) ROWS_OTHER+=("$summary_line") ;;
  esac
}

detect_isp_type() {
  local log_content=$1
  local lower_content
  lower_content=$(printf '%s' "$log_content" | tr '[:upper:]' '[:lower:]')

  if printf '%s' "$lower_content" | grep -qE 'telecom|chinanet|ct|as4134|as4809'; then
    echo 'CT'
  elif printf '%s' "$lower_content" | grep -qE 'unicom|cu|as4837|as9929|as10099'; then
    echo 'CU'
  elif printf '%s' "$lower_content" | grep -qE 'mobile|cmcc|cmi|as9808|as58453|as58807'; then
    echo 'CM'
  elif printf '%s' "$lower_content" | grep -qE 'education|cernet|edu|as4538'; then
    echo 'EDU'
  else
    echo 'OTHER'
  fi
}

print_final_summary() {
  echo ''
  print_banner
  echo -e '节点名称       IPv6 地址                                  线路类型'
  echo '----------------------------------------------------------------------'

  local line
  for line in "${ROWS_CT[@]}"; do echo -e "$line"; done
  for line in "${ROWS_CU[@]}"; do echo -e "$line"; done
  for line in "${ROWS_CM[@]}"; do echo -e "$line"; done
  for line in "${ROWS_EDU[@]}"; do echo -e "$line"; done
  for line in "${ROWS_OTHER[@]}"; do echo -e "$line"; done

  echo '----------------------------------------------------------------------'
  echo -e "${YELLOW}* 提示：IPv6 路由与线路类型判断仅供参考，请以完整 traceroute 跳点为准。${PLAIN}"
  echo ''
}

run_trace() {
  local target_name=$1
  local target_ip=$2
  local isp_type=$3
  local tmp_log
  tmp_log=$(mktemp)

  echo -e "正在测试: ${GREEN}${target_name}${PLAIN} [${target_ip}]"
  if "$NEXTTRACE_BIN" "$target_ip" -6 -q 1 -M | tee "$tmp_log"; then
    if grep -qiE 'cannot determine local IPv6 address|network is unreachable|no route to host' "$tmp_log"; then
      echo -e "${RED}IPv6 不可用或无可用 IPv6 出口：${target_ip}${PLAIN}" >&2
      ROWS_OTHER+=("$(printf '%-14s %-39s %-20s' "$target_name" "$target_ip" 'IPv6不可用')")
    else
      analyze_route "$(<"$tmp_log")" "$isp_type" "$target_name" "$target_ip"
    fi
  else
    echo -e "${RED}nexttrace 执行失败：${target_ip}${PLAIN}" >&2
    ROWS_OTHER+=("$(printf '%-14s %-39s %-20s' "$target_name" "$target_ip" '测试失败')")
  fi

  rm -f "$tmp_log"
  next_line
}

while getopts ':i:ah' opt; do
  case "$opt" in
    i) CUSTOM_IP=$OPTARG ;;
    a) RUN_CONNECTIVITY_CHECK=1 ;;
    h) usage; exit 0 ;;
    :) echo -e "${RED}错误：-${OPTARG} 需要参数${PLAIN}" >&2; usage; exit 1 ;;
    \?) echo -e "${RED}错误：未知选项 -${OPTARG}${PLAIN}" >&2; usage; exit 1 ;;
  esac
done

print_banner
ensure_nexttrace

if [[ "$RUN_CONNECTIVITY_CHECK" -eq 1 ]]; then
  check_ipv6_connectivity
fi

if [[ -n "$CUSTOM_IP" ]]; then
  if ! is_ipv6 "$CUSTOM_IP"; then
    echo -e "${RED}错误：-i 参数必须是 IPv6 地址。${PLAIN}" >&2
    exit 1
  fi
  run_trace '自定义IPv6' "$CUSTOM_IP" 'OTHER'
  print_final_summary
  exit 0
fi

for i in "${!IP_LIST[@]}"; do
  run_trace "${IP_ADDR[$i]}" "${IP_LIST[$i]}" "${ISP_CODES[$i]}"
done

print_final_summary
