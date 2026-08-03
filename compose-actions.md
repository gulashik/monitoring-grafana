### UI 
```shell
# prometheus
open http://localhost:9090/targets
# prometheus service discovery 
open http://localhost:9090/service-discovery
# prometheus federation(prometheus который собирает метрики из другого prometheus)
open http://localhost:9099/targets

# grafana
# по умолчанию login: admin pass: admin
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
clear
podman compose down -v
rm -rf ./grafana/image-mapped-folders && mkdir ./grafana/image-mapped-folders
rm -rf ./grafana/ini-from-image && mkdir ./grafana/ini-from-image
podman ps -a
```

### Состояние
```shell
clear
podman ps -a 
ps aux | grep '[s]etup-external-alertmanager.sh' 
ps aux | grep '[c]ompose-generate-testdata' 
ps aux | grep '[i]nsert-metrics' 
ps aux | grep '[i]nsert-business-metrics' 
```
```shell
# остановка генерации если нужно
# ps aux и потом через kill -9 <pid> <pid>
clear
ps aux | grep '[c]ompose-generate-testdata' 
```

### Запускаем 
```shell
clear
podman compose --env-file ./config/.env up -d

# включение доставки Grafana-managed alerts во внешний Alertmanager.
#  или можно вручную в настройках Home - Alerting - Settings - нажать Enable "prometheus-alertmanager-datasource"
chmod +x ./grafana/provisioning/datasources/setup-external-alertmanager.sh
./grafana/provisioning/datasources/setup-external-alertmanager.sh

# включение автогенерации данных в таблицы БД Postgres
chmod +x ./postgres/generator/insert-metrics.sh
./postgres/generator/insert-metrics.sh &
chmod +x ./postgres/generator/insert-business-metrics.sh
./postgres/generator/insert-business-metrics.sh &

# генерация CSV файла
chmod +x ./compose-generate-testdata.sh
OUTPUT_FILE=./grafana/public/testdata/live_metric.csv ./compose-generate-testdata.sh &

# копируем grafana.ini если нужно будет увидеть его содержимое
podman cp grafana:/etc/grafana/grafana.ini ./grafana/ini-from-image/grafana.ini

podman ps -a
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

### Демонстрация Grafana Аннотации
### Аннотации в Grafana
Есть варианты подтягивания аннотаций в Grafana.
- Вручную — через интерфейс, просто кликнув на график.
- Автоматически через API — CI/CD системы, скрипты мониторинга или алерты сами отправляют аннотации при деплоях или срабатывании триггеров.
- Из источников данных — Grafana может подтягивать аннотации из Prometheus, Elasticsearch, InfluxDB и других источников на основе определённых запросов (например, события из логов).
- Из алертов — при срабатывании алерта Grafana может автоматически создать аннотацию.

#### Вручную
Ctrl/Cmd+click (или drag-select) на графике панели → откроется диалог "Add annotation".

#### Автоматически через API
```shell
# увидеть аннотации можно через API
curl -u admin:admin "http://localhost:3000/api/annotations" | jq
# фильтрация по тегу 
curl -u admin:admin "http://localhost:3000/api/annotations?tags=deploy" | jq
# фильтрация по типу 
curl -u admin:admin "http://localhost:3000/api/annotations?type=alert" | jq

```
Аннотации можно увидеть в dashboard-е `CSV read`
```shell
# одна линия 
clear
curl -u admin:admin \
  -H "Content-Type: application/json" \
  -X POST http://localhost:3000/api/annotations \
  -d '{
        "dashboardUID": "ad8whsx",
        "panelId": 1,
        "text": "CSV read: test annotation",
        "tags": ["csv", "manual", "api"],
        "time": '"$(($(date +%s%N)/1000000))"'
      }'
```
```shell
# диапазон 1 минута
clear
START_MS=$(($(date +%s%N)/1000000))
END_MS=$((START_MS + 1 * 60 * 1000))

curl -u admin:admin \
  -H "Content-Type: application/json" \
  -X POST http://localhost:3000/api/annotations \
  -d '{
        "dashboardUID": "ad8whsx",
        "panelId": 1,
        "text": "CSV read: event interval",
        "tags": ["csv", "manual", "api", "interval"],
        "time": '"$START_MS"',
        "timeEnd": '"$END_MS"'
      }'
```

#### Из источников данных
В dashboard-е `Mixed DB + CSV` будут аннотации
Создание
Grafana сама периодически перевыполняет этот запрос и рисует найденные строки как аннотации на графике.
В UI: открыть дашборд → Dashboard settings → Annotations → New query → Data source `grafana-postgresql-datasource`
Query:
```sql
SELECT
  measured_at AS time,
  'High CPU load: ' || cpu_load || '% (' || department || ')' AS text,
  ARRAY['cpu', department] AS tags
FROM grafana_demo_metrics
WHERE cpu_load > 90
ORDER BY measured_at
```

#### Из алертов


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
