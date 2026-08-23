{{- define "voting-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 -}}
{{- end -}}

{{- define "voting-app.fullname" -}}
{{- printf "%s" (include "voting-app.name" .) -}}
{{- end -}}
