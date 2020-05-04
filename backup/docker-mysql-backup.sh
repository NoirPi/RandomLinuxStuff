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
find "${BACKUPDIR}" -type f -mtime +"${MAXDAYS}" -delete
rm "${CRON_FILE}"
