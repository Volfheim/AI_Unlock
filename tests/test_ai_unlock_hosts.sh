#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/scripts" "$WORK/system/etc"
cp "$ROOT/scripts/ai_unlock_hosts.sh" "$WORK/scripts/ai_unlock_hosts.sh"
cp "$ROOT/system/etc/hosts" "$WORK/system/etc/hosts"
printf 'version=0-test\n' > "$WORK/module.prop"

export MODDIR="$WORK"
export MIN_ADBLOCK_ENTRIES=100
. "$WORK/scripts/ai_unlock_hosts.sh"

FAKE_HTML="$WORK/fake.html"
FAKE_HOSTS="$WORK/fake.hosts"
printf '<!DOCTYPE html><html></html>\n' > "$FAKE_HTML"
cp "$ROOT/system/etc/hosts" "$FAKE_HOSTS"

download_url() {
  if [ "${FORCE_DOWNLOAD_FAIL:-0}" = "1" ]; then
    return 1
  fi
  case "$1" in
    *chatgpt-voice.json*)
      printf '{"creationTime":"2026-03-26T20:12:45.451356+00:00","prefixes":[{"ipv4Prefix":"102.37.57.54/32"},{"ipv4Prefix":"13.71.25.29/32"}]}\n' > "$2"
      ;;
    *malw-fail*)
      return 1
      ;;
    *avencores*)
      {
        printf '### dns.malw.link: hosts file\n'
        printf '# Последнее обновление: fallback test\n'
        printf '193.233.112.68 chatgpt.com\n'
        printf '62.133.62.97 gemini.google.com\n'
        printf '37.230.192.51 claude.ai\n'
        printf '37.230.192.51 fresh-fallback.claude.ai\n'
        for i in $(seq 1 1000); do
          printf '0.0.0.0 fallback-filler-%s.invalid\n' "$i"
        done
      } > "$2"
      ;;
    *geohide-fresh*)
      {
        printf '### geohide.ru: hosts file\n'
        printf '# Последнее обновление: multi-route test\n'
        printf '# Регион серверов: RU\n'
        for ip in 46.8.158.6 193.233.112.67 193.233.112.68; do
          printf '%s chatgpt.com\n' "$ip"
          printf '%s webrtc.chatgpt.com\n' "$ip"
          printf '%s realtime.chatgpt.com\n' "$ip"
          printf '%s gemini.google.com\n' "$ip"
          printf '%s generativelanguage.googleapis.com\n' "$ip"
          printf '%s alkalimakersuite-pa.clients6.google.com\n' "$ip"
          printf '%s waa-pa.clients6.google.com\n' "$ip"
          printf '%s claude.ai\n' "$ip"
          printf '%s api.anthropic.com\n' "$ip"
          printf '%s spotify.com\n' "$ip"
        done
        for i in $(seq 1 1000); do
          printf '203.0.113.10 routed-service-%s.invalid\n' "$i"
        done
      } > "$2"
      ;;
    *dns.malw.link*)
      {
        printf '### dns.malw.link: hosts file\n'
        printf '# Последнее обновление: test\n'
        printf '193.233.112.68 chatgpt.com\n'
        printf '193.233.112.68 webrtc.chatgpt.com\n'
        printf '193.233.112.68 android.chat.openai.com\n'
        printf '193.233.112.68 files.oaiusercontent.com\n'
        printf '62.133.62.97 gemini.google.com\n'
        printf '62.133.62.97 aistudio.google.com\n'
        printf '193.233.112.68 claude.ai\n'
        printf '193.233.112.68 api.anthropic.com\n'
        printf '193.233.112.68 a.claude.ai\n'
        printf '203.0.113.10 unrelated.example\n'
        for i in $(seq 1 1000); do
          printf '0.0.0.0 filler-%s.invalid\n' "$i"
        done
      } > "$2"
      ;;
    *pantsufan*|*StevenBlack*)
      {
        printf '# advertising test list\n'
        printf '0.0.0.0 ads.example\n'
        printf '0.0.0.0 tracker.example\n'
        printf '0.0.0.0 chatgpt.com\n'
        printf '0.0.0.0 bzr.openai.com\n'
        printf '0.0.0.0 gemini.google.com\n'
        printf '0.0.0.0 api.anthropic.com\n'
        for i in $(seq 1 120); do
          printf '0.0.0.0 ad-filler-%s.invalid\n' "$i"
        done
      } > "$2"
      ;;
    *domains-google*)
      {
        printf 'gemini.google.com\n'
        printf 'generativelanguage.googleapis.com\n'
        printf 'aistudio.google.com\n'
        printf 'bard.google.com\n'
        printf 'notebook.google.com\n'
        printf 'robinfrontend-pa.googleapis.com\n'
        printf 'alkalimakersuite-pa.clients6.google.com\n'
        printf 'webchannel-alkalimakersuite-pa.clients6.google.com\n'
        printf 'waa-pa.clients6.google.com\n'
        printf 'assistant-s3-pa.googleapis.com\n'
        printf 'geller-pa.googleapis.com\n'
        printf 'ai.google.dev\n'
        printf 'deepmind.google\n'
        printf 'opal.google.com\n'
        printf 'people-pa.clients6.google.com\n'
        printf 'stitch.withgoogle.com\n'
        printf 'labs.google.com\n'
        printf 'jules.google.com\n'
        printf 'notebook-pa.googleapis.com\n'
        printf 'o.pki.goog\n'
      } > "$2"
      ;;
    *primary*) cp "$FAKE_HTML" "$2" ;;
    *) cp "$FAKE_HOSTS" "$2" ;;
  esac
}

