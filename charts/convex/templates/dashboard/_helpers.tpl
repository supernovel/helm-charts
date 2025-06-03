{{/*
Expand the name of the chart.
*/}}
{{- define "convex.dashboard.name" -}}
{{- default (print .Chart.Name "-dashboard") .Values.dashboard.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "convex.dashboard.fullname" -}}
{{- if .Values.dashboard.fullnameOverride }}
{{- .Values.dashboard.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default (print .Chart.Name "-dashboard") .Values.dashboard.nameOverride }}
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
{{- define "convex.dashboard.selectorLabels" -}}
app.kubernetes.io/name: {{ include "convex.dashboard.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "convex.dashboard.serviceAccountName" -}}
{{- if .Values.dashboard.serviceAccount.create }}
{{- default (include "convex.dashboard.fullname" .) .Values.dashboard.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.dashboard.serviceAccount.name }}
{{- end }}
{{- end }}
