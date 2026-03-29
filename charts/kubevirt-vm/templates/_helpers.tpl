{{/*
Expand the name of the chart.
*/}}
{{- define "kubevirt-vm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubevirt-vm.fullname" -}}
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
{{- define "kubevirt-vm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubevirt-vm.labels" -}}
helm.sh/chart: {{ include "kubevirt-vm.chart" . }}
{{ include "kubevirt-vm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubevirt-vm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubevirt-vm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kubevirt-vm.serviceAccountName" -}}
{{- if .Values.novnc.serviceAccount.create }}
{{- default (include "kubevirt-vm.fullname" .) .Values.novnc.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.novnc.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
noVNC deployment name
*/}}
{{- define "kubevirt-vm.consoleName" -}}
{{- printf "%s-console" (include "kubevirt-vm.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
noVNC common labels
*/}}
{{- define "kubevirt-vm.consoleLabels" -}}
helm.sh/chart: {{ include "kubevirt-vm.chart" . }}
{{ include "kubevirt-vm.consoleSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: novnc
{{- end }}

{{/*
noVNC selector labels
*/}}
{{- define "kubevirt-vm.consoleSelectorLabels" -}}
app.kubernetes.io/name: {{ include "kubevirt-vm.consoleName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: novnc
{{- end }}

{{/*
noVNC admin deployment name (QEMU VNC — no public exposure, port-forward only)
*/}}
{{- define "kubevirt-vm.adminConsoleName" -}}
{{- printf "%s-admin" (include "kubevirt-vm.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
noVNC admin common labels
*/}}
{{- define "kubevirt-vm.adminConsoleLabels" -}}
helm.sh/chart: {{ include "kubevirt-vm.chart" . }}
{{ include "kubevirt-vm.adminConsoleSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: novnc-admin
{{- end }}

{{/*
noVNC admin selector labels
*/}}
{{- define "kubevirt-vm.adminConsoleSelectorLabels" -}}
app.kubernetes.io/name: {{ include "kubevirt-vm.adminConsoleName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: novnc-admin
{{- end }}

{{/*
Build the cloud-config user-data string from structured values.
qemu-guest-agent and its activation are always included.
*/}}
{{- define "kubevirt-vm.cloudInitUserData" -}}
#cloud-config
hostname: {{ include "kubevirt-vm.fullname" . }}
users:
  - name: {{ .Values.vm.cloudInit.user.name }}
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
chpasswd:
  list: "{{ .Values.vm.cloudInit.user.name }}:{{ .Values.vm.cloudInit.user.password }}"
  expire: false
ssh_pwauth: true
packages:
  - qemu-guest-agent
{{- if .Values.novnc.guest.enabled }}
  - tigervnc-standalone-server
{{- end }}
{{- range .Values.vm.cloudInit.packages }}
  - {{ . }}
{{- end }}
runcmd:
  - systemctl enable --now qemu-guest-agent
{{- if .Values.novnc.guest.enabled }}
  - systemctl enable --now vncserver@:1
{{- end }}
{{- range .Values.vm.cloudInit.runcmd }}
  - {{ . }}
{{- end }}
{{- end }}
