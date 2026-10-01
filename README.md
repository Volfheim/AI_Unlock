# AI Unlock

AI Unlock is a Magisk module that maintains a validated `hosts` overlay for AI services and advertising protection. It updates the hosts data only when the Magisk action is started, keeps a local backup, validates downloaded sources, and applies the result atomically.

AI Unlock — модуль Magisk для проверенного `hosts`-оверлея AI-сервисов и блокировки рекламы. Обновление запускается только кнопкой действия Magisk: модуль проверяет источник, сохраняет резервную копию и применяет результат атомарно.

## What is included / Что входит

- AI service routes for Gemini, ChatGPT and Claude with fallback candidates.
- Validated advertising blocklists with size and syntax limits.
- DNS and HTTPS diagnostics; no background service and no DNS settings changes.
- Conflict detection for another enabled module that owns `/system/etc/hosts`.
- Local state and backups are created on the device and are excluded from this repository.

В репозитории нет ключей, токенов, личного инвентаря или журналов устройства. Файл `state/update.log` намеренно не публикуется.

## Updates through GitHub / Обновления через GitHub

`module.prop` points Magisk to [`update.json`](update.json). The JSON feed describes the latest GitHub Release and its ZIP asset. Install the release ZIP from the **Assets** section or let Magisk detect the same release through the module updater.

В `module.prop` указан `updateJson`: Magisk получает из него версию, `versionCode`, ссылку на ZIP и changelog. Для ручной установки используйте ZIP из блока **Assets** соответствующего GitHub Release.

## Build and test / Сборка и проверка

On Windows PowerShell:

```powershell
.\build.ps1 -OutputPath ..\AI_Unlock_v4.5.zip
```

The build allowlist includes only the Magisk payload (`META-INF`, scripts, `module.prop`, `system`). Tests, local state and update logs are never added to the ZIP.

Run the regression test from Git Bash or another POSIX shell:

```bash
bash tests/test_ai_unlock_hosts.sh
```

## Sources and limitations / Источники и ограничения

The updater accepts only the HTTPS sources declared in `scripts/ai_unlock_hosts.sh` and rejects HTML responses, malformed entries, oversized files and blocked AI domains. The module requires a rooted Android device with Magisk and a single owner for `/system/etc/hosts`.

Используйте модуль только на собственном устройстве. Доступность маршрутов зависит от сети и внешних источников; успешная установка не гарантирует работу каждого сервиса.
