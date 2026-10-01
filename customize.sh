#!/sbin/sh
OUTFD="$2"
ZIP="$3"

ui_print "Установка AI Unlock v4.5 Ultimate Passive..."
ui_print " "
ui_print "- Обход блокировок AI-сервисов (Gemini, ChatGPT, Claude, Spotify и др.) без VPN."
ui_print "- Всё в одном: AI-разблокировка плюс реклама и трекеры."
ui_print "- Компактный мобильный список рекламы без перегрузки DNS."
ui_print "- База: свежий GeoHide с резервом dns.malw.link."
ui_print "- Кнопка действия Magisk: проверить DNS, обновить hosts и проверить AI-сервисы."
ui_print "- DNS проверяется только для диагностики; системные настройки не изменяются."
ui_print "- Фоновых проверок, таймеров и сетевых запросов нет."
ui_print "- Для каждого сервиса выбирается один проверенный маршрут; повторная проверка выполняется кнопкой."
ui_print "- AI-allowlist всегда имеет приоритет над рекламными списками."
ui_print "- Важно: отключите другие модули, заменяющие /system/etc/hosts."
ui_print "- Voice check: проверяет официальный список OpenAI Voice; UDP 3478 hosts-файл не изменяет."

set_perm "$MODPATH/action.sh" 0 0 0755
rm -f "$MODPATH/service.sh"
set_perm "$MODPATH/system/etc/hosts" 0 0 0644
set_perm_recursive "$MODPATH/scripts" 0 0 0755 0644
set_perm "$MODPATH/scripts/ai_unlock_hosts.sh" 0 0 0755
