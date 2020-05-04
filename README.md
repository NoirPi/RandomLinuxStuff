# Backup:

### Docker-MySQL-backup.sh
#### Settings:
```
MAXDAYS="X"              ## Automatically deletes Backups older then X Days
CRON='0 */X * * *'       ## crontab time settings
BACKUPDIR="Backup Path"  ## Path where the backups will be saved
containers=(MariaDB)     ## Comma separated list of database container names
DB_User=USERNAME         ## Database super user name
DB_Host=localhost        ## Database host address
DB_Port=5432             ## Database port
DB_Password=XYZ          ## Database super user password
```

### Docker-PSQL-backup.sh
#### Settings:
```
MAXDAYS="X"              ## Automatically deletes Backups older then X Days
CRON='0 */X * * *'       ## crontab time settings
BACKUPDIR="Backup Path"  ## Path where the backups will be saved
containers=(MariaDB)     ## Comma separated list of database container names
DB_User=USERNAME         ## Database super user name
DB_Host=localhost        ## Database host address
DB_Port=5432             ## Database port
DB_Password=XYZ          ## Database super user password
```

### inkremental-backup.sh
#### Settings:
```
BACKUPNAME="Backup"                             ## Name Suffix for the Backup Files
MAXDAYS="X"                                     ## Automatically deletes Backups older then X Days
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
```

# Basics:
### hostname.sh
##### Usage:
```
/bin/sh hostname.sh <new_hostname>
```

### certbot-cloudflare.sh
#### Settings:
```
CLOUDFLARE_EMAIL="admin@example.com"            ## Cloudflare Login Email
CLOUDFLARE_API_KEY="put-your-key-here"          ## Cloudflare API Key
CLOUDFLARE_CONFIG_PATH="/etc/letsencrypt"       ## Cloudflare Config Path
DOMAIN="example.com"                            ## Domain
OS_PACKAGE_COMMAND="apt install -y"             ## os command to install packages (apt, yum)
```
