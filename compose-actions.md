### UI 
```shell
# prometheus
open http://localhost:9090/targets
# prometheus federation(prometheus который собирает метрики из другого prometheus)
open http://localhost:9099/targets

# grafana
# по умолчанию так и есть login: admin pass: admin
open http://localhost:3000

# pushgateway
open http://localhost:9091

# allertmanager общая ссылка
open http://localhost:9093
# notify от allertmanager по prometheus
open http://localhost:8888/prometheus-alerts
# notify от allertmanager по grafana
open http://localhost:8888/grafana-alerts
```

### Остановить и удалить + удалить volume с данными
```shell
podman compose down -v
podman ps -a
```
```shell
rm -rf ./grafana/image-mapped-folders/*
```

### Состояние
```shell
clear
podman ps -a
ps aux | grep '[c]ompose-generate-testdata' 
```

### Запускаем 
```shell
clear
podman compose up -d
podman ps -a
# включение доставки Grafana-managed alerts во внешний Alertmanager. Нужно подождать.
#  или можно вручную в настройках Home - Alerting - Settings - нажать Enable "prometheus-alertmanager-datasource"
chmod +x ./grafana/provisioning/datasources/setup-external-alertmanager.sh
./grafana/provisioning/datasources/setup-external-alertmanager.sh
```

### Генерация CSV файла. 
```shell
clear
chmod +x ./compose-generate-testdata.sh
OUTPUT_FILE=./grafana/public/testdata/live_metric.csv ./compose-generate-testdata.sh
```
```shell
# остановка генерации 
# ctrl+c 
# или ps aux и потом через kill -9 <pid>
clear
ps aux | grep '[c]ompose-generate-testdata' 
```

### Демонстрация Grafana Alerting
#### Включение доставки алертов во внешний Alertmanager
Если не включили при запуске. Включение доставки Grafana-managed alerts во внешний Alertmanager.
или можно вручную в настройках Home -> Alerting -> Settings -> нажать Enable "prometheus-alertmanager-datasource"
```shell
clear
chmod +x ./grafana/provisioning/datasources/setup-external-alertmanager.sh
./grafana/provisioning/datasources/setup-external-alertmanager.sh
```
#### Проверка включения "prometheus-alertmanager-datasource"
Можно вручную в настройках Home -> Alerting -> Settings -> нажать Enable "prometheus-alertmanager-datasource"
или проверить через интерфейс:
```shell
open http://localhost:3000/alerting/admin/alertmanager
```
#### Сделать Alert editable, если нужно.
```shell
clear
chmod +x ./compose-generate-testdata.sh
./grafana/provisioning/alerting/create-editable-nginx-alert.sh
```
#### Действия по алертам
```shell
# отключаем сервис
clear
podman stop nginx-exporter
podman ps -a --filter "name=nginx" --filter "status=exited"  --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```
```shell
# через пару минут в Grafana видим статус Firing 
open http://localhost:3000/alerting/grafana/nginx-exporter-down-grafana/view
```
```shell
# через пару минут в Prometheus видим статус Firing. ОТДЕЛЬНАЯ НАСТРОЙКА БЫЛА!
open http://localhost:8888/prometheus-alerts
```
```shell
# через пару минут в NTFY увидим уведомления от Alertmanager(Prometheus) и Grafana(Alert rules)
open http://localhost:8888/grafana-alerts
```
```shell
# вернуть нормальное состояние
clear
podman start nginx-exporter
podman ps -a --filter "name=nginx-exporter" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```
```shell
# через пару минут в Grafana видим статус Normal 
open http://localhost:3000/alerting/grafana/nginx-exporter-down-grafana/view
```
```shell
# через пару минут в Prometheus видим статус Normal. ОТДЕЛЬНАЯ НАСТРОЙКА БЫЛА!
open http://localhost:9090/alerts
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
