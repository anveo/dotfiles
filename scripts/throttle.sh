#!/bin/sh
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

usage=$(
cat <<EOF
$0 [OPTIONS] start/stop
-s   set speed  default 256Kbit/s
-p   set port   default 3000
-d   set delay  default 350ms

EOF
)

PORT="3000"
DELAY="350ms"
SPEED="256Kbit/s"



while getopts  ":s:p:d:" opt ; do
  case $opt in
    s)
      SPEED="$OPTARG"
      ;;
    p)
      PORT="$OPTARG"
      ;;
    d)
      DELAY="$OPTARG"
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    \?)
      echo ""
      echo "$usage"
      exit 0
      ;;
  esac
done

# Makes the argument after all the options $1
shift $(($OPTIND - 1))

if [ "$1" != 'start' ] && [ "$1" != 'stop' ] ; then
        echo "$usage"
        exit 0
fi


if [ $1 = "start" ]; then
        echo "- Throttling $PORT to $SPEED with delay $DELAY"

        sudo ipfw pipe 1 config bw $SPEED delay $DELAY
        sudo ipfw add 100 pipe 1 src-port $PORT
        exit 0
fi

if [ $1 = "stop" ]; then
        echo "- Back to normal"

        sudo ipfw delete 100
        sudo ipfw pipe 1 delete
        exit 0
fi
