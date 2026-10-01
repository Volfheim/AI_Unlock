#!/system/bin/sh

MODULE_NAME="AI Unlock"
HOSTS_PATH="$MODDIR/system/etc/hosts"
PRIMARY_HOSTS_URL="https://geohide.ru/hosts"
FALLBACK_HOSTS_URL="https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/hosts"
SECONDARY_HOSTS_URL="https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/hosts"
GOOGLE_DOMAINS_URL="https://raw.githubusercontent.com/Internet-Helper/GeoHideDNS/refs/heads/main/lists/domains-google.txt"
MALW_HOSTS_URL="https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/hosts"
AVENCORES_HOSTS_URL=""
CHATGPT_VOICE_JSON_URL="https://openai.com/chatgpt-voice.json"
ADBLOCK_PRIMARY_URL="https://adaway.org/hosts.txt"
ADBLOCK_SECONDARY_URL="https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt"
STATE_DIR="$MODDIR/state"
BACKUP_DIR="$STATE_DIR/backups"
LOG_FILE="$STATE_DIR/update.log"
MIN_ADBLOCK_ENTRIES="${MIN_ADBLOCK_ENTRIES:-5000}"
MAX_ADBLOCK_ENTRIES="${MAX_ADBLOCK_ENTRIES:-25000}"
MAX_ROUTED_ENTRIES="${MAX_ROUTED_ENTRIES:-6000}"
MAX_HOSTS_BYTES="${MAX_HOSTS_BYTES:-2097152}"
MAX_SOURCE_BYTES="${MAX_SOURCE_BYTES:-4194304}"
MAX_SOURCE_LINES="${MAX_SOURCE_LINES:-100000}"
MAX_DOWNLOAD_BYTES="${MAX_DOWNLOAD_BYTES:-4194304}"
ROUTE_POOL_LIMIT="${ROUTE_POOL_LIMIT:-1}"
ROUTE_PROBE_LIMIT="${ROUTE_PROBE_LIMIT:-8}"
GEOHIDE_BACKEND_CANDIDATES="46.8.158.6 193.233.112.67 193.233.112.68 217.60.245.219 217.60.245.233 143.20.64.192 2.27.118.34 192.255.159.240 192.255.159.241"
OPENAI_OVERRIDE_IPS_FALLBACK="46.8.158.6 193.233.112.67 193.233.112.68"
GEMINI_OVERRIDE_IPS_FALLBACK="46.8.158.6 193.233.112.67 193.233.112.68"
CLAUDE_OVERRIDE_IPS_FALLBACK="46.8.158.6 193.233.112.67 193.233.112.68"
OPENAI_BACKEND_CANDIDATES="$GEOHIDE_BACKEND_CANDIDATES"
GEMINI_BACKEND_CANDIDATES="$GEOHIDE_BACKEND_CANDIDATES"
CLAUDE_BACKEND_CANDIDATES="$GEOHIDE_BACKEND_CANDIDATES"
OPENAI_OVERRIDE_DOMAINS_FALLBACK="ab.chatgpt.com android.chat.openai.com api.chatgpt.com api.openai.com arena.openai.com auth.openai.com auth0.openai.com beta.api.openai.com beta.openai.com cdn.oaistatic.com cdn.openai.com cdn.platform.openai.com chat.openai.com chatgpt.com developers.openai.com edge.chatgpt.com files.oaiusercontent.com ios.chat.openai.com oaistatic.com openai.com operator.chatgpt.com platform.api.openai.com platform.openai.com privacy-pass-issuer.api.chatgpt.com realtime.chatgpt.com search.chatgpt.com sora.chatgpt.com tcr9i.chat.openai.com videos.openai.com webrtc.chatgpt.com ws.chatgpt.com www.chatgpt.com www.openai.com"
GEMINI_OVERRIDE_DOMAINS_FALLBACK="ai.google.dev aisandbox-pa.googleapis.com aistudio.google.com aitestkitchen.withgoogle.com alkalicore-pa.clients6.google.com alkalimakersuite-pa.clients6.google.com apis.google.com appcatalyst.pa.googleapis.com assistant-s3-pa.googleapis.com bard.google.com daily-cloudcode-pa.googleapis.com datastudio.google.com deepmind.com deepmind.google developerprofiles-pa.googleapis.com geller-pa.googleapis.com gemini.google gemini.google.com generativeai.google generativelanguage.googleapis.com jules.google jules.google.com labs.google labs.google.com lookerstudio.google.com makersuite.google.com notebooklm-pa.googleapis.com notebooklm.google notebooklm.google.com notebook.google.com notebook.google notebook-pa.googleapis.com o.pki.goog opal.google opal.google.com opal.withgoogle.com people-pa.clients6.google.com proactivebackend-pa.googleapis.com robinfrontend-pa.googleapis.com signaler-pa.clients6.google.com stitch.withgoogle.com waa-pa.clients6.google.com webchannel-alkalimakersuite-pa.clients6.google.com"
CLAUDE_OVERRIDE_DOMAINS_FALLBACK="a.claude.ai a-api.anthropic.com a-cdn.anthropic.com anthropic.com api.anthropic.com api.claude.ai api.claude.com api.console.anthropic.com assets-proxy.anthropic.com auth.anthropic.com claude.ai claude.com console.anthropic.com downloads.claude.ai platform.claude.ai platform.claude.com s-cdn.anthropic.com statsig.anthropic.com status.anthropic.com support.anthropic.com www.anthropic.com www.claude.ai www.claude.com"
OPENAI_OVERRIDE_IPS="$OPENAI_OVERRIDE_IPS_FALLBACK"
GEMINI_OVERRIDE_IPS="$GEMINI_OVERRIDE_IPS_FALLBACK"
CLAUDE_OVERRIDE_IPS="$CLAUDE_OVERRIDE_IPS_FALLBACK"
OPENAI_OVERRIDE_DOMAINS="$OPENAI_OVERRIDE_DOMAINS_FALLBACK"
GEMINI_OVERRIDE_DOMAINS="$GEMINI_OVERRIDE_DOMAINS_FALLBACK"
CLAUDE_OVERRIDE_DOMAINS="$CLAUDE_OVERRIDE_DOMAINS_FALLBACK"
PROBE_IP_LIMIT=3
MODULES_ROOTS="${MODULES_ROOTS:-/data/adb/modules /data/adb/modules_update}"
LOCK_FILE="$STATE_DIR/.action.lock"

ensure_state_dirs() {
  mkdir -p "$STATE_DIR" "$BACKUP_DIR" 2>/dev/null
}

now_text() {
  date "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date
}

log_msg() {
  ensure_state_dirs
  echo "[$(now_text)] $*" >> "$LOG_FILE" 2>/dev/null
}

print_and_log() {
  echo "$*"
  log_msg "$*"
}

get_module_version() {
  sed -n 's/^version=//p' "$MODDIR/module.prop" 2>/dev/null | head -n 1
}

epoch_now() {
  date +%s 2>/dev/null || echo 0
}

file_hash() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" 2>/dev/null | awk '{print $1}'
  else
    cksum "$1" 2>/dev/null | awk '{print $1}'
  fi
}

line_count() {
  wc -l "$1" 2>/dev/null | awk '{print $1}'
}

byte_count() {
  wc -c "$1" 2>/dev/null | awk '{print $1}'
}

copy_file() {
  if command -v cp >/dev/null 2>&1; then
    cp -f "$1" "$2"
  else
    cat "$1" > "$2"
  fi
}

acquire_update_lock() {
  ensure_state_dirs
  if command -v flock >/dev/null 2>&1; then
    exec 9> "$LOCK_FILE" || return 1
    flock -n 9 || {
      print_and_log "Update is already running; this action was not duplicated."
      exec 9>&-
      return 1
    }
    return 0
  fi

  if mkdir "$LOCK_FILE.d" 2>/dev/null; then
    echo "$$" > "$LOCK_FILE.d/pid"
    return 0
  fi
  print_and_log "Update is already running; this action was not duplicated."
  return 1
}

release_update_lock() {
  if command -v flock >/dev/null 2>&1; then
    flock -u 9 2>/dev/null
    exec 9>&-
  else
    rm -f "$LOCK_FILE.d/pid" 2>/dev/null
    rmdir "$LOCK_FILE.d" 2>/dev/null
  fi
}

valid_ipv4() {
  ipv4_value="$1"
  old_ifs="$IFS"
  IFS=.
  set -- $ipv4_value
  IFS="$old_ifs"
  [ "$#" -eq 4 ] || return 1
  for ipv4_octet in "$@"; do
    case "$ipv4_octet" in
      ''|*[!0-9]*) return 1 ;;
    esac
    [ "$ipv4_octet" -le 255 ] 2>/dev/null || return 1
  done
  return 0
}

