<?php 

include_once "lib/html/include.php"; 
$sq = new Sqlite(null, 'mmail');

$list = $sq->getRowsWhere("remotelocalflag != 'remote'");

$string = null;
foreach($list as $l) {
	$string .= "{$l['nname']}:{$l['nname']}\n";
}

print($string);
