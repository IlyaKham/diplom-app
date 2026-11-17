# diplom-app

Статическое nginx-приложение диплома DevOps. Собственный Dockerfile, HTTP на порту 8080, пользователь UID 101, файловая система только для чтения с временным `/tmp`.

- [Работающее приложение](http://46.243.210.163/) — `v1.0.0`.
- [Инфраструктура и отчёт со скриншотами](https://github.com/IlyaKham/diplom-infrastructure/blob/main/REPORT.md).
- [Успешная сборка и деплой релиза](https://github.com/IlyaKham/diplom-app/actions/runs/44100761404).

## Реализация

| Файл | Назначение |
| --- | --- |
| `Dockerfile` | Сборка на nginx 1.30.6-alpine, закреплённом digest; метаданные версии и коммита |
| `nginx.conf` | HTTP, healthz, журналы stdout/stderr, временные файлы в /tmp |
| `html/` | Страница, стили и отображение версии |
| `.github/workflows/application.yml` | Сборка, проверка и публикация каждого push; автоматический деплой релизного тега |
| `ci/image-metadata.sh` | Теги образа, версия, SHA и время сборки |
| `ci/smoke-test.sh` | Проверка образа перед публикацией |

Обычный коммит публикуется как `sha-<полный SHA>`. Тег `vX.Y.Z` или `vX.Y.Z-rc.1` дополнительно запускает deploy в Kubernetes по digest. Деплой выполняет временный runner `diplom-deploy` внутри кластера; параметры runner и RBAC находятся в репозитории инфраструктуры.

В GitHub Actions используются Secret `YC_SERVICE_ACCOUNT_KEY` и Variables `YC_REGISTRY_ID`, `APPLICATION_URL`. Облачный ключ нужен только заданию сборки для публикации; deploy использует внутренний Kubernetes ServiceAccount.

Образ релиза в приватном Yandex Container Registry:

```text
cr.yandex/crp85lbhbo07ldt2oj0c/diplom-app:v1.0.0
cr.yandex/crp85lbhbo07ldt2oj0c/diplom-app@sha256:3e2d086d30d4a3069ca115ef5acfc253c7d1e199c6a3c848c17637203d7fbc81
```

Локальная сборка: `docker build -t diplom-app:local .`. Проверка в Bash: `bash ci/smoke-test.sh diplom-app:local dev` (нужны Docker, curl, jq и свободный порт 18080).

`/` — страница, `/healthz` — HTTP 200 и `ok`, `/version.json` — версия, ревизия и время сборки; неизвестный адрес возвращает 404. Секретов среди build args нет.
