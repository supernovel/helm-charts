{{/*
Expand the name of the backend secret.
*/}}
{{- define "convex.secret.backend" -}}
{{- printf "%s-backend" (include "convex.fullname" .) }}
{{- end -}}