{{/*
Expand the name of the chart.
*/}}
{{- define "kubevirt-windows-vm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubevirt-windows-vm.fullname" -}}
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
{{- define "kubevirt-windows-vm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubevirt-windows-vm.labels" -}}
helm.sh/chart: {{ include "kubevirt-windows-vm.chart" . }}
{{ include "kubevirt-windows-vm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubevirt-windows-vm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubevirt-windows-vm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kubevirt-windows-vm.serviceAccountName" -}}
{{- if .Values.adminNovnc.serviceAccount.create }}
{{- default (include "kubevirt-windows-vm.fullname" .) .Values.adminNovnc.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.adminNovnc.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
admin noVNC deployment name (QEMU VNC — no public exposure, port-forward only)
*/}}
{{- define "kubevirt-windows-vm.adminConsoleName" -}}
{{- printf "%s-admin" (include "kubevirt-windows-vm.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
admin noVNC common labels
*/}}
{{- define "kubevirt-windows-vm.adminConsoleLabels" -}}
helm.sh/chart: {{ include "kubevirt-windows-vm.chart" . }}
{{ include "kubevirt-windows-vm.adminConsoleSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: novnc-admin
{{- end }}

{{/*
admin noVNC selector labels
*/}}
{{- define "kubevirt-windows-vm.adminConsoleSelectorLabels" -}}
app.kubernetes.io/name: {{ include "kubevirt-windows-vm.adminConsoleName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: novnc-admin
{{- end }}

{{/*
Guacamole HTML5 RDP deployment name
*/}}
{{- define "kubevirt-windows-vm.guacamoleName" -}}
{{- printf "%s-guacamole" (include "kubevirt-windows-vm.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Guacamole common labels
*/}}
{{- define "kubevirt-windows-vm.guacamoleLabels" -}}
helm.sh/chart: {{ include "kubevirt-windows-vm.chart" . }}
{{ include "kubevirt-windows-vm.guacamoleSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: guacamole
{{- end }}

{{/*
Guacamole selector labels
*/}}
{{- define "kubevirt-windows-vm.guacamoleSelectorLabels" -}}
app.kubernetes.io/name: {{ include "kubevirt-windows-vm.guacamoleName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: guacamole
{{- end }}