validate_ip_entries() {
  awk '
    function valid_ipv4(value, p, i) {
      split(value, p, ".")
      if (length(p) != 4) return 0
      for (i = 1; i <= 4; i++) if (p[i] !~ /^[0-9]+$/ || p[i] > 255) return 0
      return 1
    }
    function valid_ipv6(value, p, i, groups, compressed, compact) {
      if (value !~ /:/ || value !~ /^[0-9A-Fa-f:]+$/) return 0
      if (value ~ /::.*::/) return 0
      if ((value ~ /^:/ && value !~ /^::/) || (value ~ /:$/ && value !~ /::$/)) return 0
      compressed = index(value, "::") > 0
      compact = value
      if (compressed) sub(/::/, "", compact)
      if (compact == "") {
        groups = 0
      } else {
        groups = split(compact, p, ":")
        for (i = 1; i <= groups; i++) {
          if (p[i] == "" || length(p[i]) > 4 || p[i] !~ /^[0-9A-Fa-f]+$/) return 0
        }
      }
      if (compressed) return groups < 8
      return groups == 8
    }
    /^[[:space:]]*#/ || NF == 0 { next }
    $1 ~ /^[0-9A-Fa-f]/ {
      if ((!valid_ipv4($1) && !valid_ipv6($1)) || NF < 2 || $2 !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) bad = 1
    }
    END { exit bad ? 1 : 0 }
  ' "$1"
}

source_age_check() {
  source_file="$1"
  grep -qiE 'Последнее обновление|last update|updated|generated' "$source_file" || return 1
  source_iso="$(grep -m 1 'Последнее обновление' "$source_file" 2>/dev/null | sed -n 's/.*: *\([0-9][0-9]\)\.\([0-9][0-9]\)\.\([0-9][0-9][0-9][0-9]\).*/\3-\2-\1/p')"
  [ -n "$source_iso" ] || return 0
  source_epoch="$(date -d "$source_iso 00:00:00" +%s 2>/dev/null)"
  [ -n "$source_epoch" ] || return 0
  source_now="$(epoch_now)"
  [ "$source_epoch" -le "$((source_now + 172800))" ] || return 1
  [ "$source_epoch" -ge "$((source_now - 90 * 86400))" ] || return 1
  return 0
}

download_url() {
  download_url_arg="$1"
  download_out="$2"
  download_tmp="$download_out.part"
  download_meta="$download_out.meta"

  case "$download_url_arg" in
    "$PRIMARY_HOSTS_URL"|"$FALLBACK_HOSTS_URL"|"$SECONDARY_HOSTS_URL"|"$GOOGLE_DOMAINS_URL"|"$MALW_HOSTS_URL"|"$AVENCORES_HOSTS_URL"|"$CHATGPT_VOICE_JSON_URL"|"$ADBLOCK_PRIMARY_URL"|"$ADBLOCK_SECONDARY_URL") ;;
    *) return 1 ;;
  esac

  rm -f "$download_out" "$download_tmp" "$download_meta"

  if command -v curl >/dev/null 2>&1; then
    curl -L -f -sS --proto '=https' --proto-redir '=https' --max-filesize "$MAX_DOWNLOAD_BYTES" \
      --connect-timeout 15 --max-time 60 "$download_url_arg" -o "$download_tmp" \
      -w '%{url_effective}\n' > "$download_meta" 2>/dev/null
    download_status=$?
    [ "$download_status" -eq 0 ] || {
      rm -f "$download_tmp" "$download_meta"
      return 1
    }
    download_effective_url="$(tail -n 1 "$download_meta" 2>/dev/null)"
    download_source_host="$(printf '%s\n' "$download_url_arg" | sed -n 's#^https://\([^/:]*\).*#\1#p')"
    download_effective_host="$(printf '%s\n' "$download_effective_url" | sed -n 's#^https://\([^/:]*\).*#\1#p')"
    case "$download_source_host:$download_effective_host" in
      geohide.ru:geohide.ru|raw.githubusercontent.com:raw.githubusercontent.com|adaway.org:adaway.org|openai.com:openai.com|www.openai.com:openai.com|geohide.ru:www.geohide.ru|www.geohide.ru:geohide.ru|adaway.org:www.adaway.org|www.adaway.org:adaway.org) ;;
      *) rm -f "$download_tmp" "$download_meta"; return 1 ;;
    esac
  elif command -v wget >/dev/null 2>&1; then
    run_with_timeout 60 wget -q -O "$download_tmp" "$download_url_arg" >/dev/null 2>&1
    download_status=$?
  elif command -v busybox >/dev/null 2>&1; then
    run_with_timeout 60 busybox wget -q -O "$download_tmp" "$download_url_arg" >/dev/null 2>&1
    download_status=$?
  elif [ -x /data/adb/magisk/busybox ]; then
    run_with_timeout 60 /data/adb/magisk/busybox wget -q -O "$download_tmp" "$download_url_arg" >/dev/null 2>&1
    download_status=$?
  elif command -v toybox >/dev/null 2>&1; then
    run_with_timeout 60 toybox wget -O "$download_tmp" "$download_url_arg" >/dev/null 2>&1
    download_status=$?
  else
    return 127
  fi

  [ "${download_status:-1}" -eq 0 ] || {
    rm -f "$download_tmp" "$download_meta"
    return 1
  }
  download_size="$(byte_count "$download_tmp")"
  [ -s "$download_tmp" ] && [ "${download_size:-0}" -le "$MAX_DOWNLOAD_BYTES" ] || {
    rm -f "$download_tmp" "$download_meta"
    return 1
  }
  mv -f "$download_tmp" "$download_out"
  rm -f "$download_meta"
  [ -s "$download_out" ]
}

run_with_timeout() {
  seconds="$1"
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  else
    "$@"
  fi
}

validate_hosts_file() {
  file="$1"
  lines="$(line_count "$file")"
  bytes="$(byte_count "$file")"
  blocked_count="$(grep -Ec '^0\.0\.0\.0[[:space:]]+' "$file" 2>/dev/null)"

  [ -s "$file" ] || return 1
  [ "${lines:-0}" -le "$MAX_SOURCE_LINES" ] || return 1
  [ "${bytes:-0}" -le "$MAX_HOSTS_BYTES" ] || return 1
  [ "${lines:-0}" -ge "$MIN_ADBLOCK_ENTRIES" ] || return 1
  [ "${blocked_count:-0}" -ge "$MIN_ADBLOCK_ENTRIES" ] || return 1
  [ "${blocked_count:-0}" -le "$MAX_ADBLOCK_ENTRIES" ] || return 1

  if grep -qiE '<!DOCTYPE html|<html|</html>' "$file"; then
    return 1
  fi

  validate_ip_entries "$file" || return 1
  routed_count="$(awk '$1 ~ /^[1-9][0-9.]*$/ { count++ } END { print count + 0 }' "$file")"
  [ "${routed_count:-0}" -le "$MAX_ROUTED_ENTRIES" ] || return 1

  grep -q '^### AI Unlock Ultimate: hosts file' "$file" || return 1
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+gemini\.google\.com$' "$file" || return 1
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+generativelanguage\.googleapis\.com$' "$file" || return 1
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+chatgpt\.com$' "$file" || return 1
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+claude\.ai$' "$file" || return 1

  for protected_domain in $OPENAI_OVERRIDE_DOMAINS $GEMINI_OVERRIDE_DOMAINS $CLAUDE_OVERRIDE_DOMAINS; do
    grep -Eq '^0\.0\.0\.0[[:space:]]+'"$protected_domain"'$' "$file" && return 1
  done

  if grep -Eq '^0\.0\.0\.0[[:space:]]+([^[:space:]]+\.)?(chatgpt\.com|openai\.com|oaistatic\.com|oaiusercontent\.com|anthropic\.com|claude\.ai|claude\.com)$' "$file"; then
    return 1
  fi

  return 0
}

validate_adblock_hosts_file() {
  adblock_file="$1"
  adblock_count="$(grep -Ec '^(0\.0\.0\.0|127\.0\.0\.1)[[:space:]]+[A-Za-z0-9._-]+$' "$adblock_file" 2>/dev/null)"
  adblock_bytes="$(byte_count "$adblock_file")"

  [ -s "$adblock_file" ] || return 1
  [ "${adblock_bytes:-0}" -le "$MAX_DOWNLOAD_BYTES" ] || return 1
  [ "${adblock_count:-0}" -ge "$MIN_ADBLOCK_ENTRIES" ] || return 1
  [ "${adblock_count:-0}" -le "$MAX_ADBLOCK_ENTRIES" ] || return 1
  if grep -qiE '<!DOCTYPE html|<html|</html>' "$adblock_file"; then
    return 1
  fi

  return 0
}

validate_source_hosts_file() {
  source_file="$1"
  source_lines="$(line_count "$source_file")"
  source_bytes="$(byte_count "$source_file")"

  [ -s "$source_file" ] || return 1
  [ "${source_lines:-0}" -ge 500 ] || return 1
  [ "${source_lines:-0}" -le "$MAX_SOURCE_LINES" ] || return 1
  [ "${source_bytes:-0}" -le "$MAX_SOURCE_BYTES" ] || return 1
  if grep -qiE '<!DOCTYPE html|<html|</html>' "$source_file"; then
    return 1
  fi

  grep -Eq '^### (dns\.malw\.link|dns\.geohide\.ru|geohide\.ru): hosts file' "$source_file" || return 1
  grep -qiE 'Последнее обновление|last update|updated|generated' "$source_file" || return 1
  validate_ip_entries "$source_file" || return 1
  source_age_check "$source_file" || return 1
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+chatgpt\.com$' "$source_file" || return 1
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+gemini\.google\.com$' "$source_file" || return 1
}

