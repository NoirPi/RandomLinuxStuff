#!/bin/bash
# Script fuer inkrementelles Backup mit 7 taegigem Vollbackup

### Einstellungen ##
BACKUPNAME="Backup"                             ## Name der Backupdatei. Datum wird automatisch angehangen
BACKUPALTER="7"                                 ## loescht Backups, die aelter als X Tage sind
BACKUPDIR="/root/backup/backups"                ## Pfad zum Speicherort der Backups
TIMESTAMP="timestamp.dat"                       ## Zeitstempel. Benoetigt fuer inkrementelles Backup
CRON='0 4 * * *'
## Verzeichnis(se) welche(s) gesichert werden soll(en)
SOURCE="/etc /home /opt /var/log /var/www"
DATUM="$(date +%Y-%m-%d)"                       ## Datumsformat einstellen
STARTZEIT="$(date +%H:%M:%S)"                   ## Uhrzeitformat einstellen
wochentag="$(date +%w)"                         ## gibt den aktuellen Wochentag aus
EMAILEMPFAENGER="admin@example.com"           ## Email, an die ein Bericht gesendet wird
EMAILSENDER="backup@example.com"

### RSYNC Einstellungen
SYNC="1"                                        ## Boolean 0=inactive / 1=active
SYNC_HOST="example.com"                         ## Sync Host adresse
SYNC_PATH="/home/serverbackup/safebackup/test"  ## Pfad zum speichern auf dem Sync Host
SYNC_USER="safebackups"                         ## User fuer Verbindung zum Sync Host

### Verzeichnisse/Dateien welche nicht gesichert werden sollen ! Achtung keinen Zeilenumbruch ! ##
EXCLUDE="--exclude=/root/backup/backups"


### Wechsel in root damit die Pfade stimmen ##
cd /

### Backupverzeichnis anlegen ##
mkdir -p ${BACKUPDIR}

### Test ob Backupverzeichnis existiert und Mail an Admin bei fehlschlagen ##
if [ ! -d "${BACKUPDIR}" ]; then

mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backupverzeichnis nicht vorhanden!" "${EMAILEMPFAENGER}" <<EOM
Hallo Admin,
das Backup am ${DATUM} konnte nicht erstellt werden. Das Verzeichnis ${BACKUPDIR} wurde nicht gefunden und konnte auch nicht angelegt werden.
EOM

 . exit 1
fi

filename=${BACKUPNAME}-${DATUM}-${STARTZEIT}.tgz


### ueberpruefen, ob FullBackup gemacht wird. 1 = Montag, 2 = Dienstag, ...##
if [ "$wochentag" = '1' ]; then
        tar --listed-incremental=${BACKUPDIR}/${TIMESTAMP} ${EXCLUDE} --level=0 -cpzf ${BACKUPDIR}/${filename} ${SOURCE}
else
        tar --listed-incremental=${BACKUPDIR}/${TIMESTAMP} ${EXCLUDE} -cpzf ${BACKUPDIR}/${filename} ${SOURCE}
fi


### Enddatum erfassen ###
ENDZEIT="$(date +%H:%M:%S)"

### Abfragen ob das Backup erfolgreich war ##
if [ $? -ne 0 ]; then

mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backup war fehlerhaft!" "${EMAILEMPFAENGER}"  <<EOM
Hallo Admin,
das Backup ${filename} am ${DATUM} wurde mit Fehler(n) beendet.
EOM
 . exit 1
else

### Dateigroesse ermitteln ###
GROESSE="$(du -sh ${BACKUPDIR}/"${filename}")"

###RSync muss explizit eingerichtet und hier angepasst werden.
if [ ${SYNC} = '1' ]; then
    rsync -avze ssh ${BACKUPDIR}/"${filename}" ${SYNC_USER}@${SYNC_HOST}:${SYNC_PATH} --log-file=${BACKUPDIR}/rsync.log
	# rsync -v -e ssh /var/www/backups/${filename} safebackups@noir.goip.de:/home/serverbackup/safebackup
	if [ $? -eq 0 ]; then
		mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backup war erfolgreich" "${EMAILEMPFAENGER}"  <<EOF
Hallo Admin,
das Backup wurde erfolgreich erstellt.

----------------Details--------------------
Name:           ${filename}
Datum:          ${DATUM}
Startzeit:      ${STARTZEIT}
Endzeit:        ${ENDZEIT}
Dateigroesse:   ${GROESSE}
Speicherort:    ${SYNC_PATH}/${filename}
EOF
		rm ${BACKUPDIR}/rsync.log
	else
	  mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backup war fehlerhaft!" "${EMAILEMPFAENGER}"  < ${BACKUPDIR}/rsync.log
	  rm ${BACKUPDIR}/rsync.log
	fi
else
	mailx -a "From: $(hostname) Backup <${EMAILSENDER}>" -s "$(hostname) Backup | Backup war erfolgreich" "${EMAILEMPFAENGER}"  <<EOF
Hallo Admin,
das Backup wurde erfolgreich erstellt.

----------------Details--------------------
Name:           ${filename}
Datum:          ${DATUM}
Startzeit:      ${STARTZEIT}
Endzeit:        ${ENDZEIT}
Dateigroesse:   ${GROESSE}
EOF
fi


fi

# Erstellen eines Cronjobs für automatische Backups
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