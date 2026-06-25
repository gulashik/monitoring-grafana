### Остановить и удалить
```shell
clear
podman compose down
podman ps -a
```

### Остановить и удалить + удалить volume с данными
```shell
podman compose down -v
podman ps -a
```
```shell
rm -rf ./grafana/image-mapped-folders/*
```

### Остановить и удалить
```shell
clear
podman compose down
podman ps -a
```

### Состояние
```shell
clear
podman ps -a
```

### Запускаем 
```shell
clear
podman compose up -d
podman ps -a
```
### Утилиты
```shell
clear
podman exec -it netshoot sh 
# exit
```

### Логи последние 100 строк за последний час
```shell
podman compose logs -f --tail 100 --since 1h 
```

### Метрики node-exporter
```shell
clear
curl --request GET -sL \
     --url 'http://localhost:9100/metrics'
```
```shell
# prometheus
open http://localhost:9090/targets
```
```shell
# prometheus federation(prometheus который собирает метрики из другого prometheus)
open http://localhost:9099/targets
```
```shell
# grafana
# по умолчанию так и есть login: admin pass: admin
open http://localhost:3000
```

```shell
# allertmanager 
open http://localhost:9093
```
```shell
# notify от allertmanager
open http://localhost:8888/alerts
```

```shell
# pushgateway
open http://localhost:9091
```
```shell
# Отправка в Pushgateway
# Prometheus метрики представлены в виде специальных комментариев HELP и TYPE, 
#   а также самого временного ряда с названием метрики, лейблами и значением и 
#   именно в таком формате мы должны отправить её в Pushgateway
cat <<EOF | curl --data-binary @- -XPOST http://localhost:9091/metrics/job/example-job
# HELP example_metrics_for_pushgateway Example of a metric sent to Pushgateway.
# TYPE example_metrics_for_pushgateway counter
example_metrics_for_pushgateway{label="value"} 117
EOF

cat <<EOF | curl --data-binary @- -XPOST http://localhost:9091/metrics/job/gitlab-ci/branch/main/project/prometheus
# HELP ci_pipeline_status Status of the latest CI/CD pipeline
# TYPE ci_pipeline_status gauge
ci_pipeline_status 1
# HELP ci_job_duration_seconds Duration of the CI/CD job in seconds
# TYPE ci_job_duration_seconds gauge
ci_job_duration_seconds 135
EOF
```
```shell
# Удаление метрик по группирующему ключу в Pushgateway 
# Pushgateway НЕ УДАЛЯЕТ метрики автоматически. Если они больше не нужны, это придется сделать вручную.
curl -XDELETE http://localhost:9091/metrics/job/gitlab-ci/branch/main/project/prometheus
```

### Логи последние 100 строк за последний час
```shell
podman compose logs -f --tail 100 --since 1h 
```