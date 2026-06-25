# Generate Grafana datasource

## Получаем текущую информацию из datasources 
```shell
clear
# согласно настроек compose.yml
curl -u admin:admin http://localhost:3000/api/datasources | jq 
# или по uid
# curl -u admin:admin http://localhost:3000/api/datasources/<uid>/prometheus | jq
```
## Результат запроса
```json
[
  {
    "id": 2,
    "uid": "ffq7bvja2gsu8d",
    "orgId": 1,
    "name": "grafana-postgresql-datasource",
    "type": "grafana-postgresql-datasource",
    "typeName": "PostgreSQL",
    "typeLogoUrl": "public/app/plugins/datasource/grafana-postgresql-datasource/img/postgresql_logo.svg",
    "access": "proxy",
    "url": "postgres-metrics-db:5432",
    "user": "postgres",
    "database": "",
    "basicAuth": false,
    "isDefault": false,
    "jsonData": {
      "connMaxLifetime": 14400,
      "database": "metrics_db",
      "maxIdleConns": 100,
      "maxIdleConnsAuto": true,
      "maxOpenConns": 100,
      "postgresVersion": 1700,
      "sslmode": "disable"
    },
    "readOnly": false
  },...
]
```

## Собираем в ручную со всеми полями в datasources.yml
Важные значения:
Модификация:
    editable: true
    jsonData: много интересного
Пароли
    secureJsonData:
        password: пароль
```yaml
apiVersion: 1

datasources:
  - name: grafana-postgresql-datasource
    type: postgres
    uid: ffq7bvja2gsu8d
    typeName: PostgreSQL
    access: proxy
    url: postgres-metrics-db:5432
    user: postgres
    isDefault: false
    editable: true
    jsonData:
      connMaxLifetime: 14400
      database: metrics_db
      maxIdleConns: 100
      maxIdleConnsAuto: true
      maxOpenConns: 100
      sslmode: disable
    secureJsonData:
      password: postgres
```

