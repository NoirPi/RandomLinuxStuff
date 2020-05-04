#!/bin/bash
# Script for incremental Backups with full backups every 7 days

### Einstellungen ##
BACKUPNAME="Backup"                             ## Name Suffix for the Backup Files
MAXDAYS="7"                                     ## Automatically deletes Backups older then X Days
BACKUPDIR="/root/backup/backups"                ## Path where the backups will be saved
TIMESTAMP="timestamp.dat"                       ## Timestamp! Needed for incremental Backups
CRON='0 4 * * *'                                ## crontab time settings
SOURCE="/etc /home /opt /var/log /var/www"      ## Folders to backup

### Times
DATE="$(date +%Y-%m-%d)"                        ## Dateformat
STARTTIME="$(date +%H:%M:%S)"                   ## Timeformat
day_of_week="$(date +%w)"                       ## Actual day of the week

### EMAIL Settings
EMAILRECIPIENT="admin@example.com"              ## Email, where the report will be sended to
EMAILSENDER="backup@example.com"                ## Email, where the report will be sended from

### RSYNC Settings
SYNC="1"                                        ## Boolean 0=inactive / 1=active
SYNC_HOST="example.com"                         ## Sync Host adress
SYNC_PATH="/home/serverbackup/safebackup/test"  ## Path where the backups will be saved on the sync host
SYNC_USER="safebackups"                         ## Username for the sync host

### Folders which will not be backuped! IMPORTANT no newline!!!
EXCLUDE="--exclude=/root/backup/backups"


### Wechsel in root damit die Pfade stimmen ##
cd /

### Backupverzeichnis anlegen ##
mkdir -p ${BACKUPDIR}

### Test ob Backupverzeichnis existiert und Mail an Admin bei fehlschlagen ##
if [[ ! -d "${BACKUPDIR}" ]]; then

mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backupverzeichnis nicht vorhanden!" "${EMAILRECIPIENT}" <<EOM
Hallo Admin,
das Backup am ${DATE} konnte nicht erstellt werden. Das Verzeichnis ${BACKUPDIR} wurde nicht gefunden und konnte auch nicht angelegt werden.
EOM

 . exit 1
fi

filename=${BACKUPNAME}-${DATE}-${STARTTIME}.tgz


### ueberpruefen, ob FullBackup gemacht wird. 1 = Montag, 2 = Dienstag, ...##
if [[ "$day_of_week" = '1' ]]; then
        tar --listed-incremental=${BACKUPDIR}/${TIMESTAMP} ${EXCLUDE} --level=0 -cpzf ${BACKUPDIR}/"${filename}" "${SOURCE}"
else
        tar --listed-incremental=${BACKUPDIR}/${TIMESTAMP} ${EXCLUDE} -cpzf ${BACKUPDIR}/"${filename}" "${SOURCE}"
fi


### Enddatum erfassen ###
ENDZEIT="$(date +%H:%M:%S)"

### Abfragen ob das Backup erfolgreich war ##
if [[ $? -ne 0 ]]; then

mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backup war fehlerhaft!" "${EMAILRECIPIENT}"  <<EOM
Hallo Admin,
das Backup ${filename} am ${DATE} wurde mit Fehler(n) beendet.
EOM
 . exit 1
else

### Dateigroesse ermitteln ###
GROESSE="$(du -sh ${BACKUPDIR}/"${filename}")"

###RSync muss explizit eingerichtet und hier angepasst werden.
if [[ ${SYNC} = '1' ]]; then
    rsync -avze ssh ${BACKUPDIR}/"${filename}" ${SYNC_USER}@${SYNC_HOST}:${SYNC_PATH} --log-file=${BACKUPDIR}/rsync.log
	# rsync -v -e ssh /var/www/backups/${filename} safebackups@noir.goip.de:/home/serverbackup/safebackup
	if [[ $? -eq 0 ]]; then
		mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backup war erfolgreich" "${EMAILRECIPIENT}"  <<EOF
Hallo Admin,
das Backup wurde erfolgreich erstellt.

----------------Details--------------------
Name:           ${filename}
Datum:          ${DATE}
Startzeit:      ${STARTTIME}
Endzeit:        ${ENDZEIT}
Dateigroesse:   ${GROESSE}
Speicherort:    ${SYNC_PATH}/${filename}
EOF
		rm ${BACKUPDIR}/rsync.log
	else
	  mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backup war fehlerhaft!" "${EMAILRECIPIENT}"  < ${BACKUPDIR}/rsync.log
	  rm ${BACKUPDIR}/rsync.log
	fi
else
	mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backup war erfolgreich" "${EMAILRECIPIENT}"  <<EOF
Hallo Admin,
das Backup wurde erfolgreich erstellt.

----------------Details--------------------
Name:           ${filename}
Datum:          ${DATE}
Startzeit:      ${STARTTIME}
Endzeit:        ${ENDZEIT}
Dateigroesse:   ${GROESSE}
EOF
fi


fi

### Erstellen eines Cronjobs für automatische Backups ###
CRON_FILE=$(mktemp /var/spool/cron/root.XXXXXX)
ME=$(basename -- "$0")
crontab -l > "${CRON_FILE}" && grep -xF "${CRON} ${PWD}/${ME}" "${CRON_FILE}" || echo "${CRON} ${PWD}/${ME}" >> "${CRON_FILE}" && /usr/bin/crontab "${CRON_FILE}"

### Loeschen der alten Backups ##
find "${BACKUPDIR}" -type f -mtime +"${MAXDAYS}" -delete