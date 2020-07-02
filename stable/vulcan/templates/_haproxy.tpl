{{/*
Override names
*/}}
{{- define "proxy-annotations" -}}
{{- if .Values.proxy.enabled -}}
checksum/config-proxy: {{ include "proxy-config-map" . | sha256sum }}
prometheus.io/scrape: 'true'
prometheus.io/port: '{{ .Values.proxy.metricsPort | default 9101 }}'
{{- end -}}
{{- end -}}

{{- define "proxy-config-map" -}}
{{- if .Values.proxy.enabled -}}
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    name: {{ .Release.Name }}-{{ .Chart.Name }}-proxy
  name: {{ .Release.Name }}-{{ .Chart.Name }}-proxy
data:
  haproxy.cfg: |
    global
      daemon
      maxconn {{ .Values.proxy.maxconn | default 64 }}
      log stdout format raw daemon

    defaults
      mode http
      timeout connect 5s
      timeout client 25s
      timeout server 25s
      timeout tunnel 3600s
      option  http-server-close

    {{- if .Values.proxy.cache }}
    cache small
      total-max-size 64     # mb
      max-age 240           # seconds
    {{- end }}

    frontend http
      bind *:{{ .Values.proxy.port | default 80 }}
      log global
      option httplog clf
    {{- if .Values.proxy.cache }}
      http-request cache-use small
      http-response cache-store small
    {{- end }}
      http-request capture req.hdr(Host) len 50
      http-request capture req.hdr(User-Agent) len 100

    {{- if .Values.proxy.logFormat }}
      log-format "{{ .Values.proxy.logFormat }}"
    {{- end }}

      default_backend app

    backend app
      server app 127.0.0.1:{{ .Values.containerPort }}

    frontend stats
      bind *:{{ .Values.proxy.metricsPort | default 9101 }}
      option http-use-htx
      http-request use-service prometheus-exporter if { path /metrics }
      monitor-uri {{ .Values.proxy.probePath | default "/healthz" }}
{{- end -}}
{{- end -}}

{{- define "proxy-container" -}}
{{- if .Values.proxy.enabled }}
- name: proxy
  image: {{ .Values.proxy.image | default "haproxy:2.1-alpine" }}
  imagePullPolicy: Always
  ports:
    - name: http
      containerPort: {{ .Values.proxy.port | default "80" }}
    - name: metrics
      containerPort: {{ .Values.proxy.metricsPort | default 9101 }}
  volumeMounts:
  - mountPath: /usr/local/etc/haproxy
    readOnly: true
    name: config-proxy
  {{- if .Values.proxy.lifecycle.preStopSleep }}
  lifecycle:
    preStop:
      exec:
        command: ["/bin/sh","-c","sleep {{ .Values.proxy.lifecycle.preStopSleep }};"]
  {{- end }}
  {{- if .Values.proxy.probe }}
  livenessProbe:
    httpGet:
      path: {{ .Values.proxy.probePath | default "/healthz" }}
      port: metrics
    initialDelaySeconds: {{ .Values.proxy.probeInitialDelay | default 5 }}
    timeoutSeconds: {{ .Values.proxy.probeTimeoutSeconds | default 3 }}
  readinessProbe:
    httpGet:
      path: {{ .Values.proxy.probePath | default "/healthz" }}
      port: metrics
    initialDelaySeconds: {{ .Values.proxy.probeInitialDelay | default 5 }}
    timeoutSeconds: {{ .Values.proxy.probeTimeoutSeconds | default 3 }}
  {{- end }}
  resources:
    {{- toYaml .Values.proxy.resources | nindent 4 }}
{{- end -}}
{{- end -}}

{{- define "proxy-volumes" -}}
{{- if .Values.proxy.enabled -}}
- name: config-proxy
  configMap:
    name: {{ .Release.Name }}-{{ .Chart.Name }}-proxy
{{- end -}}
{{- end -}}
