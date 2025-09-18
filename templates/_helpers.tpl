{{/*
Expand the name of the chart.
*/}}
{{- define "democrm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "democrm.fullname" -}}
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
{{- define "democrm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "democrm.labels" -}}
helm.sh/chart: {{ include "democrm.chart" . }}
{{ include "democrm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "democrm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "democrm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create MongoDB connection string
*/}}
{{- define "democrm.mongodbConnectionString" -}}
{{- if .Values.mongodb.enabled -}}
{{- $mongodbHost := printf "%s-mongodb-0.%s-mongodb-headless.%s.svc.cluster.local:27017,%s-mongodb-1.%s-mongodb-headless.%s.svc.cluster.local:27017" .Release.Name .Release.Name .Release.Namespace .Release.Name .Release.Name .Release.Namespace -}}
{{- printf "mongodb://%s:%s@%s/?replicaSet=%s&authSource=admin" .Values.mongodb.auth.rootUser .Values.mongodb.auth.rootPassword $mongodbHost .Values.mongodb.replicaSet.name -}}
{{- else -}}
{{- .Values.externalDatabase.connectionString -}}
{{- end -}}
{{- end }}

{{/*
MongoDB secret name
*/}}
{{- define "democrm.mongodbSecretName" -}}
{{- if .Values.security.mongodbSecret.name -}}
{{- .Values.security.mongodbSecret.name -}}
{{- else -}}
{{- printf "%s-mongodb-secret" (include "democrm.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "democrm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "democrm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}