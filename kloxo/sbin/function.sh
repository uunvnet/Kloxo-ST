#!/bin/sh

__path_php_path="/usr/bin/lxphp.exe";

__path_program_root="/usr/local/lxlabs/${progname}";
__path_slave_db="/usr/local/lxlabs/${progname}/etc/conf/slave-db.db";

if [ -f /usr/local/lxlabs/kloxo/sbin/custom.${progname}.php ] ; then
	__path_server_path="/usr/local/lxlabs/kloxo/sbin/custom.${progname}.php";
else
	__path_server_path="/usr/local/lxlabs/kloxo/sbin/${progname}.php";
fi

__path_server_exe="/usr/local/lxlabs/kloxo/sbin/${progname}.exe";
__path_low_memory_file="/usr/local/lxlabs/kloxo/etc/flag/lowmem.flag";

kill_and_save_pid() {
	name=$1;
	kill_pid ${name};
	usleep 100;
	save_pid ${name};
}

save_pid() {
	name=$1;
	echo $$ > "${__path_program_root}/pid/${name}.pid";
}

kill_pid() {
	name=$1

	if [ -f ${__path_program_root}/pid/${name}.pid ] ; then
		pid=$(cat ${__path_program_root}/pid/${name}.pid);

		kill ${pid} 2>/dev/null;
		usleep 10000;
		kill -9 ${pid} 2>/dev/null;
	fi
}

wrapper_main() {

	if [ -f ${__path_slave_db} ] ; then
		string="slave";
	else 
		string="master";
	fi


	mkdir ../log 2>/dev/null;
	mkdir ../pid 2>/dev/null;

	while : ; do

		if [ -f ${__path_low_memory_file} ] ; then
			/bin/cp ${__path_server_exe}.core ${__path_server_exe};
			chmod 755 ${__path_server_exe};
			exec ${__path_server_exe} ${string} >/dev/null 2>&1;
		else 
			exec ${__path_php_path} ${__path_server_path} ${string} >/dev/null 2>&1;
		fi

		sleep 10;
	done
}

