#!/bin/bash

# Standardmäßig 30 Tage zurück, falls kein Argument übergeben wird
days=${1:-30}

# Das Startdatum für die Suche berechnen (heute minus die angegebenen Tage)
start_date=$(date -d "-$days days" +"%Y-%m-%d")

echo "APT-Updates seit $start_date:"

# Alle regulären und gzip-komprimierten Log-Dateien durchsuchen
for file in /var/log/apt/history.log /var/log/apt/history.log.*.gz; do
    if [[ -f $file ]]; then
        # Verwende zcat für komprimierte und cat für reguläre Dateien
        cat_cmd='cat'
        [[ $file == *.gz ]] && cat_cmd='zcat'

        # Variable zum Speichern des aktuellen Logblocks
        log_block=""
        start_printing=false

        # Lese jede Zeile der Datei
        $cat_cmd "$file" | while read -r line; do
            # Wenn eine neue Transaktion beginnt
            if [[ $line =~ ^Start-Date:\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
                # Drucke den vorherigen Logblock, falls relevant
                if [[ $start_printing == true ]]; then
                    echo "$log_block" | tr '\n' ' ' | sed -e 's/Commandline: [^ ]* //' -e 's/Start-Date: //'
                    echo
                fi
                log_block="${BASH_REMATCH[1]}" # Starte einen neuen Logblock mit dem Datum
                start_printing=false # Setze Drucken zurück

                # Überprüfe das Transaktionsdatum
                if [[ ${BASH_REMATCH[1]} > $start_date || ${BASH_REMATCH[1]} == $start_date ]]; then
                    start_printing=true
                fi
            else
                # Füge die Zeile zum aktuellen Logblock hinzu, außer es ist eine End-Date oder Commandline Zeile
                if ! [[ $line =~ ^End-Date: || $line =~ ^Commandline: ]]; then
                    log_block="$log_block"$'\n'"$line"
                fi
            fi
        done

        # Drucke den letzten Logblock, falls relevant
        if [[ $start_printing == true ]]; then
            echo "$log_block" | tr '\n' ' ' | sed -e 's/Commandline: [^ ]* //' -e 's/Start-Date: //'
            echo
        fi
    fi
done
