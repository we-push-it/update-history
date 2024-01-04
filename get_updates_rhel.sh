#!/bin/bash

# Standardmäßig 30 Tage zurück, falls kein Argument übergeben wird
days=${1:-30}

# Das Enddatum für die Suche berechnen (heute minus die angegebenen Tage)
end_date=$(date -d "-$days days" +"%Y-%m-%d")

echo "YUM-Updates seit $end_date:"

# Die Yum-Historie auslesen und Zeilen bearbeiten
yum history 2> /dev/null | while IFS='|' read -r id_line; do
    # Extrahiere ID und Datum aus der Zeile
    id=$(echo "$id_line" | awk '{print $1}')
    trans_date=$(echo "$id_line" | awk -F '|' '{print $3}' | awk '{print $1}')

    # Überprüfe, ob die Zeile eine gültige Transaktions-ID und ein Datum enthält
    if [[ $id =~ ^[0-9]+$ ]] && [[ $trans_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # Prüfe, ob das Datum der Transaktion größer als oder gleich dem Enddatum ist
        if [[ $trans_date > $end_date || $trans_date == $end_date ]]; then
            # Extrahiere und formatiere die Informationen der Transaktion
            yum history info "$id"  2> /dev/null | awk -v trans_date="$trans_date" '
            /Packages Altered:/ {print_flag=1; next}
            /Transaction performed with:/ {print_flag=0}
            print_flag && !/^$/ {
                gsub(/^[ \t]+|[ \t]+$/, "", $0);  # Entferne führende und abschließende Leerzeichen
                gsub(/[ \t]{2,}/, " ");          # Ersetze mehrfache Leerzeichen und Tabs durch ein Leerzeichen
                printf "%s %s; ", trans_date, $0  # Füge Datum hinzu und trenne Einträge mit Semikolon
            }
            END {if (print_flag) print ""}'
        fi
    fi
done
