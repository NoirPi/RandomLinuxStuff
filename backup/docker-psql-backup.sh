#!/bin/bash
# Script for Database Backups

### Settings ##
MAXDAYS="X"              ## Automatically deletes Backups older then X Days
CRON='0 */X * * *'       ## crontab time settings
BACKUPDIR="Backup Path"  ## Path where the backups will be saved
containers=(MariaDB)     ## Comma separated list of database container names
DB_User=USERNAME         ## Database super user name
DB_Host=localhost        ## Database host address
DB_Port=5432             ## Database port
DB_Password=XYZ          ## Database super user password

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
find "${BACKUPDIR}" -type f -mtime +"${MAXDAYS}" -delete
rm "${PASS_FILE}" "${CRON_FILE}"