validate_domain_list_file() {
  domain_file="$1"
  domain_count="$(sed 's/\r$//' "$domain_file" 2>/dev/null | grep -Ec '^[A-Za-z0-9][A-Za-z0-9._-]+$')"

  [ -s "$domain_file" ] || return 1
  [ "${domain_count:-0}" -ge 20 ] || return 1

  if grep -qiE '<!DOCTYPE html|<html|</html>' "$domain_file"; then
    return 1
  fi

  grep -Eq '^gemini\.google\.com\r?$' "$domain_file" || return 1
  grep -Eq '^generativelanguage\.googleapis\.com\r?$' "$domain_file" || return 1

  return 0
}

validate_malw_hosts_file() {
  malw_file="$1"
  malw_lines="$(line_count "$malw_file")"
  malw_bytes="$(byte_count "$malw_file")"

  [ -s "$malw_file" ] || return 1
  [ "${malw_lines:-0}" -ge 1000 ] || return 1
  [ "${malw_lines:-0}" -le "$MAX_SOURCE_LINES" ] || return 1
  [ "${malw_bytes:-0}" -le "$MAX_SOURCE_BYTES" ] || return 1

  if grep -qiE '<!DOCTYPE html|<html|</html>' "$malw_file"; then
    return 1
  fi

  grep -Eq '^### (dns\.malw\.link|geohide\.ru): hosts file' "$malw_file" || return 1
  grep -qiE 'Последнее обновление|last update|updated|generated' "$malw_file" || return 1
  validate_ip_entries "$malw_file" || return 1
  source_age_check "$malw_file" || return 1
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+chatgpt\.com$' "$malw_file" || return 1
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+gemini\.google\.com$' "$malw_file" || return 1
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+claude\.ai$' "$malw_file" || return 1

  return 0
}

validate_voice_json_file() {
  voice_file="$1"

  [ -s "$voice_file" ] || return 1

  if grep -qiE '<!DOCTYPE html|<html|</html>' "$voice_file"; then
    return 1
  fi

  grep -Eq '"creationTime"[[:space:]]*:[[:space:]]*"[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$voice_file" || return 1
  grep -Eq '"(ipv4Prefix|ipv6Prefix)"[[:space:]]*:[[:space:]]*"[0-9A-Fa-f:.]+/[0-9]+' "$voice_file" || return 1
  grep -q '^[[:space:]]*{' "$voice_file" || return 1
  tail -c 2 "$voice_file" 2>/dev/null | grep -q '}' || return 1

  return 0
}

merge_word_lists() {
  merge_result="$1"
  shift

  for merge_words in "$@"; do
    for merge_word in $merge_words; do
      case " $merge_result " in
        *" $merge_word "*) ;;
        *) merge_result="${merge_result:+$merge_result }$merge_word" ;;
      esac
    done
  done

  echo "$merge_result"
}

extract_malw_domains() {
  malw_extract_file="$1"
  malw_extract_category="$2"

  awk -v category="$malw_extract_category" '
    function is_openai(domain) {
      return domain ~ /(^|\.)chatgpt\.com$/ ||
             domain ~ /(^|\.)openai\.com$/ ||
             domain ~ /(^|\.)oaistatic\.com$/ ||
             domain ~ /(^|\.)oaiusercontent\.com$/
    }
    function is_gemini(domain) {
      return domain == "gemini.google" ||
             domain == "gemini.google.com" ||
             domain == "aistudio.google.com" ||
             domain == "generativelanguage.googleapis.com" ||
             domain == "webchannel-alkalimakersuite-pa.clients6.google.com" ||
             domain == "alkalimakersuite-pa.clients6.google.com" ||
             domain == "robinfrontend-pa.googleapis.com"
    }
    function is_claude(domain) {
      return domain ~ /(^|\.)anthropic\.com$/ ||
             domain ~ /(^|\.)claude\.ai$/ ||
             domain ~ /(^|\.)claude\.com$/
    }
    $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && $1 != "0.0.0.0" && NF >= 2 {
      domain = $2
      if ((category == "openai" && is_openai(domain)) ||
          (category == "gemini" && is_gemini(domain)) ||
          (category == "claude" && is_claude(domain))) {
        if (!seen[domain]++) {
          print domain
        }
      }
    }
  ' "$malw_extract_file"
}

extract_malw_ips() {
  malw_extract_file="$1"
  malw_extract_category="$2"

  awk -v category="$malw_extract_category" '
    function is_openai(domain) {
      return domain ~ /(^|\.)chatgpt\.com$/ ||
             domain ~ /(^|\.)openai\.com$/ ||
             domain ~ /(^|\.)oaistatic\.com$/ ||
             domain ~ /(^|\.)oaiusercontent\.com$/
    }
    function is_gemini(domain) {
      return domain == "gemini.google" ||
             domain == "gemini.google.com" ||
             domain == "aistudio.google.com" ||
             domain == "generativelanguage.googleapis.com" ||
             domain == "webchannel-alkalimakersuite-pa.clients6.google.com" ||
             domain == "alkalimakersuite-pa.clients6.google.com" ||
             domain == "robinfrontend-pa.googleapis.com"
    }
    function is_claude(domain) {
      return domain ~ /(^|\.)anthropic\.com$/ ||
             domain ~ /(^|\.)claude\.ai$/ ||
             domain ~ /(^|\.)claude\.com$/
    }
    $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && $1 != "0.0.0.0" && NF >= 2 {
      domain = $2
      if ((category == "openai" && is_openai(domain)) ||
          (category == "gemini" && is_gemini(domain)) ||
          (category == "claude" && is_claude(domain))) {
        if (!seen[$1]++) {
          print $1
        }
      }
    }
  ' "$malw_extract_file"
}

refresh_ai_overrides_from_malw() {
  malw_tmp="$STATE_DIR/malw.hosts.$$"

  for malw_url in "$MALW_HOSTS_URL" "$AVENCORES_HOSTS_URL"; do
    [ -n "$malw_url" ] || continue
    if ! download_url "$malw_url" "$malw_tmp"; then
      rm -f "$malw_tmp"
      print_and_log "AI source download failed: $malw_url"
      continue
    fi

    if validate_malw_hosts_file "$malw_tmp"; then
      break
    fi

    rm -f "$malw_tmp"
    print_and_log "Rejected AI source: not a valid dns.malw.link-style hosts file."
  done

  if [ ! -s "$malw_tmp" ] || ! validate_malw_hosts_file "$malw_tmp"; then
    rm -f "$malw_tmp"
    print_and_log "Using bundled AI fast-path: no valid external AI source available."
    return 0
  fi

  malw_openai_domains="$(extract_malw_domains "$malw_tmp" openai | tr '\n' ' ')"
  malw_gemini_domains="$(extract_malw_domains "$malw_tmp" gemini | tr '\n' ' ')"
  malw_claude_domains="$(extract_malw_domains "$malw_tmp" claude | tr '\n' ' ')"
  malw_openai_ips="$(extract_malw_ips "$malw_tmp" openai | tr '\n' ' ')"
  malw_gemini_ips="$(extract_malw_ips "$malw_tmp" gemini | tr '\n' ' ')"
  malw_claude_ips="$(extract_malw_ips "$malw_tmp" claude | tr '\n' ' ')"

  OPENAI_OVERRIDE_DOMAINS="$(merge_word_lists "$OPENAI_OVERRIDE_DOMAINS" "$malw_openai_domains")"
  GEMINI_OVERRIDE_DOMAINS="$(merge_word_lists "$GEMINI_OVERRIDE_DOMAINS" "$malw_gemini_domains")"
  CLAUDE_OVERRIDE_DOMAINS="$(merge_word_lists "$CLAUDE_OVERRIDE_DOMAINS" "$malw_claude_domains")"
  OPENAI_OVERRIDE_IPS="$(merge_word_lists "$OPENAI_OVERRIDE_IPS" "$malw_openai_ips")"
  GEMINI_OVERRIDE_IPS="$(merge_word_lists "$GEMINI_OVERRIDE_IPS" "$malw_gemini_ips")"
  CLAUDE_OVERRIDE_IPS="$(merge_word_lists "$CLAUDE_OVERRIDE_IPS" "$malw_claude_ips")"

  rm -f "$malw_tmp"
  print_and_log "Accepted AI source: $malw_url"
  return 0
}

load_gemini_domains_from_file() {
  domain_file="$1"
  loaded_domains="$(sed 's/\r$//' "$domain_file" 2>/dev/null | grep -E '^[A-Za-z0-9][A-Za-z0-9._-]+$' | awk '!seen[$0]++' | tr '\n' ' ')"

  [ -n "$loaded_domains" ] || return 1
  GEMINI_OVERRIDE_DOMAINS="$(merge_word_lists "$GEMINI_OVERRIDE_DOMAINS_FALLBACK" "$loaded_domains")"
}

