#!/usr/bin/env bash
#
# ---------------------
# Бесконечно, раз в секунду, генерирует данные (random walk) и пишет их
# в CSV-файл для использования в Grafana TestData datasource,
# сценарий "CSV File".
#
# Формат CSV: time,value
#   time  — unix-время в секундах (Grafana распознаёт колонку "time"
#           как временную ось)
#   value — псевдослучайное целое число (random walk в диапазоне
#           [MIN_VALUE; MAX_VALUE])
#
# ВАЖНО про TestData "CSV File":
#   Этот сценарий читает файлы из директории
#     <StaticRootPath>/testdata
#   внутри контейнера Grafana (обычно /usr/share/grafana/public/testdata/).
#   Поэтому OUTPUT_FILE должен указывать либо прямо туда (если скрипт
#   запускается внутри контейнера/на хосте с смонтированным томом),
#   либо на путь на хосте, который вы примонтировали в этот каталог
#
# Использование:
#   chmod +x generate_testdata.sh
#   ./generate_testdata.sh
#
#   Настройки можно переопределить через переменные окружения:
#   OUTPUT_FILE=./grafana/testdata/live_metric.csv INTERVAL=1 \
#   MAX_POINTS=3600 MIN_VALUE=0 MAX_VALUE=100 STEP=3 ./generate_testdata.sh
#
# Остановка: Ctrl+C

#  “строгий режим” Bash — скрипт будет быстрее падать при ошибках и меньше скрывать проблемы
set -euo pipefail

# ---------- Настройки ----------
OUTPUT_FILE="${OUTPUT_FILE:-./grafana/public/testdata/live_metric.csv}"  # путь к CSV
INTERVAL="${INTERVAL:-1}"          # период генерации, сек
MAX_POINTS="${MAX_POINTS:-3600}"   # сколько последних точек хранить (скользящее окно)
MIN_VALUE="${MIN_VALUE:-0}"
MAX_VALUE="${MAX_VALUE:-100}"
STEP="${STEP:-3}"                  # максимальный шаг изменения значения за тик

# mkdir -p "$(dirname "$OUTPUT_FILE")"

# ---------- Инициализация ----------
# заново файл
current_value=$(( (MIN_VALUE + MAX_VALUE) / 2 ))
echo "time,value" > "$OUTPUT_FILE"

#if [[ ! -f "$OUTPUT_FILE" ]] || [[ "$(wc -l < "$OUTPUT_FILE")" -le 1 ]]; then
#    echo "time,value" > "$OUTPUT_FILE"
#    current_value=$(( (MIN_VALUE + MAX_VALUE) / 2 ))
#else
#    current_value=$(tail -n 1 "$OUTPUT_FILE" | cut -d',' -f2)
#    if ! [[ "$current_value" =~ ^-?[0-9]+$ ]]; then
#        current_value=$(( (MIN_VALUE + MAX_VALUE) / 2 ))
#    fi
#fi

echo "Пишу данные в: $OUTPUT_FILE (интервал: ${INTERVAL}с, Ctrl+C — остановить)"

trap 'echo; echo "Остановлено."; exit 0' INT TERM

# ---------- Основной цикл ----------
while true; do
    # случайное изменение значения в диапазоне [-STEP; +STEP]
    delta=$(( (RANDOM % (2 * STEP + 1)) - STEP ))
    current_value=$(( current_value + delta ))

    # ограничиваем значение заданным диапазоном
    if (( current_value < MIN_VALUE )); then current_value=$MIN_VALUE; fi
    if (( current_value > MAX_VALUE )); then current_value=$MAX_VALUE; fi

    ts=$(date +%s)

    # Атомарная перезапись файла: собираем новый файл во временном,
    # затем переименовываем — чтобы Grafana не прочитала файл в момент записи.
    {
        echo "time,value"
        tail -n +2 "$OUTPUT_FILE" 2>/dev/null | tail -n "$((MAX_POINTS - 1))"
        echo "${ts},${current_value}"
    } > "${OUTPUT_FILE}.tmp"

    mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

    sleep "$INTERVAL"
done
