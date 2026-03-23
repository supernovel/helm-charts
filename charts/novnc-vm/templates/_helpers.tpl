{{/*
Expand the name of the chart.
*/}}
{{- define "novnc-vm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "novnc-vm.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "novnc-vm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "novnc-vm.labels" -}}
helm.sh/chart: {{ include "novnc-vm.chart" . }}
{{ include "novnc-vm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "novnc-vm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "novnc-vm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "novnc-vm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "novnc-vm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
noVNC deployment name
*/}}
{{- define "novnc-vm.novncName" -}}
{{- printf "%s-novnc" (include "novnc-vm.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
noVNC common labels
*/}}
{{- define "novnc-vm.novncLabels" -}}
helm.sh/chart: {{ include "novnc-vm.chart" . }}
{{ include "novnc-vm.novncSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: novnc
{{- end }}

{{/*
noVNC selector labels
*/}}
{{- define "novnc-vm.novncSelectorLabels" -}}
app.kubernetes.io/name: {{ include "novnc-vm.novncName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: novnc
{{- end }}
