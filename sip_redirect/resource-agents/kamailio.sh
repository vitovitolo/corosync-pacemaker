#!/bin/sh
#
#
# kamailio
#
# Description:        Manages kamailio as Linux-HA resource
#
# Authors:        https://github.com/vitovitolo
#
#
#######################################################################
# Initialization:
: ${OCF_FUNCTIONS_DIR=${OCF_ROOT}/lib/heartbeat}
. ${OCF_FUNCTIONS_DIR}/ocf-shellfuncs

#######################################################################

# Initialization:

. /usr/lib/ocf/resource.d/heartbeat/.ocf-shellfuncs

#Load defaults vars
. /etc/default/kamailio
#Set specific vars for start and stop daemon
DAEMON=/usr/sbin/kamailio
CFGFILE=/etc/kamailio/kamailio.cfg
PIDFILE=/var/run/kamailio/kamailio.pid
SHM_MEMORY=$((`echo $SHM_MEMORY | sed -e 's/[^0-9]//g'`))
PKG_MEMORY=$((`echo $PKG_MEMORY | sed -e 's/[^0-9]//g'`))
[ $SHM_MEMORY -le 0 ] && SHM_MEMORY=64
[ $PKG_MEMORY -le 0 ] && PKG_MEMORY=4
[ -z "$USER" ]  && USER=kamailio
[ -z "$GROUP" ] && GROUP=kamailio

if [ "$SSD_SUID" != "yes" ]; then
	OPTIONS="-f $CFGFILE -P $PIDFILE -m $SHM_MEMORY -M $PKG_MEMORY -u $USER -g $GROUP"
        SSDOPTS=""
else
        OPTIONS="-f $CFGFILE -P $PIDFILE -m $SHM_MEMORY -M $PKG_MEMORY"
        SSDOPTS="--chuid $USER:$GROUP"
fi




usage() {
	cat <<-!
		usage: $0 {start|stop|status|monitor|meta-data|validate-all}
	!
}

meta_data() {
cat <<END
<?xml version="1.0" ?>
<!DOCTYPE resource-agent SYSTEM "ra-api-1.dtd">
  <resource-agent name="kamailio">
  <version>1.0</version>

  <longdesc lang="en">
   Resource Agent for the kamailio SIP Proxy.
  </longdesc>
  <shortdesc lang="en">kamailio resource agent</shortdesc>

  <parameters>
   <parameter name="ip" unique="0" required="1">
    <longdesc lang="en">
      IP Address of the kamailio Instance. This is only used for monitoring.
    </longdesc>
    <shortdesc lang="en">IP Address</shortdesc>
    <content type="string" default="" />
   </parameter>

   <parameter name="port" unique="0" required="1">
    <longdesc lang="en">
     Port of the kamailio Instance. This is only used for monitoring.
    </longdesc>
    <shortdesc lang="en">Port</shortdesc>
    <content type="string" default="5060" />
   </parameter>

  </parameters>

 <actions>
   <action name="start" timeout="30" />
   <action name="stop" timeout="30" />
   <action name="status" timeout="30" />
<action name="monitor" timeout="30s" depth="0" interval="10s" />
<action name="monitor" timeout="30s" depth="10" interval="30s" />
<action name="monitor" timeout="45s" depth="20" />
<action name="monitor" timeout="60s" depth="30" />
   <action name="meta-data" timeout="5" />
   <action name="validate-all" timeout="5" />
 </actions>
</resource-agent>
END
}

kamailio_Status() {
	local rc
	/usr/bin/sipp 127.0.0.1 -timeout 10 -sf /etc/zabbix-agent.d/xml/OPTIONS_recv_200.xml -m 1 > /dev/null 2>&1
	rc=$?
	if
	[ $rc -ne 0 ]
	then
		ocf_log info "OCF KAMAILIO_STATUS: Kamailio monitor has failed. Sipp return $rc code."
		return $OCF_NOT_RUNNING
	fi
	ocf_log info "OCF KAMAILIO_STATUS: Kamailio monitor OK."
	return $OCF_SUCCESS
}

kamailio_Monitor() {
	kamailio_Status
}

kamailio_Start() {
        local rc

        kamailio_Status
        rc=$?

        if [ $rc -eq $OCF_SUCCESS ]; then
              	return $rc
        fi

	start-stop-daemon --start --quiet --pidfile $PIDFILE $SSDOPTS --exec $DAEMON -- $OPTIONS
        rc=$?

        if [ $rc -ne 0 ]; then
                return $OCF_NOT_RUNNING
        fi

        return $OCF_SUCCESS

}

kamailio_Stop() {
        local rc

        kamailio_Status
        rc=$?

        if [ $rc -ne $OCF_SUCCESS ]; then
                return $OCF_SUCCESS
        fi

	start-stop-daemon --oknodo --stop --quiet --pidfile $PIDFILE --exec $DAEMON
        rc=$?

        if [ $rc -ne 0 ]; then
                return $OCF_ERR_GENERIC
        fi

        return $OCF_SUCCESS
}

kamailio_Validate_All() {
	return $OCF_SUCCESS
}

if [ $# -ne 1 ]; then
	usage
	exit $OCF_ERR_ARGS
fi

case $1 in
	meta-data) meta_data
		exit $OCF_SUCCESS
		;;
	start) kamailio_Start
		;;
	stop) kamailio_Stop
		;;
	monitor) kamailio_Monitor
		;;
	status) kamailio_Status
		;;
	validate-all) kamailio_Validate_All
		;;
	usage) usage
		exit $OCF_SUCCESS
		;;
	*) usage
		exit $OCF_ERR_UNIMPLEMENTED
		;;
esac
