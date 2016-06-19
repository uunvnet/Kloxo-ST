![Kloxo-ST logo](https://github.com/mustafaramadhan/kloxo/blob/dev/kloxo-mr_big.png)

### Kloxo fork by Mustafa Ramadhan
                            by SoarTeam


===================

分支结构:
- dev - 主分支，最新代码更新
- release - 发布版本的下载
- rpms - 所有用到的Rpm安装包

===================

# Kloxo-ST

这是以Kloxo-MR为基础的再开发版本，在外观/全球化/性能等方面做出改变的一个衍生版.

### 友情链接

1. Kloxo (LxCenter)(原名LxAdmin) - http://lxcenter.org/ and http://forum.lxcenter.org/

2. Kloxo-MR - http://mratwork.com/ and http://forum.mratwork.com/

3. QYun - www.soaryun.com

### Kloxo-ST 的特点

* OS: Redhat/CentOS 6 and 7 (32bit and 64bit) or their variants
* Billing: AWBS, WHMCS, HostBill, TheHostingTool, AccountLab Plus, Blesta and BoxBilling (note: claim by billing's author)
* Web server: Nginx, Nginx-Proxy and Lighttpd-proxy, Hiawatha, Hiawatha-proxy and Httpd 24, beside Httpd and Lighttpd; also Dual and Multiple Web server *)
* Webcache server: Squid, Varnish, Hiawatha and ATS *)
* Php: Dual-php with php 5.3/5.4 as primary and php 5.2 as secondary; multiple-php *)
* PHP-type for Apache: php-fpm_worker/_event and fcgid_worker/_event; beside mod_php/_ruid2/_itk and suphp/_worker/_event
* Mail server: qmail-toaster instead special qmail (in progress: change from courier-imap to dovecot as imap/pop3) *)
* Database: MySQL or MariaDB
* Database Manager: PHPMyAdmin; Adminer, MyWebSql and SqlBuddy as additional **)
* Webmail: Afterlogic Webmail Lite, Telaen, Squirrelmail, Roundcube and Rainloop; Horde and T-Dah dropped
* FTP server: Pure-ftpd
* DNS Server: Bind and Djbdns; add Powerdns, ~~MaraDNS~~, NSD, myDNS and Yadifa *)
* Addons: ClamAV, Spamassassin/Bogofilter/Spamdyke, RKHunter and MalDetect
* 修复所有原版Kloxo留下来的Bug.
* 多语言支持
* 耳目一新的主题风格
* 还有更多!

### 想做出贡献？

* 来Github提交代码，或者在论坛与我们进行交流！
论坛建设中

### Licensing - AGPLv3

* Like Kloxo Official, Kloxo-MR adopt AGPLv3 too.

### 如何安装？

* 请查阅：https://github.com/soarteam/Kloxo-ST/blob/dev/how-to-install.txt


### 注意
*) New features in Kloxo-MR 7.0.0 (aka Kloxo-MR 7)

- Version 6.5.1 change to 7.0.0 since 20 Aug 2014 (beta step)
- Web server: Hiawatha (since 28 Sep 2013) and Httpd 2.4 (since 20 Jun 2015); Dual (since 19 Jan 2016) and Multiple Web server (in progress)
- Webcache server: Squid, Varnish and ATS (Apache Traffic Server) (since 3 Oct 2013)
- DNS server: Powerdns, NSD, MyDNS and Yadifa (since 16 Sep 2013)
- Mail server: Dovecot (in progress)
- Php: multiple Php versions
  * suphp base since 27 Jun 2014
  * fcgid base since 5 Jul 2015
  * php-fpm/spawning base since 24 May 2016

**) New features in Kloxo-MR 6.5.0 after released
- Panel: Adminer, MyWebSql and SqlBuddy as alternative for Database management
- Core: change to use Hiawatha + php52s from lxphp + lxlighttpd for running panel