PRIMARY_HOSTS_URL="https://primary.invalid/"
FALLBACK_HOSTS_URL="https://dns.malw.link/hosts"
SECONDARY_HOSTS_URL="https://secondary.invalid/hosts"
GOOGLE_DOMAINS_URL="https://google.invalid/domains-google.txt"
MALW_HOSTS_URL="https://dns.malw.link/hosts"
AVENCORES_HOSTS_URL="https://avencores.invalid/hosts"
CHATGPT_VOICE_JSON_URL="https://openai.invalid/chatgpt-voice.json"
ADBLOCK_PRIMARY_URL="https://pantsufan.invalid/hosts"
ADBLOCK_SECONDARY_URL="https://StevenBlack.invalid/hosts"

OPENAI_OVERRIDE_IPS_FALLBACK="193.233.112.68"
GEMINI_OVERRIDE_IPS_FALLBACK="62.133.62.97"
CLAUDE_OVERRIDE_IPS_FALLBACK="193.233.112.68"
OPENAI_OVERRIDE_IPS="$OPENAI_OVERRIDE_IPS_FALLBACK"
GEMINI_OVERRIDE_IPS="$GEMINI_OVERRIDE_IPS_FALLBACK"
CLAUDE_OVERRIDE_IPS="$CLAUDE_OVERRIDE_IPS_FALLBACK"
OPENAI_BACKEND_CANDIDATES="37.230.192.51 193.233.112.68"
GEMINI_BACKEND_CANDIDATES="37.230.192.51 62.133.62.97"
CLAUDE_BACKEND_CANDIDATES="37.230.192.51 193.233.112.68"

curl() {
  printf '403'
}
if backend_probe "gemini.google.com" "/app" "203.0.113.20" strict; then
  exit 1
fi
backend_probe "waa-pa.clients6.google.com" "/" "203.0.113.20" reachable
unset -f curl

has_curl() {
  return 0
}
curl() {
  printf 'curl: (28) Resolving timed out after 8000 milliseconds\n000'
  return 28
}
if dns_resolution_probe; then
  exit 1
else
  test "$?" -eq 1
fi
curl() {
  printf '204'
  return 0
}
dns_resolution_probe
curl() {
  printf 'curl: (28) Connection timed out after 8000 milliseconds\n000'
  return 28
}
if dns_resolution_probe; then
  exit 1
else
  test "$?" -eq 2
fi
unset -f curl
has_curl() {
  command -v curl >/dev/null 2>&1
}

backend_probe() {
  test "$3" = "37.230.192.51"
}

ensure_state_dirs
FETCHED="$STATE_DIR/fetched.hosts"
fetch_valid_hosts "$FETCHED"
test -s "$FETCHED"
validate_source_hosts_file "$FETCHED"

