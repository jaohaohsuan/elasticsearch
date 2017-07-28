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
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "labels.master" -}}
component: master
app: {{ .Chart.Name }}
release: {{ .Release.Name }} 
{{- end -}}

{{- define "labels.client" -}}
component: client
app: {{ .Chart.Name }}
release: {{ .Release.Name }} 
{{- end -}}

{{- define "labels.data" -}}
component: data
app: {{ .Chart.Name }}
release: {{ .Release.Name }} 
{{- end -}}

{{- define "labels" -}}
heritage: {{ .Release.Service }}
release: {{ .Release.Name }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}
