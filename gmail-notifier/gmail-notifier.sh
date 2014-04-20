#!/bin/bash
usage()
{
cat << EOF

Poll gmail for new email and use custom terminal-notifier build to display alerts

OPTIONS:
    -i      polling interval (in seconds, default 10)
    -k      keychain value with gmail details (defaults to "gmail")
    -c      disable notifications (cli mode) implies once and verbose
    -o      run once only
    -d      display delay before showing next of multiple notifications (default 3 seconds)
    -s      optional sound to play (form osx sound list, for example "Ping", defaults to no sound)
    -v      verbose mode
EOF
exit 1
}

while getopts "cd:k:i:hvos:" option
do
  case $option in
    c) CLI=1;VERBOSE=1;ONCE=1;;
    d) DISPLAY=$OPTARG;;
    i) INTERVAL=$OPTARG;;
    k) KEY=$OPTARG;;
    s) SOUND=$OPTARG;;
    o) ONCE=1;;
    v) VERBOSE=1;;
    h) usage;;
    *) usage;;
  esac
done

if [ -z "$KEY" ];then
  KEY="gmail"
fi

function keychain() {
  FAIL="security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain."
  VALUE=$(/usr/bin/security find-generic-password -s $1 -g 2>&1)
  if [ "$VALUE" != "$FAIL" ];then
    if [ "$2" == "account" ];then
      echo "$VALUE" | grep "acct" | cut -d \" -f 4
    elif [ "$2" == "password" ];then
      echo "$VALUE" | grep "password" | cut -d \" -f 2
    fi
  fi
}

USERNAME=$(keychain "$KEY" "account")
PASSWORD=$(keychain "$KEY" "password")

if [[ "$USERNAME" == "" || "$PASSWORD" == "" ]];then
  echo "fatal: keychain value not found"
  exit 1
fi

if [ -z "$INTERVAL" ];then
  INTERVAL=10
fi

if [ -z "$DISPLAY" ];then
  DISPLAY=3
fi

CACHE=''
IFS=$'\n'

# clean up message data
function sanitize(){
  # step 1 - replace html ampersands
  # step 2 - replace html single quotes with right single quotation mark
  # step 3 - replace html double quotes with double quotation
  # step 4 - replace single quote with right single quotation mark
  #          note that single quoted output is treated by bash as string literal (ie not interpreted)
  #          so replace single quotes with http://unicode-table.com/en/2019/ to avoid unexpected end of matching ' pairs
  echo "$1" | sed 's/&amp;/\&/g' | sed "s/&#39;/’/g" | sed 's/&quot;/\\"/g' | sed "s/'/’/g"
}

# extract data
function extract() {
  echo "$1" | sed -n -e "s/.*<$2>\(.*\)<\/$2>.*/\1/p"
}

function log(){
  if [ "$VERBOSE" == 1 ]; then
    echo $1
  fi
}

function check_messages() {
  # curl the messages feed and pull out the interesting data
  MESSAGES=$(curl -u $USERNAME:$PASSWORD --silent "https://mail.google.com/mail/feed/atom")
  count=$(extract "$MESSAGES" fullcount)
  if [ "$count" == "" ];then
    log "error: unable to retrieve feed"
  else
    NEW_CACHE=''
    if [ "$count" == "1" ];then
      log "$count message"
    else
      log "$count messages"
    fi
    MESSAGES=$(echo "$MESSAGES" | tr -d '\n' | awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}')
    for mail in ${MESSAGES[@]} ; do
      #echo "$mail"
      id=$(extract $mail id)
      cached=$(echo $CACHE | grep "$id" | wc -l | sed "s/ //g")
      if [ $cached == 0 ];then
        title=$(sanitize $(extract $mail title))
        summary=$(sanitize $(extract $mail summary))
        message=$(sanitize $(extract $mail message))
        #sender=$(sanitize $(extract $mail name))
        sender=$(sanitize $(echo "$mail" | sed -ne "s/.*<author><name>\(.*\)<\/name><email>.*<\/email><\/author>.*/\1/p"))
        link=$(echo "$mail" | sed -n -e 's/.*<link rel="alternate" href="\(.*\)&amp;extsrc=atom".*/\1/p')
        link=$(echo "${link}&extsrc=atom" | sed 's/&amp;/\&/g')
        exec='/Applications/gmail-notifier/gmail-notifier.app/Contents/MacOS/gmail-notifier'
        if [ ! -z "$SOUND" ];then
          exec="$exec -sound '$SOUND'"
        fi
        # note that single quoted output is treated by bash as string literal (ie not interpreted)
        cmd=$(echo $exec "-title '$sender' -subtitle '$title' -message '$summary' -open '$link'" )
        log "$sender - $title"
        if [ -z "$CLI" ];then
          eval $cmd > /dev/null
          sleep $DISPLAY
        fi
      else
        log "cache: \"$id\""
      fi
      NEW_CACHE+=$id
    done
    CACHE=$NEW_CACHE
  fi
}

if [ -z "$ONCE" ];then
  while true; do
    log "checking for messages on $USERNAME"
    check_messages
    log "`date`  (repeat in $INTERVAL seconds)"
    log "---"
    sleep $INTERVAL
  done
else
  log "checking for messages on $USERNAME"
  check_messages
  exit 0
fi
