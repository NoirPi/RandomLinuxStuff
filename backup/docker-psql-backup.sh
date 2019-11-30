#!/bin/bash
# Script fuer Datenbank Backups

### Einstellungen ##
BACKUPALTER="7"                                 ## loescht Backups, die aelter als X Tage sind
CRON='0 */6 * * *'
BACKUPDIR="/opt/postgres/backups/"              ## Pfad zum Speicherort der Backups auf dem Host
containers=(CONTAINERNAMES)                     ## Name oder ID des PostgreSQL Containers
DB_User=USERNAME                             ## Name des PostgreSQL SuperUsers
DB_Host=localhost                               ## Hostadresse des PostgreSQL Containers
DB_Port=5432                                    ## Port des PostgreSQL Containers
DB_Password=SECRET PASSWORD                   ## Password des PostgreSQL SuperUsers


echo "${DB_Host}:${DB_Port}:*:${DB_User}:${DB_Password}" > pgpass

for container in ${containers[*]}
    do
        docker cp pgpass $container:/root/.pgpass
        docker exec -u 0 -it $container chmod 600 /root/.pgpass
        docker exec -u 0 -it $container sh -c "pg_dumpall -U ${DB_User} -h ${DB_Host} -p ${DB_Port} --clean" > ${BACKUPDIR}/${container}_dump.$( date '+%F_%H:%M:%S' ).sql
    done

rm pgpass

# Erstellen eines Cronjobs fuer automatische Backups
CRON_FILE=/var/spool/cron/root
if [ -f "$FILE" ]; then
    :
else
  ME=$(basename -- "$0")
  echo "${CRON} bash ${PWD}/${ME}" >> $CRON_FILE
  /usr/bin/crontab $CRON_FILE
fi

### Loeschen der alten Backups ##
find "${BACKUPDIR}" -type f -mtime +"${BACKUPALTER}" -delete
