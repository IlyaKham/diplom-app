# diplom-app

Статическое nginx-приложение диплома DevOps. Собственный Dockerfile, HTTP на порту 8080, пользователь UID 101, файловая система только для чтения с временным `/tmp`.

- [Инфраструктура и отчёт со скриншотами](https://github.com/IlyaKham/diplom-infrastructure/blob/main/README.md).
- [Успешная сборка и деплой релиза](https://github.com/IlyaKham/diplom-app/actions/runs/44100761404).

## Реализация

| Файл | Назначение |
| --- | --- |
| `Dockerfile` | Сборка на nginx 1.30.6-alpine, закреплённом digest; метаданные версии и коммита |
| `nginx.conf` | HTTP, healthz, журналы stdout/stderr, временные файлы в /tmp |
| `html/` | Страница, стили и отображение версии |
| `kubernetes/` | Манифесты приложения, Helm values мониторинга/Traefik и настройки ARC с RBAC |
| `.github/workflows/application.yml` | Сборка, проверка и публикация каждого push; автоматический деплой релизного тега |


Образ релиза в приватном Yandex Container Registry:

```text
cr.yandex/crp85lbhbo07ldt2oj0c/diplom-app:v1.0.0
cr.yandex/crp85lbhbo07ldt2oj0c/diplom-app@sha256:3e2d086d30d4a3069ca115ef5acfc253c7d1e199c6a3c848c17637203d7fbc81
```

Локальная сборка: `docker build -t diplom-app:local .`. Проверки HTTP, версии и непривилегированного запуска описаны непосредственно в workflow.

`/` — страница, `/healthz` — HTTP 200 и `ok`, `/version.json` — версия, ревизия и время сборки; неизвестный адрес возвращает 404. Секретов среди build args нет.

