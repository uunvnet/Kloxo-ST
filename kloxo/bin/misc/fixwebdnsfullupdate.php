<?php 

include_once "lib/html/include.php"; 

initProgram('admin');

$login->loadAllObjects('client');
$list = $login->getList('client');

$par = parse_opt($argv);

$newip = null;

if (isset($par['oldip'])) {
	$oldip = $par['oldip'];
}

if (isset($par['newip'])) {
	$newip = $par['newip'];
}


foreach($list as $c) {
	$dlist = $c->getList('domain');
	foreach($dlist as $l) {
		$web = $l->getObject('web');
		$web->setUpdateSubaction('full_update');
		if ($newip && $oldip) {
			$web->ipaddress = $newip;
		}
		$web->was();
		$dns = $l->getObject('dns');
		$dns->setUpdateSubaction('full_update');
		if ($newip && $oldip) {
			foreach($dns->dns_record_a as $drec) {
				if ($drec->ttype !== 'a') {
					continue;
				}
				if ($drec->param === $oldip) {
					$drec->param = $newip;
				}
			}
		}
		$dns->was();
	}
}

$list = lscandir_without_dot("/home/httpd");

foreach($list as $l) {
	if (!is_dir("/home/httpd/$l")) {
		continue;
	}
	lxfile_unix_chown_rec("/home/httpd/$l/stats/", "apache");
}

$driverapp = $gbl->getSyncClass(null, 'localhost', 'web');

if ($driverapp === 'apache') {
	// --- issue #589
//	addLineIfNotExistInside("/etc/httpd/conf/httpd.conf", "Include /etc/httpd/conf/kloxo/kloxo.conf", "");
//	lxshell_return("$sgbl->__path_php_path", "../bin/misc/installsuphp.php", "--nolog");
} else {
	lxfile_cp("../file/lighttpd/lighttpd.conf", "/etc/lighttpd/lighttpd.conf");
	// --- issue #598
//	lxfile_cp("../file/lighttpd/conf/kloxo/kloxo.conf", "/etc/lighttpd/conf/kloxo/kloxo.conf");
//	lxfile_cp("../file/lighttpd/conf/kloxo/webmail.conf", "/etc/lighttpd/conf/kloxo/webmail.conf");
	lxfile_cp("../file/lighttpd/~lxcenter.conf", "/etc/lighttpd/conf.d/~lxcenter.conf");
	lxfile_cp("../file/lighttpd/conf/kloxo/webmail.conf", "/opt/configs/lighttpd/conf/defaults/webmail.conf");
	lxfile_mkdir("/home/kloxo/httpd/lighttpd");
	lxfile_unix_chown("/home/kloxo/httpd/lighttpd", "apache");
}


print("\n\n");

