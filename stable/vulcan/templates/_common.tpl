{{- define "common-manifests" -}}
{{- include "proxy-config-map" . }}
{{- end -}}

{{- define "common-annotations" -}}
{{- include "proxy-annotations" . }}
{{- end -}}

{{/*
Lifecycle common preStop
*/}}
{{- define "common-lifecycle" -}}
{{- if or .Values.lifecycle.preStopCommand .Values.lifecycle.preStopSleep -}}
lifecycle:
  preStop:
    exec:
{{- if .Values.lifecycle.preStopCommand }}
      command: {{ .Values.lifecycle.preStopCommand }}
{{- else }}
      command: ["/bin/sh","-c","sleep {{ .Values.lifecycle.preStopSleep }};"]
{{- end -}}
{{- end -}}
{{- if .Values.livenessProbe.enabled }}
livenessProbe:
{{- if .Values.livenessProbe.command }}
  exec:
    command: {{ .Values.livenessProbe.command }}
{{- else }}
  httpGet:
    path: {{ .Values.livenessProbe.path }}
    port: {{ .Values.containerPort }}
{{- end }}
  initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
  periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
  timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
  successThreshold: {{ .Values.livenessProbe.successThreshold }}
  failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
{{- end }}
{{- if .Values.readinessProbe.enabled }}
readinessProbe:
{{- if .Values.readinessProbe.command }}
  exec:
    command: {{ .Values.readinessProbe.command }}
{{- else }}
  httpGet:
    path: {{ .Values.readinessProbe.path }}
    port: {{ .Values.containerPort }}
{{- end }}
  initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
  periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
  timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
  successThreshold: {{ .Values.readinessProbe.successThreshold }}
  failureThreshold: {{ .Values.readinessProbe.failureThreshold }}
{{- end }}
{{- end -}}

{{- define "common-spec" -}}
{{- if .Values.terminationGracePeriodSeconds -}}
terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
{{- end -}}
{{- end -}}

{{- define "common-containers" -}}
{{- include "dogstatsd-sidecar" . }}
{{- include "proxy-container" . }}
{{- end -}}

{{- define "common-envs" -}}
{{- include "infra-envs-sqs" . }}
{{- include "infra-envs-sns" . }}
{{- include "infra-envs-minio" . }}
{{- include "dogstatsd-envs" . }}
{{- end -}}

{{- define "common-volumes" -}}
{{- include "proxy-volumes" . }}
{{- end -}}
