#!/bin/bash
### BEGIN INIT INFO
# Provides:          test
# Required-Start:    $local_fs $network $named $time $syslog
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Test Service
### END INIT INFO

SCRIPTFILE="${BASH_SOURCE[0]}"
while [ -h "$SCRIPTFILE" ]; do # resolve $SCRIPTFILE until the file is no longer a symlink
	SCRIPTPATH="$( cd -P "$( dirname "$SCRIPTFILE" )" && pwd )"
	SCRIPTFILE="$(readlink "$SCRIPTFILE")"
	[[ $SCRIPTFILE != /* ]] && SCRIPTFILE="$SCRIPTPATH/$SCRIPTFILE" # if $SCRIPTFILE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPTPATH="$( cd -P "$( dirname "$SCRIPTFILE" )" && pwd )"

SCRIPTCMD="/home/ecuomo/Projects/arbs-poc/service-test/run.sh"
RUNAS="ecuomo"
NAME="test"

PIDPATH=/var/run
LOGPATH=/var/log
SERVICEPATH=/etc/init.d

PIDFILE=${PIDPATH}/${NAME}.pid
LOGFILE=${LOGPATH}/${NAME}.log
SERVICEFILE=${SERVICEPATH}/${NAME}

install() {
	echo "--- Installation ---"
	echo ""

	if [ -f $SERVICEFILE ]; then
		echo "Error! Service \"$NAME\" already exists!"
	else
		if [ ! -w $SERVICEPATH ] || [ ! -w $LOGPATH ] || [ ! -w $PIDPATH ]; then
			echo "You don't gave me enough permissions to install service myself."
			echo "That's smart, always be really cautious with third-party shell scripts!"
			echo "You should now type those commands as superuser to install and run your service:"
			echo ""
			echo "   cp \"$SCRIPTFILE\" \"$SERVICEFILE\""
			echo "   echo \"\" &>> \"$LOGFILE\""
			echo "   touch \"$LOGFILE\" && chown \"$RUNAS\" \"$LOGFILE\""
			echo "   update-rc.d \"$NAME\" defaults"
			echo "   service \"$NAME\" start"
		else
			echo "1. cp \"$SCRIPTFILE\" \"$SERVICEFILE\""
			cp -v "$SCRIPTFILE" "$SERVICEFILE"
			echo "2. echo \"\" &>> \"$LOGFILE\""
			echo "" &>> "$LOGFILE"
			echo "3. touch \"$LOGFILE\" && chown \"$RUNAS\" \"$LOGFILE\""
			touch "$LOGFILE" && chown "$RUNAS" "$LOGFILE"
			echo "4. update-rc.d \"$NAME\" defaults"
			update-rc.d "$NAME" defaults
			echo "5. service \"$NAME\" start"
			service "$NAME" start
		fi
	fi

	echo ""
	echo "---Uninstall instructions ---"
	echo "The service can uninstall itself:"
	echo "    service \"$NAME\" uninstall"
	echo "It will simply run update-rc.d -f \"$NAME\" remove && rm -f \"$SERVICEFILE\""
	echo ""
	echo "--- Terminated ---"
}

start() {
	if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE); then
		echo 'Service already running' >&2
		return 1
	fi
	echo 'Starting service…' >&2
	local CMD="$SCRIPTCMD &> \"$LOGFILE\" & echo \$!"
	su -c "$CMD" $RUNAS > "$PIDFILE"
	echo 'Service started' >&2
}

stop() {
	if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE"); then
		echo 'Service not running' >&2
		return 1
	fi
	echo 'Stopping service…' >&2
	kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"
	echo 'Service stopped' >&2
}

uninstall() {
	if [ ! -w $SERVICEFILE ] || [ ! -w $LOGFILE ] || [ ! -w $PIDFILE ]; then
		echo "Error! You didn't give me enough permissions to uninstall service myself."
	else
		echo -n "Are you really sure you want to uninstall this service? That cannot be undone. [yes|No] "
		local SURE
		read SURE
		if [ "$SURE" = "yes" ]; then
			stop
			rm -f "$PIDFILE"
			echo "Notice: log file was not removed: '$LOGFILE'" >&2
			update-rc.d -f $NAME remove
			rm -fv "$SERVICEFILE"
		fi
	fi
}

status() {
	printf "%-50s" "Checking $NAME..."
	if [ -f $PIDFILE ]; then
		PID=$(cat $PIDFILE)
		if [ -z "$(ps axf | grep ${PID} | grep -v grep)" ]; then
			printf "%s\n" "The process appears to be dead but pidfile still exists"
		else
			echo "Running, the PID is $PID"
		fi
	else
		printf "%s\n" "Service not running"
	fi
}


case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	status)
		status
		;;
	install)
		install
		;;
	uninstall)
		uninstall
		;;
	restart)
		stop
		start
		;;
	*)

	echo "Usage: $SCRIPTFILE {start|stop|status|restart|install|uninstall}"
esac
