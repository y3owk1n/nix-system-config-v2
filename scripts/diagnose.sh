#!/bin/bash

# Performance Diagnostic Tool for Software Development
# Comprehensive monitoring for memory leaks, CPU spikes, and performance issues
# Usage: ./diagnose.sh [duration_in_seconds]

set -uo pipefail

# Configuration
DEFAULT_DURATION=60
SAMPLE_INTERVAL=2
WARNING_CPU_THRESHOLD=50.0
WARNING_MEM_GROWTH_MB=10
ALERT_MEM_GROWTH_MB=50

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check for required commands
for cmd in fzf bc; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is not installed. Please install it first."
    exit 1
  fi
done

# Function to display process selection
select_process() {
  echo -e "${CYAN}Select a process to monitor (press Ctrl-C to cancel):${NC}"
  echo ""

  local selected
  selected=$(ps aux 2>/dev/null | tail -n +2 | fzf \
    --header="USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND" \
    --preview='echo {} | awk "{print \"PID: \" \$2 \"\nUser: \" \$1 \"\nCPU: \" \$3 \"%\nMemory: \" \$4 \"%\nVSZ: \" \$5 \" KB\nRSS: \" \$6 \" KB\nStatus: \" \$8 \"\nCommand: \" \$11}"' \
    --preview-window=up:8 2>/dev/null) || {
    echo ""
    echo "Process selection cancelled or failed."
    return 1
  }

  echo "$selected"
}

# Function to get memory usage in KB
get_memory_kb() {
  local pid=$1
  ps -p "$pid" -o rss= 2>/dev/null || echo "0"
}

# Function to get virtual memory in KB
get_virtual_memory_kb() {
  local pid=$1
  ps -p "$pid" -o vsz= 2>/dev/null || echo "0"
}

# Function to get CPU usage
get_cpu_percent() {
  local pid=$1
  ps -p "$pid" -o %cpu= 2>/dev/null || echo "0"
}

# Function to get thread count
get_thread_count() {
  local pid=$1
  # macOS uses different syntax
  if [[ $OSTYPE == "darwin"* ]]; then
    ps -M -p "$pid" 2>/dev/null | tail -n +2 | wc -l | tr -d ' '
  else
    ps -o nlwp= -p "$pid" 2>/dev/null || echo "0"
  fi
}

# Function to get file descriptors (macOS)
get_fd_count() {
  local pid=$1
  if [[ $OSTYPE == "darwin"* ]]; then
    lsof -p "$pid" 2>/dev/null | wc -l | tr -d ' '
  else
    ls /proc/$pid/fd 2>/dev/null | wc -l || echo "0"
  fi
}

# Function to format bytes
format_bytes() {
  local kb=$1
  local abs_kb=$kb
  local sign=""

  # Handle negative values
  if ((kb < 0)); then
    abs_kb=$((kb * -1))
    sign="-"
  fi

  if ((abs_kb < 1024)); then
    echo "${sign}${abs_kb} KB"
  elif ((abs_kb < 1048576)); then
    echo "${sign}$(echo "scale=2; $abs_kb / 1024" | bc) MB"
  else
    echo "${sign}$(echo "scale=2; $abs_kb / 1048576" | bc) GB"
  fi
}

