{{/*
Expand the name of the chart.
*/}}
{{- define "convex.backend.name" -}}
{{- default (print .Chart.Name "-backend") .Values.backend.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "convex.backend.fullname" -}}
{{- if .Values.backend.fullnameOverride }}
{{- .Values.backend.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default (print .Chart.Name "-backend") .Values.backend.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "convex.backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "convex.backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "convex.backend.serviceAccountName" -}}
{{- if .Values.backend.serviceAccount.create }}
{{- default (include "convex.backend.fullname" .) .Values.backend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.backend.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "convex.backend.cnpg.name" -}}
{{- printf "%s-%s" (include "convex.backend.fullname" .) "cnpg" }}
{{- end }}