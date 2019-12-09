#!/bin/bash
# Script fuer Datenbank Backups

### Einstellungen ##
BACKUPALTER="7"                                 ## loescht Backups, die aelter als X Tage sind
CRON='0 */6 * * *'
BACKUPDIR="Backup Path"                      ## Pfad zum Speicherort der Backups auf dem Host
containers=(MariaDB)
DB_User=USERNAME
DB_Host=localhost
DB_Port=5432
DB_Password=SECRETPASSWORD


### Erstellen temporaerer Dateien ###
CRON_FILE=$(mktemp /var/spool/cron/root.XXXXXX)

#TODO Add host and port to mysqldump command (actually untested)

for container in ${containers[*]}
    do
        docker exec -u 0 -it "${container}" sh -c "exec mysqldump --all-databases -u'${DB_User}' -p'${DB_Password}'" > "${BACKUPDIR}"/"${container}"_dump."$( date '+%F_%H:%M:%S' )".sql
    done

### Erstellen eines Cronjobs für automatische Backups ###
ME=$(basename -- "$0")
crontab -l > "${CRON_FILE}" && grep -xF "${CRON} ${PWD}/${ME}" "${CRON_FILE}" || echo "${CRON} ${PWD}/${ME}" >> "${CRON_FILE}" && /usr/bin/crontab "${CRON_FILE}"

### Loeschen der alten Backups und temporaerer Files ##
find "${BACKUPDIR}" -type f -mtime +"${BACKUPALTER}" -delete
rm "${CRON_FILE}"
