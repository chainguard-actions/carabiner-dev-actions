#!/bin/sh
# Fake curl: intercepts OIDC and Carabiner exchange server calls.
# Supports both "curl URL | sh" (payload to stdout) and the hardened
# "curl -o FILE URL" (payload written to FILE) forms.
#
# Reads response payloads from:
#   /tmp/fake-oidc-response.json  — OIDC token endpoint response
#   /tmp/fake-exchange-response.json — token exchange endpoint response
#   /tmp/fake-exchange-error.json — token exchange error response (if present)
#
# URL routing:
#   *localhost* or *token_request* → OIDC endpoint (returns fake OIDC JWT)
#   *auth.carabiner.dev*token*     → exchange endpoint (returns fake Carabiner token)

out=""
prev=""
for arg in "$@"; do
  case "$prev" in
    -o|--output) out="$arg" ;;
  esac
  prev="$arg"
done

serve() {
  payload="$1"
  http_code="${2:-}"
  if [ -n "$out" ]; then
    cat "$payload" > "$out"
    if [ -n "$http_code" ]; then
      printf '\n%s' "$http_code" >> "$out"
    fi
  else
    cat "$payload"
    if [ -n "$http_code" ]; then
      printf '\n%s' "$http_code"
    fi
  fi
}

case "$*" in
  *localhost*|*token_request*)
    # OIDC token request — return fake OIDC JWT
    serve /tmp/fake-oidc-response.json
    exit 0
    ;;
  *auth.carabiner.dev*token*)
    # Token exchange request — check for error response first
    if [ -f /tmp/fake-exchange-error.json ]; then
      http_code="${FAKE_EXCHANGE_HTTP_CODE:-403}"
      serve /tmp/fake-exchange-error.json "$http_code"
    else
      serve /tmp/fake-exchange-response.json "200"
    fi
    exit 0
    ;;
esac

# Fall through to real curl for anything else
exec /usr/bin/curl "$@"