refresh_gemini_override_domains() {
  domains_tmp="$STATE_DIR/domains-google.$$"

  if download_url "$GOOGLE_DOMAINS_URL" "$domains_tmp" && validate_domain_list_file "$domains_tmp" && load_gemini_domains_from_file "$domains_tmp"; then
    rm -f "$domains_tmp"
    print_and_log "Accepted Gemini domain list: $GOOGLE_DOMAINS_URL"
    return 0
  fi

  rm -f "$domains_tmp"
  GEMINI_OVERRIDE_DOMAINS="$GEMINI_OVERRIDE_DOMAINS_FALLBACK"
  print_and_log "Using bundled Gemini domain list."
  return 0
}

hosts_date_line() {
  grep -m 1 'Последнее обновление' "$1" 2>/dev/null | sed 's/^# //'
}

apply_ai_overrides() {
  override_file="$1"
  override_tmp="$STATE_DIR/hosts.ai.$$"
  source_date="$(grep -m 1 'Последнее обновление' "$override_file" 2>/dev/null | sed 's/^# //')"
  source_name="$(head -n 1 "$override_file" 2>/dev/null | sed 's/^### /Source: /')"

  awk \
    -v openai_domains="$OPENAI_OVERRIDE_DOMAINS" \
    -v openai_ips="$OPENAI_OVERRIDE_IPS_FALLBACK" \
    -v gemini_domains="$GEMINI_OVERRIDE_DOMAINS" \
    -v gemini_ips="$GEMINI_OVERRIDE_IPS_FALLBACK" \
    -v claude_domains="$CLAUDE_OVERRIDE_DOMAINS" \
    -v claude_ips="$CLAUDE_OVERRIDE_IPS_FALLBACK" \
    -v source_date="$source_date" \
    -v source_name="$source_name" '
    BEGIN {
      openai_domain_count = split(openai_domains, openai_domain_list, " ")
      gemini_domain_count = split(gemini_domains, gemini_domain_list, " ")
      claude_domain_count = split(claude_domains, claude_domain_list, " ")
      openai_ip_count = split(openai_ips, openai_ip_list, " ")
      gemini_ip_count = split(gemini_ips, gemini_ip_list, " ")
      claude_ip_count = split(claude_ips, claude_ip_list, " ")
      print "### AI Unlock Ultimate: hosts file"
      if (source_date != "") print "# " source_date
      if (source_name != "") print "# " source_name
      print "# One selected AI route has priority over advertising blocklists."
      print "127.0.0.1 localhost"
      print "::1 localhost ip6-localhost ip6-loopback"
      print ""
      print "# Routed services preserved from the selected source"
      seen_pair["127.0.0.1" SUBSEP "localhost"] = 1
      for (i = 1; i <= openai_domain_count; i++) {
        if (openai_domain_list[i] != "") openai_domain[openai_domain_list[i]] = 1
      }
      for (i = 1; i <= gemini_domain_count; i++) {
        if (gemini_domain_list[i] != "") gemini_domain[gemini_domain_list[i]] = 1
      }
      for (i = 1; i <= claude_domain_count; i++) {
        if (claude_domain_list[i] != "") claude_domain[claude_domain_list[i]] = 1
      }
    }
    $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && $1 != "0.0.0.0" && NF >= 2 {
      domain = $2
      is_openai = openai_domain[domain] || domain ~ /(^|\.)chatgpt\.com$/ || domain ~ /(^|\.)openai\.com$/ || domain ~ /(^|\.)oaistatic\.com$/ || domain ~ /(^|\.)oaiusercontent\.com$/
      is_claude = claude_domain[domain] || domain ~ /(^|\.)anthropic\.com$/ || domain ~ /(^|\.)claude\.ai$/ || domain ~ /(^|\.)claude\.com$/
      if (is_openai) {
        if (!openai_domain[domain]) {
          openai_domain[domain] = 1
          openai_domain_list[++openai_domain_count] = domain
        }
        next
      }
      if (gemini_domain[domain]) {
        next
      }
      if (is_claude) {
        if (!claude_domain[domain]) {
          claude_domain[domain] = 1
          claude_domain_list[++claude_domain_count] = domain
        }
        next
      }
      pair = $1 SUBSEP domain
      if (domain ~ /^[A-Za-z0-9][A-Za-z0-9._-]+$/ && !seen_pair[pair]++) {
        print $1 " " domain
      }
    }
    END {
      print ""
      print "# ChatGPT/OpenAI selected route"
      for (i = 1; i <= openai_domain_count; i++) {
        domain = openai_domain_list[i]
        if (domain == "") continue
        for (j = 1; j <= openai_ip_count; j++) {
          if (openai_ip_list[j] != "") print openai_ip_list[j] " " domain
        }
      }
      print ""
      print "# Gemini/Google AI selected route"
      for (i = 1; i <= gemini_domain_count; i++) {
        domain = gemini_domain_list[i]
        if (domain == "") continue
        for (j = 1; j <= gemini_ip_count; j++) {
          if (gemini_ip_list[j] != "") print gemini_ip_list[j] " " domain
        }
      }
      print ""
      print "# Claude/Anthropic selected route"
      for (i = 1; i <= claude_domain_count; i++) {
        domain = claude_domain_list[i]
        if (domain == "") continue
        for (j = 1; j <= claude_ip_count; j++) {
          if (claude_ip_list[j] != "") print claude_ip_list[j] " " domain
        }
      }
    }
  ' "$override_file" > "$override_tmp" || return 1

  mv -f "$override_tmp" "$override_file"
}

apply_gemini_overrides() {
  apply_ai_overrides "$1"
}

prune_backups() {
  count=0
  for file in $(ls -1t "$BACKUP_DIR"/hosts.*.bak 2>/dev/null); do
    count=$((count + 1))
    if [ "$count" -gt 3 ]; then
      rm -f "$file"
    fi
  done
}

prepare_hosts_permissions() {
  chmod 0644 "$1" 2>/dev/null || return 1
  chown 0:0 "$1" 2>/dev/null || true
  if command -v chcon >/dev/null 2>&1; then
    chcon u:object_r:system_file:s0 "$1" 2>/dev/null || true
  fi
}

install_hosts_file() (
  new_file="$1"
  validate_hosts_file "$new_file" || return 1
  old_hash="$(file_hash "$HOSTS_PATH")"
  new_hash="$(file_hash "$new_file")"

  if [ -n "$old_hash" ] && [ "$old_hash" = "$new_hash" ]; then
    print_and_log "Hosts is already current: $(hosts_date_line "$HOSTS_PATH")"
    return 0
  fi

  [ ! -L "$HOSTS_PATH" ] || return 1
  stage_file="$(mktemp "$MODDIR/system/etc/.hosts.stage.XXXXXX")" || return 1
  rollback_file="$(mktemp "$MODDIR/system/etc/.hosts.rollback.XXXXXX")" || {
    rm -f "$stage_file"
    return 1
  }
  trap 'rm -f "$stage_file" "$rollback_file"' EXIT

  cp -f "$new_file" "$stage_file" || return 1
  cp -f "$HOSTS_PATH" "$rollback_file" || return 1
  prepare_hosts_permissions "$stage_file"
  prepare_hosts_permissions "$rollback_file"
  [ "$(file_hash "$stage_file")" = "$new_hash" ] || return 1
  [ "$(file_hash "$rollback_file")" = "$old_hash" ] || return 1

  backup_file="$BACKUP_DIR/hosts.$(epoch_now).$$.$old_hash.bak"
  cp -f "$rollback_file" "$backup_file" || return 1
  [ "$(file_hash "$backup_file")" = "$old_hash" ] || return 1
  sync 2>/dev/null || true

  # Both stage and destination are in the module directory: rename is atomic.
  mv -f "$stage_file" "$HOSTS_PATH" || return 1
  if ! validate_hosts_file "$HOSTS_PATH" || [ "$(file_hash "$HOSTS_PATH")" != "$new_hash" ]; then
    mv -f "$rollback_file" "$HOSTS_PATH" || {
      print_and_log "FAIL: atomic rollback failed; disable the module before reboot."
      return 1
    }
    print_and_log "FAIL: post-install validation failed; previous hosts restored atomically."
    return 1
  fi

  sync 2>/dev/null || true
  prune_backups
  print_and_log "Hosts prepared atomically: $(hosts_date_line "$HOSTS_PATH")"
  print_and_log "New SHA256: $(file_hash "$HOSTS_PATH")"
  print_and_log "Reboot if Android still exposes an older mounted hosts inode."
  return 0
)

