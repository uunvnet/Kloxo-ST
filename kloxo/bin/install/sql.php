<?php 

function sql_main()
{
/*
	global $sgbl;


	self::$__fdb = mysql_connect($db_server, 'kloxo', getAdminPass());
	mysql_select_db($sgbl->__var_dbf);
	self::$__database = 'mysql';
*/

	create_database();
	update_database();

	create_general();

}





