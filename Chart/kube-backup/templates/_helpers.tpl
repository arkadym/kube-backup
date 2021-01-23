{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}

{{- define "prefix" -}}
{{- printf "%s-" (include "name" .) -}}
{{- end -}}

{{- define "fullname" -}}
{{- if hasPrefix (include "prefix" .) .Release.Name -}}
{{- printf "%s" .Release.Name -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" $name .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "backup.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" (include "fullname" .) $name "cronjob" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