fetch_valid_hosts() {
  fetch_out="$1"
  fetch_tmp="$STATE_DIR/hosts.download.$$"

  for fetch_url in "$PRIMARY_HOSTS_URL" "$FALLBACK_HOSTS_URL"; do
    [ -n "$fetch_url" ] || continue
    print_and_log "Trying source: $fetch_url"

    if ! download_url "$fetch_url" "$fetch_tmp"; then
      print_and_log "Download failed."
      continue
    fi

    if validate_source_hosts_file "$fetch_tmp"; then
      mv -f "$fetch_tmp" "$fetch_out"
      print_and_log "Accepted source: $fetch_url"
      return 0
    fi

    print_and_log "Rejected source: not a valid supported hosts file."
  done

  rm -f "$fetch_tmp"
  return 1
}

fetch_adblock_hosts() {
  adblock_out="$1"
  adblock_tmp="$STATE_DIR/adblock.download.$$"
  adblock_merged="$STATE_DIR/adblock.merged.$$"
  accepted_sources=0
  : > "$adblock_merged"

  for adblock_url in "$ADBLOCK_PRIMARY_URL" "$ADBLOCK_SECONDARY_URL"; do
    print_and_log "Trying adblock source: $adblock_url"
    if download_url "$adblock_url" "$adblock_tmp" && validate_adblock_hosts_file "$adblock_tmp"; then
      cat "$adblock_tmp" >> "$adblock_merged"
      accepted_sources=$((accepted_sources + 1))
      print_and_log "Accepted adblock source: $adblock_url"
    else
      print_and_log "Rejected adblock source: download or validation failed."
    fi
  done
  rm -f "$adblock_tmp"

  if [ "$accepted_sources" -gt 0 ] && validate_adblock_hosts_file "$adblock_merged"; then
    mv -f "$adblock_merged" "$adblock_out"
    return 0
  fi
  rm -f "$adblock_merged"

  if [ -r "$HOSTS_PATH" ]; then
    grep -E '^0\.0\.0\.0[[:space:]]+[A-Za-z0-9._-]+$' "$HOSTS_PATH" > "$adblock_out" 2>/dev/null
    if validate_adblock_hosts_file "$adblock_out"; then
      print_and_log "Using bundled advertising blocklist."
      return 0
    fi
  fi

  rm -f "$adblock_out"
  return 1
}

merge_adblock_hosts() {
  hosts_file="$1"
  adblock_file="$2"
  merged_tmp="$STATE_DIR/hosts.ultimate.$$"

  awk '
    function is_ai_domain(domain) {
      return domain ~ /(^|\.)chatgpt\.com$/ ||
             domain ~ /(^|\.)openai\.com$/ ||
             domain ~ /(^|\.)oaistatic\.com$/ ||
             domain ~ /(^|\.)oaiusercontent\.com$/ ||
             domain ~ /(^|\.)anthropic\.com$/ ||
             domain ~ /(^|\.)claude\.ai$/ ||
             domain ~ /(^|\.)claude\.com$/
    }
    NR == FNR {
      print
      if (($1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ || $1 ~ /^[0-9A-Fa-f:]+$/ && $1 ~ /:/) && NF >= 2) {
        protected[$2] = 1
        seen[$2] = 1
      }
      next
    }
    !header_printed {
      print ""
      print "# Mobile advertising and tracker blocklist"
      header_printed = 1
    }
    ($1 == "0.0.0.0" || $1 == "127.0.0.1") && $2 ~ /^[A-Za-z0-9][A-Za-z0-9._-]+$/ {
      domain = $2
      if (!protected[domain] && !is_ai_domain(domain) && !seen[domain]++) {
        print "0.0.0.0 " domain
      }
    }
  ' "$hosts_file" "$adblock_file" > "$merged_tmp" || return 1

  mv -f "$merged_tmp" "$hosts_file"
}

has_curl() {
  command -v curl >/dev/null 2>&1
}

extract_domain_ips() {
  route_file="$1"
  route_domain="$2"
  awk -v domain="$route_domain" '
    $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && $1 != "0.0.0.0" && $2 == domain && !seen[$1]++ { print $1 }
  ' "$route_file" 2>/dev/null | tr '\n' ' '
}

limit_word_list() {
  limit_words="$1"
  shift
  limit_result=""
  limit_count=0

  for limit_group in "$@"; do
    for limit_word in $limit_group; do
      case " $limit_result " in
        *" $limit_word "*) continue ;;
      esac
      limit_result="${limit_result:+$limit_result }$limit_word"
      limit_count=$((limit_count + 1))
      [ "$limit_count" -ge "$limit_words" ] && break 2
    done
  done

  echo "$limit_result"
}

backend_probe() {
  backend_host="$1"
  backend_path="$2"
  backend_ip="$3"
  backend_mode="${4:-reachable}"

  has_curl || return 2
  backend_result="$(curl -L --noproxy '*' --proto '=https' --proto-redir '=https' -sS -o /dev/null -w '%{http_code} %{time_total}' --connect-timeout 6 --max-time 12 --resolve "$backend_host:443:$backend_ip" "https://$backend_host$backend_path" 2>/dev/null)"
  backend_code="$(echo "$backend_result" | awk '{print $1}')"
  BACKEND_TIME="$(echo "$backend_result" | awk '{print $2}')"
  [ -n "$BACKEND_TIME" ] || BACKEND_TIME=0
  if [ "$backend_mode" = "strict" ]; then
    case "$backend_code" in
      2*|3*) return 0 ;;
      *) return 1 ;;
    esac
  fi

  case "$backend_code" in
    2*|3*|400|401|403|404|405) return 0 ;;
    *) return 1 ;;
  esac
}

backend_profile_probe() {
  route_profile="$1"
  route_ip="$2"
  BACKEND_PROFILE_TIME=0

  case "$route_profile" in
    Gemini)
      # An unauthenticated Gemini page may answer 401/403/404; transport success is the useful signal here.
      backend_probe "gemini.google.com" "/app" "$route_ip" reachable || return 1
      BACKEND_PROFILE_TIME="$(awk -v a="$BACKEND_PROFILE_TIME" -v b="$BACKEND_TIME" 'BEGIN {print a+b}')"
      backend_probe "generativelanguage.googleapis.com" "/v1beta/models" "$route_ip" reachable || return 1
      BACKEND_PROFILE_TIME="$(awk -v a="$BACKEND_PROFILE_TIME" -v b="$BACKEND_TIME" 'BEGIN {print a+b}')"
      backend_probe "alkalimakersuite-pa.clients6.google.com" "/" "$route_ip" reachable || return 1
      BACKEND_PROFILE_TIME="$(awk -v a="$BACKEND_PROFILE_TIME" -v b="$BACKEND_TIME" 'BEGIN {print a+b}')"
      backend_probe "waa-pa.clients6.google.com" "/" "$route_ip" reachable || return 1
      BACKEND_PROFILE_TIME="$(awk -v a="$BACKEND_PROFILE_TIME" -v b="$BACKEND_TIME" 'BEGIN {print a+b}')"
      ;;
    ChatGPT)
      backend_probe "webrtc.chatgpt.com" "/" "$route_ip" reachable || return 1
      BACKEND_PROFILE_TIME="$(awk -v a="$BACKEND_PROFILE_TIME" -v b="$BACKEND_TIME" 'BEGIN {print a+b}')"
      backend_probe "realtime.chatgpt.com" "/" "$route_ip" reachable || return 1
      BACKEND_PROFILE_TIME="$(awk -v a="$BACKEND_PROFILE_TIME" -v b="$BACKEND_TIME" 'BEGIN {print a+b}')"
      ;;
    Claude)
      backend_probe "api.anthropic.com" "/" "$route_ip" reachable || return 1
      BACKEND_PROFILE_TIME="$BACKEND_TIME"
      ;;
    *) return 1 ;;
  esac
}

select_backend_routes() {
  route_label="$1"
  route_installed_domain="$2"
  route_candidates="$3"
  route_fallback="$4"
  installed_ips="$(extract_domain_ips "$HOSTS_PATH" "$route_installed_domain")"
  candidate_ips="$(merge_word_lists "$route_candidates" "$installed_ips" "$route_fallback")"
  unverified_ips="$(limit_word_list "$ROUTE_POOL_LIMIT" "$installed_ips" "$route_candidates" "$route_fallback")"

  if ! has_curl; then
    SELECTED_BACKEND_IPS="$unverified_ips"
    SELECTED_BACKEND_IP="${SELECTED_BACKEND_IPS%% *}"
    print_and_log "$route_label route check skipped: curl is unavailable; keeping route pool $SELECTED_BACKEND_IPS."
    return 0
  fi

  healthy_ips=""
  healthy_time=""
  checked_count=0
  for candidate_ip in $candidate_ips; do
    checked_count=$((checked_count + 1))
    [ "$checked_count" -gt "$ROUTE_PROBE_LIMIT" ] && break

    if backend_profile_probe "$route_label" "$candidate_ip"; then
      [ -n "$BACKEND_PROFILE_TIME" ] || BACKEND_PROFILE_TIME=0
      if [ -z "$healthy_ips" ] || awk -v a="$BACKEND_PROFILE_TIME" -v b="$healthy_time" 'BEGIN { exit !(a<b) }'; then
        healthy_ips="$candidate_ip"
        healthy_time="$BACKEND_PROFILE_TIME"
      fi
    fi
  done

  if [ -n "$healthy_ips" ]; then
    SELECTED_BACKEND_IPS="$healthy_ips"
    SELECTED_BACKEND_IP="${SELECTED_BACKEND_IPS%% *}"
    print_and_log "Selected fastest responsive $route_label route: $SELECTED_BACKEND_IPS (${healthy_time}s HTTPS preflight)."
    return 0
  fi

  SELECTED_BACKEND_IPS="$unverified_ips"
  SELECTED_BACKEND_IP="${SELECTED_BACKEND_IPS%% *}"
  print_and_log "WARN: no $route_label route passed the full preflight; keeping route pool $SELECTED_BACKEND_IPS."
  return 0
}

