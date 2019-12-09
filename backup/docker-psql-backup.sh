#!/bin/bash
# Script fuer Datenbank Backups

### Einstellungen ##
BACKUPALTER="7"                                 ## loescht Backups, die aelter als X Tage sind
CRON='0 */6 * * *'                            ## Crontab Zeit
BACKUPDIR="Path/to/backupfolder"              ## Pfad zum Speicherort der Backups auf dem Host
containers=(CONTAINERNAMES)                     ## Name oder ID des PostgreSQL Containers
DB_User=USERNAME                             ## Name des PostgreSQL SuperUsers
DB_Host=localhost                               ## Hostadresse des PostgreSQL Containers
DB_Port=5432                                    ## Port des PostgreSQL Containers
DB_Password=SECRETPASSWORD                   ## Password des PostgreSQL SuperUsers

### Erstellen temporaerer Dateien ###
PASS_FILE=$(mktemp "${PWD}"/pass.XXXXXX)
CRON_FILE=$(mktemp /var/spool/cron/root.XXXXXX)

### Create passfile ###
echo "${DB_Host}:${DB_Port}:*:${DB_User}:${DB_Password}" > "${PASS_FILE}"

### Kopiere Passfile und erstelle Dump ###
for container in ${containers[*]}
    do
        docker cp "${PASS_FILE}" "${container}":/root/.pgpass && docker exec -u 0 -it "${container}" chmod 600 /root/.pgpass
        docker exec -u 0 -it "${container}" sh -c "pg_dumpall -U ${DB_User} -h ${DB_Host} -p ${DB_Port} --clean" > "${BACKUPDIR}"/"${container}"_dump."$( date '+%F_%H:%M:%S' )".sql
    done

### Erstellen eines Cronjobs für automatische Backups ###
ME=$(basename -- "$0")
crontab -l > "${CRON_FILE}" && grep -xF "${CRON} ${PWD}/${ME}" "${CRON_FILE}" || echo "${CRON} ${PWD}/${ME}" >> "${CRON_FILE}" && /usr/bin/crontab "${CRON_FILE}"


### Loeschen der alten Backups und temporaerer Files ##
find "${BACKUPDIR}" -type f -mtime +"${BACKUPALTER}" -delete
rm "${PASS_FILE}" "${CRON_FILE}"

