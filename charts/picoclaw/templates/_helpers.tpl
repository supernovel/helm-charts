{{/*
Expand the name of the chart.
*/}}
{{- define "picoclaw.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Truncated to 63 characters because Kubernetes DNS naming spec.
*/}}
{{- define "picoclaw.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart label.
*/}}
{{- define "picoclaw.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "picoclaw.labels" -}}
helm.sh/chart: {{ include "picoclaw.chart" . }}
{{ include "picoclaw.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "picoclaw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "picoclaw.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "picoclaw.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "picoclaw.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image tag — defaults to appVersion.
*/}}
{{- define "picoclaw.imageTag" -}}
{{- default .Chart.AppVersion .Values.image.tag }}
{{- end }}

{{/*
PVC name for the single data volume.
*/}}
{{- define "picoclaw.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- include "picoclaw.fullname" . }}-data
{{- end }}
{{- end }}

{{/*
Secret name for config.json ConfigMap.
*/}}
{{- define "picoclaw.configMapName" -}}
{{- include "picoclaw.fullname" . }}-config
{{- end }}

{{/*
Secret name for the client gateway token (PICOCLAW_GATEWAY_TOKEN).
*/}}
{{- define "picoclaw.clientSecretName" -}}
{{- include "picoclaw.fullname" . }}-client
{{- end }}

{{/*
Resolve the gateway token for the picoclaw-client sidecar.
Priority:
  1. .Values.client.gatewayToken if explicitly set
  2. Existing Secret value (persists across upgrades)
  3. Deterministic fallback derived from release identity (stable across re-renders)
*/}}
{{- define "picoclaw.resolvedGatewayToken" -}}
{{- if .Values.client.gatewayToken -}}
{{- .Values.client.gatewayToken -}}
{{- else -}}
{{- $secretName := include "picoclaw.clientSecretName" . -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if and $existing $existing.data (index $existing.data "gateway-token") -}}
{{- index $existing.data "gateway-token" | b64dec -}}
{{- else -}}
{{- printf "pico-%s" (printf "%s.%s" .Release.Name .Release.Namespace | sha256sum | trunc 32) -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Secret name for .security.yml (model api_keys).
Ref: https://docs.picoclaw.io/docs/configuration/config-reference#security-configuration
*/}}
{{- define "picoclaw.securitySecretName" -}}
{{- include "picoclaw.fullname" . }}-security
{{- end }}

{{/*
Render .security.yml — all sensitive credentials in one place.
picoclaw deep-merges this file into config at startup (config.json wins on conflict).

Sections:
  model_list   — api_keys per model (keyed by model_name)
  channels     — telegram / discord / slack tokens
  tools.web    — brave / perplexity api_keys

Ref: https://docs.picoclaw.io/docs/credential-encryption
*/}}
{{- define "picoclaw.securityYaml" -}}
{{- $cfg := .Values.config }}
model_list:
{{- range $m := $cfg.modelList }}
{{- if $m.apiKey }}
  {{ $m.modelName }}:
    api_keys:
      - {{ $m.apiKey | quote }}
{{- end }}
{{- end }}

{{- $ch := $cfg.channels }}
{{- $hasChannels := or $ch.telegram.token $ch.discord.token $ch.slack.botToken $ch.slack.appToken }}
{{- if $hasChannels }}
channels:
  {{- if $ch.telegram.token }}
  telegram:
    token: {{ $ch.telegram.token | quote }}
  {{- end }}
  {{- if $ch.discord.token }}
  discord:
    token: {{ $ch.discord.token | quote }}
  {{- end }}
  {{- if or $ch.slack.botToken $ch.slack.appToken }}
  slack:
    {{- if $ch.slack.botToken }}
    bot_token: {{ $ch.slack.botToken | quote }}
    {{- end }}
    {{- if $ch.slack.appToken }}
    app_token: {{ $ch.slack.appToken | quote }}
    {{- end }}
  {{- end }}
  pico:
    token: {{ include "picoclaw.resolvedGatewayToken" . | quote }}
{{- else }}
channels:
  pico:
    token: {{ include "picoclaw.resolvedGatewayToken" . | quote }}
{{- end }}

{{- $web := $cfg.tools.web }}
{{- $hasTools := or $web.brave.apiKey $web.perplexity.apiKey }}
{{- if $hasTools }}
tools:
  web:
    {{- if $web.brave.apiKey }}
    brave:
      api_key: {{ $web.brave.apiKey | quote }}
    {{- end }}
    {{- if $web.perplexity.apiKey }}
    perplexity:
      api_key: {{ $web.perplexity.apiKey | quote }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Render config.json as JSON from values.
api_key fields are intentionally omitted here — they are provided via
.security.yml (secret.yaml) which picoclaw merges at startup.
Ref: https://docs.picoclaw.io/docs/configuration/config-reference
*/}}
{{- define "picoclaw.configJson" -}}
{{- $cfg := .Values.config }}
{{- $channels := $cfg.channels }}
{
  "agents": {
    "defaults": {
      "workspace": {{ $cfg.agents.defaults.workspace | quote }},
      "restrict_to_workspace": {{ $cfg.agents.defaults.restrictToWorkspace }},
      "model_name": {{ $cfg.agents.defaults.modelName | quote }},
      "max_tokens": {{ $cfg.agents.defaults.maxTokens }},
      "max_tool_iterations": {{ $cfg.agents.defaults.maxToolIterations }}
    }
  },
  "model_list": [
    {{- range $i, $m := $cfg.modelList }}
    {{- if $i }},{{ end }}
    {
      "model_name": {{ $m.modelName | quote }},
      "model": {{ $m.model | quote }}
      {{- if $m.apiBase }},
      "api_base": {{ $m.apiBase | quote }}
      {{- end }}
      {{- if $m.requestTimeout }},
      "request_timeout": {{ $m.requestTimeout }}
      {{- end }}
    }
    {{- end }}
  ],
  "channels": {
    "telegram": {
      "enabled": {{ $channels.telegram.enabled }},
      "allow_from": []
    },
    "discord": {
      "enabled": {{ $channels.discord.enabled }},
      "allow_from": []
    },
    "slack": {
      "enabled": {{ $channels.slack.enabled }},
      "allow_from": []
    },
    "pico": {
      "enabled": true,
      "allow_from": []
    }
  },
  "tools": {
    "web": {
      "duckduckgo": {
        "enabled": {{ $cfg.tools.web.duckduckgo.enabled }},
        "max_results": {{ $cfg.tools.web.duckduckgo.maxResults }}
      },
      "brave": {
        "enabled": {{ $cfg.tools.web.brave.enabled }},
        "max_results": {{ $cfg.tools.web.brave.maxResults }}
      },
      "perplexity": {
        "enabled": {{ $cfg.tools.web.perplexity.enabled }},
        "max_results": {{ $cfg.tools.web.perplexity.maxResults }}
      }
    },
    "mcp": {
      "enabled": {{ $cfg.tools.mcp.enabled }}
    },
    "cron": {
      "exec_timeout_minutes": {{ $cfg.tools.cron.execTimeoutMinutes }}
    },
    "exec": {
      "enable_deny_patterns": {{ $cfg.tools.exec.enableDenyPatterns }}
    }
  },
  "heartbeat": {
    "enabled": {{ $cfg.heartbeat.enabled }},
    "interval": {{ $cfg.heartbeat.interval }}
  },
  "gateway": {
    "host": {{ $cfg.gateway.host | quote }},
    "port": {{ $cfg.gateway.port }}
  }
}
{{- end }}
