FROM nginx:1.30.6-alpine@sha256:901e593c95dc85f5a729f5765516321366ef4ac401821431d408897e95287d0a

ARG APP_VERSION=dev
ARG VCS_REF=local
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="diplom-app" \
      org.opencontainers.image.description="Static nginx application for the DevOps diploma" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}"

COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

# Validate metadata before writing it as JSON. No credentials belong in build args.
RUN set -eu; \
    case "$APP_VERSION" in ''|*[!a-zA-Z0-9._+-]*) exit 1 ;; esac; \
    case "$VCS_REF" in ''|*[!a-zA-Z0-9._-]*) exit 1 ;; esac; \
    case "$BUILD_DATE" in ''|*[!a-zA-Z0-9.:+-]*) exit 1 ;; esac; \
    printf '{"version":"%s","revision":"%s","built_at":"%s"}\n' \
      "$APP_VERSION" "$VCS_REF" "$BUILD_DATE" > /usr/share/nginx/html/version.json

USER nginx
EXPOSE 8080
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=30s --timeout=3s --start-period=3s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1

ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