refresh_gemini_override_domains
VOICE_OUTPUT="$(check_chatgpt_voice_ranges)"
printf '%s\n' "$VOICE_OUTPUT" | grep -q 'OK: OpenAI Voice IP ranges fetched: 2 ranges, created 2026-03-26T20:12:45.451356+00:00'
apply_ai_overrides "$FETCHED"
FIRST_GEMINI="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+gemini\.google\.com$' "$FETCHED" | head -n 1)"
test "$FIRST_GEMINI" = "62.133.62.97 gemini.google.com"
FIRST_CHATGPT_VOICE="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+webrtc\.chatgpt\.com$' "$FETCHED" | head -n 1)"
test "$FIRST_CHATGPT_VOICE" = "193.233.112.68 webrtc.chatgpt.com"
FIRST_CLAUDE="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+api\.anthropic\.com$' "$FETCHED" | head -n 1)"
test "$FIRST_CLAUDE" = "193.233.112.68 api.anthropic.com"
MALW_DYNAMIC="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+a\.claude\.ai$' "$FETCHED" | head -n 1)"
test "$MALW_DYNAMIC" = "193.233.112.68 a.claude.ai"
! grep -Eq '^0\.0\.0\.0[[:space:]]+' "$FETCHED"
grep -q '^203\.0\.113\.10 unrelated\.example$' "$FETCHED"
DUPLICATE_ROUTE_PAIRS="$(awk '$1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ { pair=$1 " " $2; count[pair]++ } END { for (pair in count) if (count[pair] > 1) print pair }' "$FETCHED")"
test -z "$DUPLICATE_ROUTE_PAIRS"

FRESH="$STATE_DIR/geohide.hosts"
download_url "https://geohide-fresh.invalid/hosts" "$FRESH"
validate_source_hosts_file "$FRESH"
OPENAI_OVERRIDE_IPS_FALLBACK="46.8.158.6 193.233.112.67"
GEMINI_OVERRIDE_IPS_FALLBACK="46.8.158.6 193.233.112.67"
CLAUDE_OVERRIDE_IPS_FALLBACK="46.8.158.6 193.233.112.67"
apply_ai_overrides "$FRESH"
test "$(grep -cE '^[0-9.]+[[:space:]]+gemini\.google\.com$' "$FRESH")" -eq 2
check_route_redundancy "$FRESH" "fresh fixture" >/dev/null
grep -q '^46\.8\.158\.6 spotify\.com$' "$FRESH"
grep -q '^193\.233\.112\.68 spotify\.com$' "$FRESH"
DUPLICATE_ROUTE_PAIRS="$(awk '$1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ { pair=$1 " " $2; count[pair]++ } END { for (pair in count) if (count[pair] > 1) print pair }' "$FRESH")"
test -z "$DUPLICATE_ROUTE_PAIRS"
OPENAI_OVERRIDE_IPS_FALLBACK="193.233.112.68"
GEMINI_OVERRIDE_IPS_FALLBACK="62.133.62.97"
CLAUDE_OVERRIDE_IPS_FALLBACK="193.233.112.68"

MALW_HOSTS_URL="https://malw-fail.invalid/hosts"
OPENAI_OVERRIDE_DOMAINS="$OPENAI_OVERRIDE_DOMAINS_FALLBACK"
GEMINI_OVERRIDE_DOMAINS="$GEMINI_OVERRIDE_DOMAINS_FALLBACK"
CLAUDE_OVERRIDE_DOMAINS="$CLAUDE_OVERRIDE_DOMAINS_FALLBACK"
OPENAI_OVERRIDE_IPS="$OPENAI_OVERRIDE_IPS_FALLBACK"
GEMINI_OVERRIDE_IPS="$GEMINI_OVERRIDE_IPS_FALLBACK"
CLAUDE_OVERRIDE_IPS="$CLAUDE_OVERRIDE_IPS_FALLBACK"
refresh_ai_overrides_from_malw
case " $CLAUDE_OVERRIDE_DOMAINS " in
  *" fresh-fallback.claude.ai "*) ;;
  *) exit 1 ;;
esac
MALW_HOSTS_URL="https://dns.malw.link/hosts"