configure_route_candidates_from_source() {
  route_source="$1"
  source_openai_ips="$(extract_domain_ips "$route_source" "webrtc.chatgpt.com")"
  [ -n "$source_openai_ips" ] || source_openai_ips="$(extract_domain_ips "$route_source" "chatgpt.com")"
  source_gemini_ips="$(extract_domain_ips "$route_source" "gemini.google.com")"
  source_claude_ips="$(extract_domain_ips "$route_source" "api.anthropic.com")"
  [ -n "$source_claude_ips" ] || source_claude_ips="$(extract_domain_ips "$route_source" "claude.ai")"

  OPENAI_BACKEND_CANDIDATES="$(merge_word_lists "$source_openai_ips" "$OPENAI_BACKEND_CANDIDATES")"
  GEMINI_BACKEND_CANDIDATES="$(merge_word_lists "$source_gemini_ips" "$GEMINI_BACKEND_CANDIDATES")"
  CLAUDE_BACKEND_CANDIDATES="$(merge_word_lists "$source_claude_ips" "$CLAUDE_BACKEND_CANDIDATES")"
}

select_ai_backends() {
  select_backend_routes "ChatGPT" "webrtc.chatgpt.com" "$OPENAI_BACKEND_CANDIDATES" "$OPENAI_OVERRIDE_IPS_FALLBACK"
  OPENAI_OVERRIDE_IPS_FALLBACK="$SELECTED_BACKEND_IPS"
  OPENAI_OVERRIDE_IPS="$SELECTED_BACKEND_IPS"

  select_backend_routes "Gemini" "gemini.google.com" "$GEMINI_BACKEND_CANDIDATES" "$GEMINI_OVERRIDE_IPS_FALLBACK"
  GEMINI_OVERRIDE_IPS_FALLBACK="$SELECTED_BACKEND_IPS"
  GEMINI_OVERRIDE_IPS="$SELECTED_BACKEND_IPS"

  select_backend_routes "Claude" "api.anthropic.com" "$CLAUDE_BACKEND_CANDIDATES" "$CLAUDE_OVERRIDE_IPS_FALLBACK"
  CLAUDE_OVERRIDE_IPS_FALLBACK="$SELECTED_BACKEND_IPS"
  CLAUDE_OVERRIDE_IPS="$SELECTED_BACKEND_IPS"
}

select_gemini_backend() {
  select_backend_routes "Gemini" "gemini.google.com" "$GEMINI_BACKEND_CANDIDATES" "$GEMINI_OVERRIDE_IPS_FALLBACK"
  GEMINI_OVERRIDE_IPS_FALLBACK="$SELECTED_BACKEND_IPS"
  GEMINI_OVERRIDE_IPS="$SELECTED_BACKEND_IPS"
}

rewrite_installed_ai_routes() {
  rewrite_tmp="$STATE_DIR/hosts.routes.$$"
  awk \
    -v openai_ips="$OPENAI_OVERRIDE_IPS_FALLBACK" \
    -v gemini_ips="$GEMINI_OVERRIDE_IPS_FALLBACK" \
    -v claude_ips="$CLAUDE_OVERRIDE_IPS_FALLBACK" \
    -v openai_domains="$OPENAI_OVERRIDE_DOMAINS" \
    -v gemini_domains="$GEMINI_OVERRIDE_DOMAINS" \
    -v claude_domains="$CLAUDE_OVERRIDE_DOMAINS" '
    BEGIN {
      openai_domain_count = split(openai_domains, openai_domain_list, " ")
      gemini_domain_count = split(gemini_domains, gemini_domain_list, " ")
      claude_domain_count = split(claude_domains, claude_domain_list, " ")
      openai_ip_count = split(openai_ips, openai_ip_list, " ")
      gemini_ip_count = split(gemini_ips, gemini_ip_list, " ")
      claude_ip_count = split(claude_ips, claude_ip_list, " ")
      for (i = 1; i <= openai_domain_count; i++) if (openai_domain_list[i] != "") openai[openai_domain_list[i]] = 1
      for (i = 1; i <= gemini_domain_count; i++) if (gemini_domain_list[i] != "") gemini[gemini_domain_list[i]] = 1
      for (i = 1; i <= claude_domain_count; i++) if (claude_domain_list[i] != "") claude[claude_domain_list[i]] = 1
    }
    function is_openai(domain) {
      return openai[domain] || domain ~ /(^|\.)chatgpt\.com$/ || domain ~ /(^|\.)openai\.com$/ || domain ~ /(^|\.)oaistatic\.com$/ || domain ~ /(^|\.)oaiusercontent\.com$/
    }
    function is_claude(domain) {
      return claude[domain] || domain ~ /(^|\.)anthropic\.com$/ || domain ~ /(^|\.)claude\.ai$/ || domain ~ /(^|\.)claude\.com$/
    }
    NF >= 2 && is_openai($2) {
      if (!openai[$2]) {
        openai[$2] = 1
        openai_domain_list[++openai_domain_count] = $2
      }
      next
    }
    NF >= 2 && gemini[$2] { next }
    NF >= 2 && is_claude($2) {
      if (!claude[$2]) {
        claude[$2] = 1
        claude_domain_list[++claude_domain_count] = $2
      }
      next
    }
    { print }
    END {
      print ""
      print "# ChatGPT/OpenAI selected route"
      for (i = 1; i <= openai_domain_count; i++) for (j = 1; j <= openai_ip_count; j++) if (openai_domain_list[i] != "" && openai_ip_list[j] != "") print openai_ip_list[j] " " openai_domain_list[i]
      print ""
      print "# Gemini/Google AI selected route"
      for (i = 1; i <= gemini_domain_count; i++) for (j = 1; j <= gemini_ip_count; j++) if (gemini_domain_list[i] != "" && gemini_ip_list[j] != "") print gemini_ip_list[j] " " gemini_domain_list[i]
      print ""
      print "# Claude/Anthropic selected route"
      for (i = 1; i <= claude_domain_count; i++) for (j = 1; j <= claude_ip_count; j++) if (claude_domain_list[i] != "" && claude_ip_list[j] != "") print claude_ip_list[j] " " claude_domain_list[i]
    }
  ' "$HOSTS_PATH" > "$rewrite_tmp" || return 1

  if ! validate_hosts_file "$rewrite_tmp"; then
    rm -f "$rewrite_tmp"
    return 1
  fi

  if ! install_hosts_file "$rewrite_tmp"; then
    rm -f "$rewrite_tmp"
    return 1
  fi
  rm -f "$rewrite_tmp"
  return 0
}

run_update() {
  mode="$1"
  ensure_state_dirs
  if ! acquire_update_lock; then
    return 1
  fi
  print_and_log "$MODULE_NAME hosts update started ($mode)."

  new_hosts="$STATE_DIR/hosts.valid.$$"
  if ! fetch_valid_hosts "$new_hosts"; then
    rm -f "$new_hosts"
    select_ai_backends
    if validate_hosts_file "$HOSTS_PATH" && rewrite_installed_ai_routes && validate_hosts_file "$HOSTS_PATH"; then
      print_and_log "Sources unavailable; kept advertising rules and repaired AI routes."
      release_update_lock
      return 0
    fi
    print_and_log "Update failed: no valid hosts source and no repairable installed hosts."
    release_update_lock
    return 1
  fi

  configure_route_candidates_from_source "$new_hosts"
  refresh_gemini_override_domains
  select_ai_backends

  if ! apply_ai_overrides "$new_hosts"; then
    rm -f "$new_hosts"
    print_and_log "Update failed: cannot apply AI overrides."
    release_update_lock
    return 1
  fi

  adblock_hosts="$STATE_DIR/adblock.valid.$$"
  if ! fetch_adblock_hosts "$adblock_hosts"; then
    rm -f "$new_hosts" "$adblock_hosts"
    print_and_log "Update failed: no valid advertising blocklist available."
    release_update_lock
    return 1
  fi

  if ! merge_adblock_hosts "$new_hosts" "$adblock_hosts"; then
    rm -f "$new_hosts" "$adblock_hosts"
    print_and_log "Update failed: cannot merge advertising blocklist."
    release_update_lock
    return 1
  fi
  rm -f "$adblock_hosts"

  if install_hosts_file "$new_hosts"; then
    rm -f "$new_hosts"
    release_update_lock
    return 0
  fi

  rm -f "$new_hosts"
  print_and_log "Update failed: cannot write $HOSTS_PATH."
  release_update_lock
  return 1
}

