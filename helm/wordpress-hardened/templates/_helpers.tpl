{{/*
Expand the name of the chart.
*/}}
{{- define "wordpress-hardened.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wordpress-hardened.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "wph" $.Values.nameOverride }}
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
{{- define "wordpress-hardened.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wordpress-hardened.labels" -}}
helm.sh/chart: {{ include "wordpress-hardened.chart" . }}
{{ include "wordpress-hardened.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wordpress-hardened.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wordpress-hardened.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wordpress-hardened.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wordpress-hardened.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "wordpress-hardened.mounts" }}
{{- if .Values.pv.wp.enabled }}
- name: wp
  mountPath: /var/www/riotkit
{{- end }}

{{- if .Values.pv.wp_content.enabled }}
- name: wp-content
  mountPath: /var/www/riotkit/wp-content
{{- end }}

{{- with .Values.pv.extraVolumeMounts }}
{{- toYaml . }}
{{- end }}

{{- end }}

{{- define "wordpress-hardened.job" }}
{{ $job := .job }}
{{ $jobName := .jobName }}

ttlSecondsAfterFinished: {{ ($job.ttlSecondsAfterFinished | default "86400") }}
activeDeadlineSeconds: {{ ($job.activeDeadlineSeconds | default "60") }}
backoffLimit: 1
completions: 1
parallelism: 1
suspend: false
template:
    spec:
        volumes:
            - name: scripts
              configMap:
                  name: {{ include "wordpress-hardened.name" . }}-sql-scripts
        containers:
            - name: mysql
              image: {{ $job.image | quote }}
              imagePullPolicy: IfNotPresent
              args: ["-c", "cat /mnt/script.sql | mysql -u {{ .Values.db.user }} -h {{ .Values.db.host }} -P {{ .Values.db.port }} -p${WORDPRESS_DB_PASSWORD} {{ .Values.db.name }}"]
              command: ["/bin/sh"]
              env:
                  {{- if not (hasKey $.Values.env "WORDPRESS_DB_PASSWORD") }}
                  - name: WORDPRESS_DB_PASSWORD
                    valueFrom:
                        secretKeyRef:
                            name: {{ .Values.db.password.secretName | quote }}
                            key: {{ .Values.db.password.secretKey | quote }}
                  {{ else }}
                  - name: WORDPRESS_DB_PASSWORD
                    value: {{ .Values.env.WORDPRESS_DB_PASSWORD | quote }}
                  {{- end }}
              resources: {}
              volumeMounts:
                  - name: scripts
                    mountPath: /mnt/script.sql
                    subPath: {{ $jobName }}
        dnsPolicy: ClusterFirst
        restartPolicy: Never
        automountServiceAccountToken: false
        terminationGracePeriodSeconds: {{ ($job.terminationGracePeriodSeconds | default "5") }}
{{- end }}