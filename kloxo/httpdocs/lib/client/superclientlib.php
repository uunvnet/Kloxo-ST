<?php

class SuperClient extends ClientBase
{
	static $__desc  = array("","",  "super_admin");

	static $__desc_nname =     array("", "",  "name");
	static $__desc_node_num	 = array("q", "",  "number_of_nodes");

	static $__desc_node_l = array("Rq", "",  "");

	static $__acdesc_update_license_superadmin  =  array("","",  "license");
	static $__acdesc_update_collectusage  =  array("","",  "collect_usage");

	function updatecollectusage()
	{
		global $gbl, $sgbl, $login, $ghtml;

		$this->collectQuota();
	}

	function hasDriverClass()
	{
		return false;
	}

	function createShowAlist(&$alist, $subaction = null)
	{
		global $gbl, $sgbl, $login, $ghtml;

		$alist['__title_main'] = $login->getKeywordUc('resource');
		$alist[] = 'a=list&c=node';
		$this->getLxclientActions($alist);
	//	$alist[] = 'a=updateform&sa=license';
		$alist[] = 'a=resource';
		$alist[] = 'a=update&sa=collectusage';
		return $alist;
	}

	function dosyncToSystem()
	{
		global $last_error;

		switch($this->dbaction) {
			case "update":
			{
				switch($this->subaction) {
					case "password":
					{
						$this->changeSuperAdminPass();
						break;
					}
				}

				break;

			}
		}
	}

	function changeAdminPass()
	{
		global $login;

		if ($this->main->nname === 'admin') {
			$newp = client::createDbPass($this->main->realpass);

			$sql = new Sqlite(null, "client");
			$return = $sql->setPassword($newp);

			if ($return) {
				log_log("admin_error", "mysql change password Failed . $out");

				exec_with_all_closed("sh /script/load-wrapper >/dev/null 2>&1 &");
				throw new lxException($login->getThrow("could_not_change_admin_pass"));
			}

			$return = lfile_put_contents("__path_admin_pass", $newp);

			if (!$return) {
				log_log("admin_error", "Admin pass change failed  $last_error");

				exec_with_all_closed("sh /script/load-wrapper >/dev/null 2>&1 &");
				throw new lxException($login->getThrow("could_not_change_admin_pass"));
			}
		}
	}

	function changeSuperAdminPass()
	{
		global $login;

		if ($this->nname === 'superadmin') {
			$oldpass = getAdminDbPass();

			$newp = client::createDbPass($this->realpass);

			$return = lfile_put_contents("__path_super_pass", $newp);

			if (!$return) {
				log_log("admin_error", "Admin pass change failed  $last_error");

				exec_with_all_closed("sh /script/load-wrapper >/dev/null 2>&1 &");
				throw new lxException($login->getThrow("could_not_change_superadmin_pass"));
			}

			$sql = new Sqlite(null, "client");

			$return = $sql->setPassword($newp);

			if ($return) {
				$return = lfile_put_contents("__path_super_pass", $oldpass);
				log_log("admin_error", "mysqladmin Failed . $out");

				exec_with_all_closed("sh /script/load-wrapper >/dev/null 2>&1 &");
				throw new lxException($login->getThrow("could_not_change_superadmin_pass"));
			}
		}
	}
}
