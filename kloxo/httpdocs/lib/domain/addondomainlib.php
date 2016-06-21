<?php

class addondomain extends Lxdb
{
	static $__desc = array("n", "", "parked_redirected_domain");
	static $__table = 'addondomain';

	static $__desc_nname = array("n", "", "pointer_domain");
	static $__desc_parent_name_f = array("n", "", "owner");
	static $__desc_parent_clname = array("n", "", "destination");
	static $__desc_real_clparent_f = array("", "", "redirect_to");
	static $__desc_mail_flag = array("f", "", "map_mail");
	static $__desc_ttype = array("", "", "type");
	static $__desc_ttype_v_parked = array("n", "", "parked");
	static $__desc_ttype_v_redirect = array("n", "", "redirected");
	static $__desc_destinationdir = array("", "", "destination_directory");

	static function createListAlist($parent, $class)
	{
		$alist[] = "a=list&c=$class";
		$alist['__v_dialog_park'] = "a=addform&c=addondomain&dta[var]=ttype&dta[val]=parked";
		$alist['__v_dialog_red'] = "a=addform&c=addondomain&dta[var]=ttype&dta[val]=redirect";

		return $alist;
	}

	function display($var)
	{
		if ($var === 'destinationdir') {
			return "http://{$this->getTrueParentO()->nname}/$this->destinationdir";
		}

		return parent::display($var);
	}

	static function createListNlist($parent, $view)
	{
		$nlist['ttype'] = '5%';
		$nlist['nname'] = '30%';
		$nlist['mail_flag'] = '10%';
		$nlist['destinationdir'] = '70%';

		return $nlist;
	}

	static function add($parent, $class, $param)
	{
		global $login;

		$param['nname'] = strtolower($param['nname']);

		$param['nname'] = trim($param['nname']);

		if (exists_in_db(null, 'domain', $param['nname'])) {
			throw new lxException($login->getThrow('domain_already_exists_as_virtual'), '', $param['nname']);
		}

		validate_domain_name($param['nname']);

		if ($parent->isClient()) {
		} else {
			$param['real_clparent_f'] = $parent->nname;
		}

		$param['destinationdir'] = trim($param['destinationdir']);

		// MR -- that mean redirect
		if (isset($param['destinationdir'])) {
			validate_docroot($param['destinationdir']);
		}

		return $param;
	}

	static function initThisListRule($parent, $class)
	{
		if ($parent->isClient()) {
			$ret = lxdb::initThisOutOfBand($parent, 'domain', 'domain', $class);
			return $ret;

		}

		return lxdb::initThisListRule($parent, $class);
	}

	function isSync()
	{
		global $gbl, $sgbl, $login, $ghtml;

		// Don't do anything if it is syncadd or if it is restore... 
		// When restoring, addondomain is handled by the domain itself, and then the web backup.
		if ($this->dbaction === 'syncadd') {
			return false;
		}

		if ($this->dbaction === 'syncdelete') {
			return false;
		}

		if (isset($gbl->__restore_flag) && $gbl->__restore_flag) {
			return false;
		}

		return false;
	}

	function postAdd()
	{
		$this->write();

		$parent = $this->getParentO();

		if ($parent->isClient()) {
			// You have to load the domain here. Otherwise, the synctosystem won't get executed on the domain.
			$domain = $parent->getFromList('domain', $this->getTrueParentO()->nname);
			$domain->addToList('addondomain', $this);
		} else {
			$domain = $parent;
		}

		$web = $domain->getObject('web');
		$web->setUpdateSubaction('addondomain');

		if ($this->isOn('mail_flag')) {
			$mmail = $domain->getObject('mmail');
			$mmail->__var_aliasdomain = $this->nname;
			$mmail->setUpdateSubaction('add_alias');
		}

		$dns = $domain->getObject('dns');
		$dns->setUpdateSubaction('domain');
	}

	function deleteSpecific()
	{
		$this->write();

		$parent = $this->getParentO();

		if ($parent->isClient()) {
			// You have to load the domain here. Otherwise, the synctosystem won't get executed on the domain.
			$domain = $parent->getFromList('domain', $this->getTrueParentO()->nname);
		} else {
			$domain = $parent;
		}

		$web = $domain->getObject('web');
		$web->setUpdateSubaction('addondomain');

		$mmail = $domain->getObject('mmail');
		$mmail->__var_aliasdomain = $this->nname;
		$mmail->setUpdateSubaction('delete_alias');

		$dns = $domain->getObject('dns');
		$dns->setUpdateSubaction('domain');
	}

	static function defaultParentClass($parent)
	{
		return "domain";
	}

	static function addform($parent, $class, $typetd = null)
	{
		$vlist['nname'] = null;

		if ($parent->isClient()) {
			$list = get_namelist_from_objectlist($parent->getList('domain'));
			$vv = array('var' => 'real_clparent_f', 'val' => array('s', $list));
			$vlist['nname'] = array('m', array('posttext' => "=>", 'postvar' => $vv));
		} else {
			$vlist['nname'] = array('m', array('posttext' => "=>$parent->nname"));
		}

		if ($typetd['val'] === 'redirect') {
			$vlist['destinationdir'] = array('m', null);
		}

		$vlist['mail_flag'] = null;
		$ret['variable'] = $vlist;
		$ret['action'] = 'add';

		return $ret;
	}

	static function createListSlist($parent)
	{
		$nlist['nname'] = null;
		$nlist['ttype'] = array('s', array('--any--', 'parked', 'redirect'));
		$nlist['parent_clname'] = null;

		return $nlist;
	}
}

class all_addondomain extends addondomain
{
	static $__desc = array("n", "", "all_pointer_domain");

	function isSelect()
	{
		return false;
	}

	static function initThisListRule($parent, $class)
	{
		global $login;

		if (!$parent->isAdmin()) {
			throw new lxException($login->getThrow("only_admin_can_access"));
		}

		return "__v_table";
	}

	static function createListAlist($parent, $class)
	{
		return all_domain::createListAlist($parent, $class);
	}

}
