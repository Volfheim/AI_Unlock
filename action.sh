#!/system/bin/sh

MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR="$(pwd)"

if [ -r "$MODDIR/scripts/ai_unlock_hosts.sh" ]; then
  . "$MODDIR/scripts/ai_unlock_hosts.sh"
else
  echo "AI Unlock: updater script not found."
  exit 1
fi

echo "AI Unlock v$(get_module_version)"
echo "Magisk action: diagnose, update hosts atomically and check AI services"
echo

check_dns_health
dns_result=$?

echo
run_update "manual"
update_result=$?

echo
run_health_check
check_result=$?

if [ "$update_result" -ne 0 ] || [ "$check_result" -ne 0 ]; then
  exit 1
fi

exit 0