run_update "test"
validate_hosts_file "$HOSTS_PATH"
FIRST_INSTALLED="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+gemini\.google\.com$' "$HOSTS_PATH" | head -n 1)"
test "$FIRST_INSTALLED" = "37.230.192.51 gemini.google.com"
FIRST_DYNAMIC="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+notebook\.google\.com$' "$HOSTS_PATH" | head -n 1)"
test "$FIRST_DYNAMIC" = "37.230.192.51 notebook.google.com"
FIRST_INSTALLED_CHATGPT="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+webrtc\.chatgpt\.com$' "$HOSTS_PATH" | head -n 1)"
test "$FIRST_INSTALLED_CHATGPT" = "37.230.192.51 webrtc.chatgpt.com"
FIRST_INSTALLED_CLAUDE="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+api\.anthropic\.com$' "$HOSTS_PATH" | head -n 1)"
test "$FIRST_INSTALLED_CLAUDE" = "37.230.192.51 api.anthropic.com"
grep -q '^0\.0\.0\.0 ads\.example$' "$HOSTS_PATH"
test "$(grep -c '^0\.0\.0\.0 ads\.example$' "$HOSTS_PATH")" -eq 1
! grep -Eq '^0\.0\.0\.0[[:space:]]+(chatgpt\.com|bzr\.openai\.com|gemini\.google\.com|api\.anthropic\.com)$' "$HOSTS_PATH"
validate_hosts_file "$HOSTS_PATH"

has_curl() {
  return 1
}
GEMINI_OVERRIDE_IPS_FALLBACK="62.133.62.97"
GEMINI_OVERRIDE_IPS="62.133.62.97"
select_gemini_backend >/dev/null
test "${GEMINI_OVERRIDE_IPS%% *}" = "37.230.192.51"

backend_probe() {
  test "$3" = "31.25.239.132"
}
has_curl() {
  return 0
}
OPENAI_BACKEND_CANDIDATES="31.25.239.132"
GEMINI_BACKEND_CANDIDATES="31.25.239.132"
CLAUDE_BACKEND_CANDIDATES="31.25.239.132"
FORCE_DOWNLOAD_FAIL=1
BLOCK_COUNT_BEFORE="$(grep -Ec '^0\.0\.0\.0[[:space:]]+' "$HOSTS_PATH")"
run_update "offline-repair"
test "$(grep -E '^[0-9.]+[[:space:]]+webrtc\.chatgpt\.com$' "$HOSTS_PATH" | head -n 1)" = "31.25.239.132 webrtc.chatgpt.com"
test "$(grep -E '^[0-9.]+[[:space:]]+gemini\.google\.com$' "$HOSTS_PATH" | head -n 1)" = "31.25.239.132 gemini.google.com"
test "$(grep -E '^[0-9.]+[[:space:]]+api\.anthropic\.com$' "$HOSTS_PATH" | head -n 1)" = "31.25.239.132 api.anthropic.com"
test "$(grep -Ec '^0\.0\.0\.0[[:space:]]+' "$HOSTS_PATH")" -eq "$BLOCK_COUNT_BEFORE"
FORCE_DOWNLOAD_FAIL=0

test ! -e "$ROOT/service.sh"
grep -q 'check_dns_health' "$ROOT/action.sh"
if grep -R -E 'settings[[:space:]]+put|recover_dns_if_needed|run_auto_update|run_smart_maintenance|while[[:space:]]+true' \
  "$ROOT/action.sh" "$ROOT/customize.sh" "$ROOT/scripts"; then
  exit 1
fi
grep -q 'rm -f "$MODPATH/service.sh"' "$ROOT/customize.sh"
grep -q '^version=4\.5$' "$ROOT/module.prop"
grep -q '^versionCode=27$' "$ROOT/module.prop"

MODULES_ROOTS="$WORK/modules"
mkdir -p "$MODULES_ROOTS/other/system/etc"
printf '127.0.0.1 localhost\n' > "$MODULES_ROOTS/other/system/etc/hosts"
if check_hosts_conflicts >/dev/null; then
  exit 1
fi
touch "$MODULES_ROOTS/other/disable"
check_hosts_conflicts >/dev/null

INVALID_HOSTS="$WORK/invalid.hosts"
cp "$HOSTS_PATH" "$INVALID_HOSTS"
printf '999.999.999.999 invalid-ip.example\n' >> "$INVALID_HOSTS"
if validate_hosts_file "$INVALID_HOSTS"; then
  exit 1
fi

IPV6_HOSTS="$WORK/ipv6.hosts"
cp "$HOSTS_PATH" "$IPV6_HOSTS"
printf '2a02:e00:ffec:4b8::1 ipv6.example\n' >> "$IPV6_HOSTS"
validate_hosts_file "$IPV6_HOSTS"

if acquire_update_lock; then
  if acquire_update_lock; then
    exit 1
  fi
  release_update_lock
else
  exit 1
fi

echo "ai_unlock_hosts regression tests passed"