ip_connectivity_healthy() {
  command -v ping >/dev/null 2>&1 || return 1

  for connectivity_ip in 1.1.1.1 8.8.8.8; do
    if ping -c 1 -W 3 "$connectivity_ip" >/dev/null 2>&1; then
      return 0
    fi
  done

  return 1
}

dns_resolution_probe() {
  has_curl || return 2

  dns_probe_checked=0
  dns_probe_resolver_failures=0
  dns_probe_unknown_failures=0

  for dns_probe_spec in \
    "connectivitycheck.gstatic.com|https://connectivitycheck.gstatic.com/generate_204" \
    "www.iana.org|https://www.iana.org/"; do
    dns_probe_host="${dns_probe_spec%%|*}"
    dns_probe_url="${dns_probe_spec#*|}"

    if grep -Eq '^[^#[:space:]]+[[:space:]]+'"$dns_probe_host"'([[:space:]]|$)' "$HOSTS_PATH" /system/etc/hosts 2>/dev/null; then
      continue
    fi

    dns_probe_checked=$((dns_probe_checked + 1))
    dns_probe_output="$(curl -4 -L -sS -o /dev/null -w '%{http_code}' --connect-timeout 4 --max-time 8 \
      "$dns_probe_url" 2>&1)"
    dns_probe_status=$?

    if [ "$dns_probe_status" -eq 0 ]; then
      dns_probe_code="$(printf '%s\n' "$dns_probe_output" | tail -n 1)"
      case "$dns_probe_code" in
        2*|3*|4*) return 0 ;;
      esac
    fi

    if printf '%s\n' "$dns_probe_output" | grep -qiE 'could not resolve|resolving timed out|resolve host|name resolution'; then
      dns_probe_resolver_failures=$((dns_probe_resolver_failures + 1))
    else
      dns_probe_unknown_failures=$((dns_probe_unknown_failures + 1))
    fi
  done

  [ "$dns_probe_checked" -gt 0 ] || return 2
  [ "$dns_probe_unknown_failures" -eq 0 ] || return 2
  [ "$dns_probe_resolver_failures" -eq "$dns_probe_checked" ] || return 2
  return 1
}

check_dns_health() {
  if dns_resolution_probe; then
    echo "OK: system DNS resolution is healthy."
    return 0
  else
    dns_check_result=$?
  fi

  if [ "$dns_check_result" -eq 1 ] && ip_connectivity_healthy; then
    echo "WARN: system DNS is failing while direct IP connectivity works. No settings were changed."
    return 1
  fi

  if [ "$dns_check_result" -eq 2 ]; then
    echo "WARN: system DNS state is inconclusive. No settings were changed."
    return 1
  fi

  echo "WARN: network connectivity is unavailable."
  return 1
}

check_hosts_entries() {
  file="$1"
  label="$2"
  missing=0

  if [ ! -r "$file" ]; then
    echo "FAIL: $label is not readable: $file"
    return 1
  fi

  expected_openai_ip="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+webrtc\.chatgpt\.com$' "$file" 2>/dev/null | head -n 1 | awk '{print $1}')"
  expected_gemini_ip="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+gemini\.google\.com$' "$file" 2>/dev/null | head -n 1 | awk '{print $1}')"
  expected_claude_ip="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+api\.anthropic\.com$' "$file" 2>/dev/null | head -n 1 | awk '{print $1}')"
  [ -n "$expected_openai_ip" ] || expected_openai_ip="${OPENAI_OVERRIDE_IPS_FALLBACK%% *}"
  [ -n "$expected_gemini_ip" ] || expected_gemini_ip="${GEMINI_OVERRIDE_IPS_FALLBACK%% *}"
  [ -n "$expected_claude_ip" ] || expected_claude_ip="${CLAUDE_OVERRIDE_IPS_FALLBACK%% *}"

  for check_pair in \
    "webrtc.chatgpt.com:$expected_openai_ip" \
    "realtime.chatgpt.com:$expected_openai_ip" \
    "android.chat.openai.com:$expected_openai_ip" \
    "chatgpt.com:$expected_openai_ip" \
    "gemini.google.com:$expected_gemini_ip" \
    "generativelanguage.googleapis.com:$expected_gemini_ip" \
    "aistudio.google.com:$expected_gemini_ip" \
    "claude.ai:$expected_claude_ip" \
    "api.anthropic.com:$expected_claude_ip"; do
    domain="${check_pair%%:*}"
    expected_ip="${check_pair##*:}"
    first_line="$(grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+$domain$" "$file" 2>/dev/null | head -n 1)"
    case "$first_line" in
      "$expected_ip "*)
        echo "OK: $label prefers $expected_ip for $domain"
        ;;
      "")
        echo "WARN: $label misses $domain"
        missing=$((missing + 1))
        ;;
      *)
        echo "WARN: $label has $domain, but first IP is not $expected_ip"
        missing=$((missing + 1))
        ;;
    esac
  done

  [ "$missing" -eq 0 ]
}

