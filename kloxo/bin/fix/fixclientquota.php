<?php 

include_once "lib/html/include.php"; 

initProgram('admin');

$login->loadAllObjects('client');

$list = $login->getList('client');

os_createUserQuota();

foreach($list as $l) {
	$l->setUpdateSubaction('change_disk_usage');
	$l->was();
}
