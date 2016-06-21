<?php 

include_once "lib/html/include.php"; 

initProgram('admin');
$list = posix_getpwnam('admin');

if (!$list) {
	os_create_system_user('admin', $login->password, 'admin', '/sbin/nologin', '/home/admin');
	lxfile_unix_chown_rec("/home/admin", "admin");

	//fixes issue #515
	lxfile_generic_chmod("/home/admin", "0751");

	lxshell_return("$sgbl->__path_php_path", "../bin/misc/fixwebdnsfullupdate.php");
	lxshell_return("$sgbl->__path_php_path", "../bin/misc/fixftpuserclient.php");
}