check_hosts_conflicts() {
  conflict_count=0

  for modules_root in $MODULES_ROOTS; do
    [ -d "$modules_root" ] || continue
    for module_dir in "$modules_root"/*; do
      [ -d "$module_dir" ] || continue
      [ "$module_dir" = "$MODDIR" ] && continue
      [ -e "$module_dir/disable" ] && continue
      [ -e "$module_dir/remove" ] && continue
      [ -f "$module_dir/system/etc/hosts" ] || continue

      module_id="$(basename "$module_dir")"
      echo "WARN: another enabled hosts module found: $module_id"
      conflict_count=$((conflict_count + 1))
    done
  done

  if [ "$conflict_count" -eq 0 ]; then
    echo "OK: no other enabled Magisk hosts modules found."
    return 0
  fi

  echo "FAIL: disable other hosts modules and reboot; only one module can own /system/etc/hosts."
  return 1
}

check_active_hosts_match() {
  module_hash="$(file_hash "$HOSTS_PATH")"
  active_hash="$(file_hash /system/etc/hosts)"

  if [ -n "$module_hash" ] && [ "$module_hash" = "$active_hash" ]; then
    echo "OK: active /system/etc/hosts is the file mounted by $MODULE_NAME."
    return 0
  fi

  echo "FAIL: active /system/etc/hosts does not match the module file."
  echo "INFO: reboot first; if this remains, disable the conflicting hosts module."
  return 1
}

check_adblock_entries() {
  adblock_check_file="$1"
  adblock_check_label="$2"
  adblock_check_count="$(grep -Ec '^0\.0\.0\.0[[:space:]]+' "$adblock_check_file" 2>/dev/null)"

  if [ "${adblock_check_count:-0}" -ge "$MIN_ADBLOCK_ENTRIES" ] && [ "${adblock_check_count:-0}" -le "$MAX_ADBLOCK_ENTRIES" ]; then
    echo "OK: $adblock_check_label contains $adblock_check_count blocked advertising/tracker domains."
    return 0
  fi

  echo "FAIL: $adblock_check_label contains only ${adblock_check_count:-0} blocking entries."
  return 1
}

check_route_redundancy() {
  redundancy_check_file="$1"
  redundancy_check_label="$2"
  redundancy_failures=0

  for redundancy_domain in webrtc.chatgpt.com gemini.google.com api.anthropic.com; do
    redundancy_ips="$(extract_domain_ips "$redundancy_check_file" "$redundancy_domain")"
    redundancy_count="$(echo "$redundancy_ips" | awk '{print NF}')"
    if [ "${redundancy_count:-0}" -eq 1 ]; then
      echo "OK: $redundancy_check_label has one selected route for $redundancy_domain"
    elif [ "${redundancy_count:-0}" -gt 1 ]; then
      echo "WARN: $redundancy_check_label has $redundancy_count routes for $redundancy_domain; only the first is deterministic on Android"
    else
      echo "WARN: $redundancy_check_label has no selected route for $redundancy_domain"
      redundancy_failures=$((redundancy_failures + 1))
    fi
  done

  [ "$redundancy_failures" -eq 0 ]
}

probe_resolved_url() {
  probe_host="$1"
  probe_path="$2"
  probe_ip="$3"
  probe_mode="${4:-reachable}"

  if ! command -v curl >/dev/null 2>&1; then
    echo "SKIP: no curl for resolved probe $probe_host via $probe_ip."
    return 0
  fi

  probe_result="$(curl -L -sS -o /dev/null -w '%{http_code} %{time_total}' --connect-timeout 8 --max-time 18 --resolve "$probe_host:443:$probe_ip" "https://$probe_host$probe_path" 2>/dev/null)"
  probe_status=$?
  probe_code="$(echo "$probe_result" | awk '{print $1}')"
  probe_time="$(echo "$probe_result" | awk '{print $2}')"

  if [ "$probe_status" -eq 0 ]; then
    if [ "$probe_mode" = "strict" ]; then
      case "$probe_code" in
        2*|3*)
          echo "OK: $probe_host via $probe_ip -> HTTP $probe_code in ${probe_time}s"
          return 0
          ;;
      esac
    else
      case "$probe_code" in
        2*|3*|400|401|403|404|405)
          echo "OK: $probe_host via $probe_ip -> HTTP $probe_code in ${probe_time}s"
          return 0
          ;;
      esac
    fi
  fi

  echo "WARN: $probe_host via $probe_ip -> HTTP ${probe_code:-000} in ${probe_time:-timeout}s"
  return 1
}

probe_priority_backends() {
  probe_label="$1"
  probe_host="$2"
  probe_path="$3"
  probe_ips="$4"
  backend_ok=0
  backend_count=0

  echo "$probe_label"
  for backend_ip in $probe_ips; do
    backend_count=$((backend_count + 1))
    [ "$backend_count" -gt "$PROBE_IP_LIMIT" ] && break

    if probe_resolved_url "$probe_host" "$probe_path" "$backend_ip"; then
      backend_ok=$((backend_ok + 1))
    else
      :
    fi
  done

  [ "$backend_ok" -gt 0 ]
}

check_chatgpt_voice_ranges() {
  voice_tmp="$STATE_DIR/chatgpt-voice.$$"

  echo "ChatGPT Voice official range check"

  if ! download_url "$CHATGPT_VOICE_JSON_URL" "$voice_tmp"; then
    rm -f "$voice_tmp"
    echo "WARN: OpenAI Voice IP range list is not reachable."
    echo "INFO: Voice quality also depends on UDP 3478; hosts cannot force UDP routing."
    return 1
  fi

  if ! validate_voice_json_file "$voice_tmp"; then
    rm -f "$voice_tmp"
    echo "WARN: OpenAI Voice IP range list did not pass validation."
    echo "INFO: Voice quality also depends on UDP 3478; hosts cannot force UDP routing."
    return 1
  fi

  voice_creation="$(sed -n 's/.*"creationTime"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$voice_tmp" | head -n 1)"
  voice_count="$(grep -o '"ipv4Prefix"' "$voice_tmp" | wc -l | awk '{print $1}')"
  rm -f "$voice_tmp"

  echo "OK: OpenAI Voice IP ranges fetched: ${voice_count:-0} ranges, created ${voice_creation:-unknown}"
  echo "INFO: Voice quality also depends on UDP 3478; hosts cannot force UDP routing."
  return 0
}

check_http2_capability() {
  if ! command -v curl >/dev/null 2>&1 || ! curl --version 2>/dev/null | grep -q 'Features:.*HTTP2'; then
    echo "INFO: this device curl has no HTTP/2 support; Gemini streaming/gRPC was not verified by this action."
    return 2
  fi

  http2_result="$(curl --http2 -L --noproxy '*' --proto '=https' -sS -o /dev/null -w '%{http_code} %{http_version}' \
    --connect-timeout 6 --max-time 15 https://generativelanguage.googleapis.com/v1beta/models 2>/dev/null)"
  http2_code="$(echo "$http2_result" | awk '{print $1}')"
  http2_version="$(echo "$http2_result" | awk '{print $2}')"
  case "$http2_code:$http2_version" in
    2*:*2|3*:*2|4*:*2)
      echo "OK: Gemini API negotiated HTTP/2 ($http2_code); authenticated streaming remains untested."
      return 0
      ;;
  esac
  echo "WARN: Gemini API did not negotiate HTTP/2 in the unauthenticated probe."
  return 1
}

probe_gemini_backends() {
  echo "Gemini multi-endpoint backend probes"
  gemini_ok=0
  gemini_count=0
  for gemini_ip in $GEMINI_OVERRIDE_IPS; do
    gemini_count=$((gemini_count + 1))
    [ "$gemini_count" -gt "$PROBE_IP_LIMIT" ] && break
    if probe_resolved_url "gemini.google.com" "/app" "$gemini_ip" strict &&
      probe_resolved_url "generativelanguage.googleapis.com" "/v1beta/models" "$gemini_ip" reachable &&
      probe_resolved_url "alkalimakersuite-pa.clients6.google.com" "/" "$gemini_ip" reachable &&
      probe_resolved_url "waa-pa.clients6.google.com" "/" "$gemini_ip" reachable; then
      gemini_ok=$((gemini_ok + 1))
    fi
  done
  [ "$gemini_ok" -gt 0 ]
}

probe_url() {
  url="$1"

  if command -v curl >/dev/null 2>&1; then
    code="$(curl -L -sS -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 25 "$url" 2>/dev/null)"
    case "$code" in
      2*|3*|4*) echo "OK: HTTPS probe $url -> HTTP $code"; return 0 ;;
      *) echo "WARN: HTTPS probe $url -> HTTP ${code:-000}"; return 1 ;;
    esac
  fi

  if command -v wget >/dev/null 2>&1; then
    if run_with_timeout 25 wget -q -O /dev/null "$url" >/dev/null 2>&1; then
      echo "OK: HTTPS probe $url"
      return 0
    fi
    echo "WARN: HTTPS probe failed: $url"
    return 1
  fi

  if command -v busybox >/dev/null 2>&1; then
    if run_with_timeout 25 busybox wget -q -O /dev/null "$url" >/dev/null 2>&1; then
      echo "OK: HTTPS probe $url"
      return 0
    fi
    echo "WARN: HTTPS probe failed: $url"
    return 1
  fi

  if [ -x /data/adb/magisk/busybox ]; then
    if run_with_timeout 25 /data/adb/magisk/busybox wget -q -O /dev/null "$url" >/dev/null 2>&1; then
      echo "OK: HTTPS probe $url"
      return 0
    fi
    echo "WARN: HTTPS probe failed: $url"
    return 1
  fi

  echo "SKIP: no curl/wget for HTTPS probe."
  return 0
}

run_health_check() {
  ensure_state_dirs
  installed_openai_ips="$(extract_domain_ips "$HOSTS_PATH" "webrtc.chatgpt.com")"
  installed_gemini_ips="$(extract_domain_ips "$HOSTS_PATH" "gemini.google.com")"
  installed_claude_ips="$(extract_domain_ips "$HOSTS_PATH" "api.anthropic.com")"
  [ -n "$installed_openai_ips" ] && OPENAI_OVERRIDE_IPS="$installed_openai_ips"
  [ -n "$installed_gemini_ips" ] && GEMINI_OVERRIDE_IPS="$installed_gemini_ips"
  [ -n "$installed_claude_ips" ] && CLAUDE_OVERRIDE_IPS="$installed_claude_ips"
  echo "$MODULE_NAME health check"
  echo "Module hosts: $HOSTS_PATH"
  echo "Module date: $(hosts_date_line "$HOSTS_PATH")"
  echo

  check_dns_health
  dns_result=$?
  echo

  check_hosts_entries "$HOSTS_PATH" "module hosts"
  module_result=$?
  check_route_redundancy "$HOSTS_PATH" "module hosts"
  redundancy_result=$?
  check_adblock_entries "$HOSTS_PATH" "module hosts"
  adblock_result=$?

  echo
  check_hosts_conflicts
  conflict_result=$?

  echo
  check_hosts_entries "/system/etc/hosts" "active /system/etc/hosts"
  active_result=$?

  check_active_hosts_match
  active_match_result=$?

  if [ "$active_result" -ne 0 ]; then
    echo "WARN: active hosts may not be mounted yet. Reboot after updating the module."
  fi

  echo
  probe_url "https://gemini.google.com/app"
  gemini_result=$?
  probe_url "https://generativelanguage.googleapis.com/"
  api_result=$?

  echo
  probe_priority_backends "ChatGPT voice backend probes" "webrtc.chatgpt.com" "/" "$OPENAI_OVERRIDE_IPS"
  chatgpt_voice_result=$?
  probe_priority_backends "ChatGPT realtime backend probes" "realtime.chatgpt.com" "/" "$OPENAI_OVERRIDE_IPS"
  chatgpt_realtime_result=$?
  probe_gemini_backends
  gemini_backend_result=$?
  check_http2_capability
  http2_result=$?
  probe_priority_backends "Claude backend probes" "api.anthropic.com" "/" "$CLAUDE_OVERRIDE_IPS"
  claude_backend_result=$?
  check_chatgpt_voice_ranges
  voice_result=$?

  if [ "$dns_result" -eq 0 ] && [ "$module_result" -eq 0 ] && [ "$redundancy_result" -eq 0 ] && [ "$adblock_result" -eq 0 ] && [ "$conflict_result" -eq 0 ] && [ "$active_result" -eq 0 ] && [ "$active_match_result" -eq 0 ] && [ "$gemini_result" -eq 0 ] && [ "$api_result" -eq 0 ] && [ "$chatgpt_voice_result" -eq 0 ] && [ "$chatgpt_realtime_result" -eq 0 ] && [ "$gemini_backend_result" -eq 0 ] && [ "$claude_backend_result" -eq 0 ] && [ "$voice_result" -eq 0 ]; then
    print_and_log "Health check passed."
    return 0
  fi

  print_and_log "Health check finished with warnings."
  return 1
}