# Function to calculate standard deviation
calculate_stddev() {
  local values=("$@")
  local n=${#values[@]}
  local sum=0
  local mean=0
  local variance=0

  # Calculate mean
  for val in "${values[@]}"; do
    sum=$(echo "$sum + $val" | bc)
  done
  mean=$(echo "scale=2; $sum / $n" | bc)

  # Calculate variance
  for val in "${values[@]}"; do
    local diff=$(echo "$val - $mean" | bc)
    variance=$(echo "$variance + ($diff * $diff)" | bc)
  done
  variance=$(echo "scale=2; $variance / $n" | bc)

  # Standard deviation is square root of variance
  echo "sqrt($variance)" | bc
}

# Function to detect memory trend
detect_memory_trend() {
  # Use indirect reference for bash 3.x compatibility
  local array_name=$1
  eval "local samples=(\"\${${array_name}[@]}\")"
  local n=${#samples[@]}

  if ((n < 5)); then
    echo "insufficient_data"
    return
  fi

  # Simple linear regression to detect trend
  local sum_x=0
  local sum_y=0
  local sum_xy=0
  local sum_x2=0

  for ((i = 0; i < n; i++)); do
    sum_x=$((sum_x + i))
    sum_y=$((sum_y + ${samples[i]}))
    sum_xy=$((sum_xy + i * ${samples[i]}))
    sum_x2=$((sum_x2 + i * i))
  done

  # Slope = (n*sum_xy - sum_x*sum_y) / (n*sum_x2 - sum_x*sum_x)
  local numerator=$((n * sum_xy - sum_x * sum_y))
  local denominator=$((n * sum_x2 - sum_x * sum_x))

  if ((denominator == 0)); then
    echo "stable"
    return
  fi

  local slope=$(echo "scale=4; $numerator / $denominator" | bc)
  local slope_abs=$(echo "$slope" | tr -d '-')

  # Classify trend based on slope
  if (($(echo "$slope > 100" | bc -l))); then
    echo "increasing"
  elif (($(echo "$slope < -100" | bc -l))); then
    echo "decreasing"
  elif (($(echo "$slope_abs < 10" | bc -l))); then
    echo "stable"
  else
    echo "fluctuating"
  fi
}

# Main monitoring function with enhanced diagnostics
monitor_process() {
  local pid=$1
  local cmd=$2
  local duration=${3:-$DEFAULT_DURATION}
  local interval=$SAMPLE_INTERVAL
  local samples=$((duration / interval))

  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${CYAN}Performance Diagnostic Report${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo "Process: $cmd"
  echo "PID: $pid"
  echo "Duration: ${duration}s (sampling every ${interval}s)"
  echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  # Validate PID is numeric and not empty
  if [[ -z $pid ]] || ! [[ $pid =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid PID '$pid'. Must be a number.${NC}"
    exit 1
  fi

  # Check if process exists
  if ! ps -p "$pid" >/dev/null 2>&1; then
    echo -e "${RED}Error: Process $pid does not exist or has terminated.${NC}"
    exit 1
  fi

  # Get initial process info
  echo -e "${CYAN}Initial Process Information:${NC}"
  local initial_threads=$(get_thread_count "$pid")
  local initial_fds=$(get_fd_count "$pid")
  echo "  Threads: $initial_threads"
  echo "  File Descriptors: $initial_fds"
  echo ""

  # Arrays to store measurements
  local -a memory_samples=()
  local -a vmem_samples=()
  local -a cpu_samples=()
  local -a thread_samples=()
  local -a fd_samples=()
  local -a timestamps=()

  # Performance anomalies
  local cpu_spike_count=0
  local mem_spike_count=0
  local max_cpu=0
  local max_cpu_time=0

  echo -e "${CYAN}Real-time Monitoring:${NC}"
  printf "%-7s | %-12s | %-12s | %-6s | %-9s | %-4s | %-5s\n" \
    "Time" "RSS" "VSZ" "CPU%" "Memory" "Thrd" "FDs"
  echo "--------|--------------|--------------|--------|-----------|------|------"

  local start_time=$(date +%s)
  local prev_mem=0

  for ((i = 0; i < samples; i++)); do
    # Check if process still exists
    if ! ps -p "$pid" >/dev/null 2>&1; then
      echo ""
      echo -e "${YELLOW}Warning: Process terminated during monitoring at ${i}s.${NC}"
      break
    fi

    local current_time=$(($(date +%s) - start_time))
    local mem=$(get_memory_kb "$pid")
    local vmem=$(get_virtual_memory_kb "$pid")
    local cpu=$(get_cpu_percent "$pid")
    local threads=$(get_thread_count "$pid")
    local fds=$(get_fd_count "$pid")

    memory_samples+=("$mem")
    vmem_samples+=("$vmem")
    cpu_samples+=("$cpu")
    thread_samples+=("$threads")
    fd_samples+=("$fds")
    timestamps+=("$current_time")

    # Calculate memory delta
    local delta=""
    local delta_kb=0
    if ((i > 0)); then
      delta_kb=$((mem - prev_mem))
      delta=$(format_bytes $delta_kb)

      # Detect memory spikes (>10MB increase in one sample)
      if ((delta_kb > 10240)); then
        mem_spike_count=$((mem_spike_count + 1))
        delta="${delta} ⚠️"
      fi
    else
      delta="baseline"
    fi

    # Detect CPU spikes and format output
    local cpu_int=${cpu%.*}
    if (($(echo "$cpu > $max_cpu" | bc -l))); then
      max_cpu=$cpu
      max_cpu_time=$current_time
    fi

    if (($(echo "$cpu > $WARNING_CPU_THRESHOLD" | bc -l))); then
      cpu_spike_count=$((cpu_spike_count + 1))
      # Use echo -e for color codes
      echo -e "$(printf "%-7s | %-12s | %-12s | ${RED}%-6s${NC} | %-9s | %-4s | %-5s" \
        "${current_time}s" \
        "$(format_bytes $mem)" \
        "$(format_bytes $vmem)" \
        "$cpu%" \
        "$delta" \
        "$threads" \
        "$fds")"
    else
      printf "%-7s | %-12s | %-12s | %-6s | %-9s | %-4s | %-5s\n" \
        "${current_time}s" \
        "$(format_bytes $mem)" \
        "$(format_bytes $vmem)" \
        "$cpu%" \
        "$delta" \
        "$threads" \
        "$fds"
    fi

    prev_mem=$mem

    # Sleep for interval (except on last iteration)
    if ((i < samples - 1)); then
      sleep $interval
    fi
  done

  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${CYAN}Diagnostic Analysis${NC}"
  echo -e "${BLUE}========================================${NC}"

  # Calculate statistics
  local min_mem=${memory_samples[0]}
  local max_mem=${memory_samples[0]}
  local total_mem=0
  local total_cpu=0

  for mem in "${memory_samples[@]}"; do
    ((mem < min_mem)) && min_mem=$mem
    ((mem > max_mem)) && max_mem=$mem
    total_mem=$((total_mem + mem))
  done

  for cpu in "${cpu_samples[@]}"; do
    total_cpu=$(echo "$total_cpu + $cpu" | bc)
  done

  local avg_mem=$((total_mem / ${#memory_samples[@]}))
  local avg_cpu=$(echo "scale=2; $total_cpu / ${#cpu_samples[@]}" | bc)
  local mem_growth=$((max_mem - min_mem))
  local mem_growth_mb=$(echo "scale=2; $mem_growth / 1024" | bc)
  local mem_growth_percent=$(echo "scale=2; ($mem_growth * 100) / $min_mem" | bc)
  local final_mem=${memory_samples[${#memory_samples[@]} - 1]}
  local actual_growth=$((final_mem - memory_samples[0]))
  local actual_growth_mb=$(echo "scale=2; $actual_growth / 1024" | bc)

  # Thread and FD analysis
  local final_threads=${thread_samples[${#thread_samples[@]} - 1]}
  local thread_change=$((final_threads - initial_threads))
  local final_fds=${fd_samples[${#fd_samples[@]} - 1]}
  local fd_change=$((final_fds - initial_fds))

  # Detect memory trend
  local mem_trend=$(detect_memory_trend memory_samples)

  echo ""
  echo -e "${CYAN}📊 Memory Analysis:${NC}"
  echo "  Initial:       $(format_bytes ${memory_samples[0]})"
  echo "  Final:         $(format_bytes $final_mem)"
  echo "  Minimum:       $(format_bytes $min_mem)"
  echo "  Maximum:       $(format_bytes $max_mem)"
  echo "  Average:       $(format_bytes $avg_mem)"
  echo "  Peak Growth:   $(format_bytes $mem_growth) (${mem_growth_percent}%)"
  echo "  Net Change:    $(format_bytes $actual_growth)"
  echo "  Trend:         $mem_trend"
  echo "  Spikes (>10MB):$mem_spike_count"

  echo ""
  echo -e "${CYAN}⚡ CPU Analysis:${NC}"
  echo "  Average:       ${avg_cpu}%"
  echo "  Peak:          ${max_cpu}% (at ${max_cpu_time}s)"
  echo "  High CPU Count:$cpu_spike_count samples >${WARNING_CPU_THRESHOLD}%"

  echo ""
  echo -e "${CYAN}🧵 Resource Usage:${NC}"
  echo "  Initial Threads: $initial_threads"
  echo "  Final Threads:   $final_threads (change: $thread_change)"
  echo "  Initial FDs:     $initial_fds"
  echo "  Final FDs:       $final_fds (change: $fd_change)"

  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${CYAN}🔍 Performance Diagnosis${NC}"
  echo -e "${BLUE}========================================${NC}"

  local issues_found=0

  # Memory leak detection
  echo ""
  if [[ $mem_trend == "increasing" ]] && (($(echo "$actual_growth_mb > $ALERT_MEM_GROWTH_MB" | bc -l))); then
    echo -e "${RED}❌ CRITICAL: Potential Memory Leak Detected!${NC}"
    echo "   • Memory continuously increasing: $(format_bytes $actual_growth) net growth"
    echo "   • Recommendation: Investigate memory allocations and ensure proper cleanup"
    issues_found=$((issues_found + 1))
  elif [[ $mem_trend == "increasing" ]] && (($(echo "$actual_growth_mb > $WARNING_MEM_GROWTH_MB" | bc -l))); then
    echo -e "${YELLOW}⚠️  WARNING: Gradual Memory Growth${NC}"
    echo "   • Memory growing: $(format_bytes $actual_growth)"
    echo "   • May be normal for initialization or caching"
    echo "   • Monitor over longer periods to confirm"
    issues_found=$((issues_found + 1))
  elif ((mem_spike_count > 3)); then
    echo -e "${YELLOW}⚠️  WARNING: Multiple Memory Spikes Detected${NC}"
    echo "   • $mem_spike_count sudden memory increases >10MB"
    echo "   • Check for large allocations or memory churn"
    issues_found=$((issues_found + 1))
  else
    echo -e "${GREEN}✓ Memory: Stable and healthy${NC}"
    echo "   • Net change: $(format_bytes $actual_growth)"
    echo "   • No concerning patterns detected"
  fi

  # CPU analysis
  echo ""
  if ((cpu_spike_count > 5)); then
    echo -e "${YELLOW}⚠️  WARNING: High CPU Usage Detected${NC}"
    echo "   • CPU exceeded ${WARNING_CPU_THRESHOLD}% for $cpu_spike_count samples"
    echo "   • Peak: ${max_cpu}% at ${max_cpu_time}s"
    echo "   • For window managers: Check event loop efficiency"
    echo "   • For CLI tools: Profile hot paths in the code"
    issues_found=$((issues_found + 1))
  elif (($(echo "$max_cpu > 80" | bc -l))); then
    echo -e "${YELLOW}⚠️  WARNING: CPU Spike Detected${NC}"
    echo "   • Peak CPU: ${max_cpu}% at ${max_cpu_time}s"
    echo "   • Check for expensive operations or blocking calls"
    issues_found=$((issues_found + 1))
  else
    echo -e "${GREEN}✓ CPU: Normal usage patterns${NC}"
    echo "   • Average: ${avg_cpu}%, Peak: ${max_cpu}%"
  fi

  # Thread analysis
  echo ""
  if ((thread_change > 10)); then
    echo -e "${YELLOW}⚠️  WARNING: Thread Count Increased Significantly${NC}"
    echo "   • Threads: $initial_threads → $final_threads (+$thread_change)"
    echo "   • May indicate thread leaks or excessive threading"
    issues_found=$((issues_found + 1))
  elif ((thread_change > 5)); then
    echo -e "${YELLOW}⚡ NOTICE: Thread Count Increased${NC}"
    echo "   • Threads: $initial_threads → $final_threads (+$thread_change)"
    echo "   • Monitor if this continues to grow"
  else
    echo -e "${GREEN}✓ Threads: Stable count${NC}"
    echo "   • Change: $thread_change"
  fi

  # File descriptor analysis
  echo ""
  if ((fd_change > 50)); then
    echo -e "${RED}❌ CRITICAL: File Descriptor Leak Detected!${NC}"
    echo "   • FDs: $initial_fds → $final_fds (+$fd_change)"
    echo "   • Check for unclosed files, sockets, or pipes"
    issues_found=$((issues_found + 1))
  elif ((fd_change > 20)); then
    echo -e "${YELLOW}⚠️  WARNING: File Descriptors Increasing${NC}"
    echo "   • FDs: $initial_fds → $final_fds (+$fd_change)"
    echo "   • Ensure proper resource cleanup"
    issues_found=$((issues_found + 1))
  else
    echo -e "${GREEN}✓ File Descriptors: Normal${NC}"
    echo "   • Change: $fd_change"
  fi

  # Overall assessment
  echo ""
  echo -e "${BLUE}========================================${NC}"
  if ((issues_found == 0)); then
    echo -e "${GREEN}✅ Overall Assessment: No Performance Issues Detected${NC}"
    echo "   Your application appears to be running efficiently!"
  else
    echo -e "${YELLOW}⚠️  Overall Assessment: $issues_found Issue(s) Found${NC}"
    echo "   Review the warnings above and monitor over longer periods."
  fi
  echo -e "${BLUE}========================================${NC}"
  echo ""
  echo "Tip: For window managers, also check X11/Wayland event handling."
  echo "Tip: Use 'sudo dtruss -p $pid' (macOS) or 'strace -p $pid' (Linux) for syscall tracing."
  echo ""
}

# Main script execution
main() {
  local duration=${1:-$DEFAULT_DURATION}

  # Select process
  if ! selected=$(select_process); then
    exit 0
  fi

  if [[ -z $selected ]]; then
    echo "No process selected. Exiting."
    exit 0
  fi

  # Extract PID and command
  pid=$(echo "$selected" | awk '{print $2}')
  cmd=$(echo "$selected" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; printf "\n"}' | sed 's/[[:space:]]*$//')

  # Clean the PID: remove ALL whitespace and non-digits
  pid=$(echo "$pid" | tr -cd '0-9')

  # Start monitoring
  monitor_process "$pid" "$cmd" "$duration"
}

# Run with optional duration argument
main "$@"
