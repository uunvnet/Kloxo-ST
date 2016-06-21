### begin - web of '<?php echo $domainname; ?>' - do not remove/modify this line

<?php

if (!isset($phpselected)) {
	$phpselected = 'php';
}

if (!isset($timeout)) {
	$timeout = '300';
}

$globalspath = "/opt/configs/apache/conf/globals";
$sslpath = "/home/kloxo/ssl";
$kloxopath = "/usr/local/lxlabs/kloxo";

if ($reverseproxy) {
	$ports[] = '30080';
	$ports[] = '30443';
} else {
	if (($webcache === 'none') || (!$webcache)) {
		$ports[] = '80';
		$ports[] = '443';
	} else {
		$ports[] = '8080';
		$ports[] = '8443';
	}
}

$portlist = array('${port}', '${portssl}');

if ($reverseproxy) {
	$tmp_ip = '127.0.0.1';

	foreach ($certnamelist as $ip => $certname) {
		$tmp_certname = $certname;
		break;
	}

	$certnamelist = null;

	$certnamelist[$tmp_ip] = $tmp_certname;
} else {
	$tmp_ip = '*';
}

foreach ($certnamelist as $ip => $certname) {
	if (file_exists("{$sslpath}/{$domainname}.key")) {
		$certnamelist[$ip] = "{$sslpath}/{$domainname}";
	} else {
		$certnamelist[$ip] = "{$sslpath}/{$certname}";
	}
}

$statsapp = $stats['app'];
$statsprotect = ($stats['protect']) ? true : false;

$serveralias = "www.{$domainname}";

if ($wildcards) {
	$serveralias .= " *.{$domainname}";
}

if ($serveraliases) {
	foreach ($serveraliases as &$sa) {
		$serveralias .= "\\\n		{$sa}";
	}
}

if ($parkdomains) {
	foreach ($parkdomains as $pk) {
		$pa = $pk['parkdomain'];
		$serveralias .= "\\\n		{$pa} www.{$pa}";
	}
}

if ($webmailapp) {
	if ($webmailapp === '--Disabled--') {
		$webmaildocroot = "/home/kloxo/httpd/disable";
	} else {
		$webmaildocroot = "/home/kloxo/httpd/webmail/{$webmailapp}";
	}
} else {
	$webmaildocroot = "/home/kloxo/httpd/webmail";
}

$webmailremote = str_replace("http://", "", $webmailremote);
$webmailremote = str_replace("https://", "", $webmailremote);

$cpdocroot = "/home/kloxo/httpd/cp";

if ($indexorder) {
	$indexorder = implode(' ', $indexorder);
}

if ($dirindex) {
	$dirindex = '+Indexes';
} else {
	$dirindex = '-Indexes';
}

if ($blockips) {
	$biptemp = array();
	foreach ($blockips as &$bip) {
		if (strpos($bip, ".*.*.*") !== false) { $bip = str_replace(".*.*.*", ".0.0/8", $bip); }
		if (strpos($bip, ".*.*") !== false) { $bip = str_replace(".*.*", ".0.0/16", $bip); }
		if (strpos($bip, ".*") !== false)  { $bip = str_replace(".*", ".0/24", $bip); }
		$biptemp[] = $bip;
	}
	$blockips = $biptemp;

	$blockips = implode(' ', $blockips);
}

if (file_exists("{$globalspath}/custom.acme-challenge.conf")) {
	$acmechallenge = "custom.acme-challenge";
} else if (file_exists("{$globalspath}/acme-challenge.conf")) {
	$acmechallenge = "acme-challenge";
}

if (file_exists("{$globalspath}/custom.header_base.conf")) {
	$header_base = "custom.header_base";
} else if (file_exists("{$globalspath}/header_base.conf")) {
	$header_base = "header_base";
}

if (file_exists("{$kloxopath}/etc/flag/use_apache24.flg")) {
	$use_httpd24 = true;
} else {
	$use_httpd24 = false;
}

if ($use_httpd24) {
	if (file_exists("{$globalspath}/custom.ssl_base24.conf")) {
		$ssl_base = "custom.ssl_base24";
	} else if (file_exists("{$globalspath}/ssl_base24.conf")) {
		$ssl_base = "ssl_base24";
	}
} else {
	if (file_exists("{$globalspath}/custom.ssl_base.conf")) {
		$ssl_base = "custom.ssl_base";
	} else if (file_exists("{$globalspath}/ssl_base.conf")) {
		$ssl_base = "ssl_base";
	}
}

$userinfo = posix_getpwnam($user);

if ($userinfo) {
	$fpmport = (50000 + $userinfo['uid']);
} else {
	return false;
}

// MR -- for future purpose, apache user have uid 50000
// $userinfoapache = posix_getpwnam('apache');
// $fpmportapache = (50000 + $userinfoapache['uid']);
$fpmportapache = 50000;

$disablepath = "/home/kloxo/httpd/disable";

if ($disabled) {
	$sockuser = 'apache';
} else {
	$sockuser = $user;
}

foreach ($certnamelist as $ip => $certname) {
?>

<IfVersion < 2.4>
	Define port ${global::port}
	Define portssl ${global::portssl}
	Define ip ${global::ip}
</IfVersion>

<IfVersion >= 2.4>
	Include <?php echo $globalspath; ?>/portnip.conf
</IfVersion>

<?php
	if (!$reverseproxy) {
		if ($ip !== '*') {
?>
Define ipalloc <?php echo $ip; ?>

<IfVersion < 2.4>
	NameVirtualHost ${ipalloc}:${port}
	NameVirtualHost ${ipalloc}:${portssl}
</IfVersion>

<?php
		}
	}
}

foreach ($certnamelist as $ip => $certname) {
	$count = 0;

	foreach ($ports as &$port) {
		$protocol = ($count === 0) ? "http://" : "https://";

		if ($disabled) {
?>

## webmail for '<?php echo $domainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName webmail.<?php echo $domainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $disablepath; ?>"

	DirectoryIndex <?php echo $indexorder; ?>

<?php
			if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
				if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
				}
?>
	</IfModule>
<?php
			} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
			}
?>

	<IfModule suexec.c>
		SuexecUserGroup apache apache
	</IfModule>

	<IfModule mod_suphp.c>
		SuPhp_UserGroup apache apache
	</IfModule>

	#<IfVersion < 2.4>
		<IfModule mod_ruid2.c>
			RMode config
			RUidGid apache apache
			RMinUidGid apache apache
		</IfModule>

		<IfModule itk.c>
			AssignUserId apache apache
		</IfModule>

		<IfModule mod_fastcgi.c>
			Alias /webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake "<?php echo $disablepath; ?>/webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake"
			#FastCGIExternalServer "<?php echo $disablepath; ?>/webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmportapache; ?> -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			FastCGIExternalServer "<?php echo $disablepath; ?>/webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake" -socket /opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			<FilesMatch \.php$>
				SetHandler application/x-httpd-fastphp
			</FilesMatch>
			Action application/x-httpd-fastphp /webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake
			<Files "webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake">
				RewriteCond %{REQUEST_URI} !webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake
			</Files>
		</IfModule>

		<IfModule !mod_ruid2.c>
			<IfModule !mod_itk.c>
				<IfModule !mod_fastcgi.c>
					<IfModule mod_fcgid.c>
						FcgidIOTimeout <?php echo $timeout; ?>

						<Directory "<?php echo $disablepath; ?>/">
							Options +ExecCGI
							<FilesMatch \.php$>
								SetHandler fcgid-script
							</FilesMatch>
							FCGIWrapper /home/kloxo/client/php.fcgi .php
						</Directory>
					</IfModule>
				</IfModule>
			</IfModule>	
		</IfModule>
	#</IfVersion>

	<IfVersion >= 2.4>
		<IfModule mod_proxy_fcgi.c>
			ProxyRequests Off
			ProxyErrorOverride On
			ProxyPass /error !
			ErrorDocument 500 /error/500.html
			<FilesMatch \.php$>
				SetHandler "proxy:unix:/opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock|fcgi://localhost"
			</FilesMatch>
			<Proxy "fcgi://localhost">
				ProxySet timeout=<?php echo $timeout; ?>

				ProxySet connectiontimeout=<?php echo $timeout; ?>
				#ProxySet enablereuse=on
				ProxySet max=25
				ProxySet retry=0
			</Proxy>
		</IfModule>
	</IfVersion>

	<Location "/">
		Options -Indexes -FollowSymlinks +SymLinksIfOwnerMatch
	</Location>

	<Directory "<?php echo $disablepath; ?>/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
	</Directory>

</VirtualHost>

<?php
		} else {
?>

## cp for '<?php echo $domainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName cp.<?php echo $domainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $cpdocroot; ?>"

	DirectoryIndex <?php echo $indexorder; ?>

<?php
		if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
			if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
			}
?>
	</IfModule>
<?php
		} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
		}
?>

	<IfModule suexec.c>
		SuexecUserGroup apache apache
	</IfModule>

	<IfModule mod_suphp.c>
		SuPhp_UserGroup apache apache
	</IfModule>

	#<IfVersion < 2.4>
		<IfModule mod_ruid2.c>
			RMode config
			RUidGid apache apache
			RMinUidGid apache apache
		</IfModule>

		<IfModule itk.c>
			AssignUserId apache apache
		</IfModule>

		<IfModule mod_fastcgi.c>
			Alias /cp.<?php echo $domainname; ?>.<?php echo $count; ?>fake "<?php echo $cpdocroot; ?>/cp.<?php echo $domainname; ?>.<?php echo $count; ?>fake"
			#FastCGIExternalServer "<?php echo $cpdocroot; ?>/cp.<?php echo $domainname; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmportapache; ?> -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			FastCGIExternalServer "<?php echo $cpdocroot; ?>/cp.<?php echo $domainname; ?>.<?php echo $count; ?>fake" -socket /opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			<FilesMatch \.php$>
				SetHandler application/x-httpd-fastphp
			</FilesMatch>
			Action application/x-httpd-fastphp /cp.<?php echo $domainname; ?>.<?php echo $count; ?>fake
			<Files "cp.<?php echo $domainname; ?>.<?php echo $count; ?>fake">
				RewriteCond %{REQUEST_URI} !cp.<?php echo $domainname; ?>.<?php echo $count; ?>fake
			</Files>
		</IfModule>

		<IfModule !mod_ruid2.c>
			<IfModule !mod_itk.c>
				<IfModule !mod_fastcgi.c>
					<IfModule mod_fcgid.c>
						FcgidIOTimeout <?php echo $timeout; ?>

						<Directory "<?php echo $cpdocroot; ?>/">
							Options +ExecCGI
							<FilesMatch \.php$>
								SetHandler fcgid-script
							</FilesMatch>
							FCGIWrapper /home/kloxo/client/php.fcgi .php
						</Directory>
					</IfModule>
				</IfModule>
			</IfModule>	
		</IfModule>
	#</IfVersion>

	<IfVersion >= 2.4>
		<IfModule mod_proxy_fcgi.c>
			ProxyRequests Off
			ProxyErrorOverride On
			ProxyPass /error !
			ErrorDocument 500 /error/500.html
			<FilesMatch \.php$>
				SetHandler "proxy:unix:/opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock|fcgi://localhost"
			</FilesMatch>
			<Proxy "fcgi://localhost">
				ProxySet timeout=<?php echo $timeout; ?>

				ProxySet connectiontimeout=<?php echo $timeout; ?>

				#ProxySet enablereuse=on
				ProxySet max=25
				ProxySet retry=0
			</Proxy>
		</IfModule>
	</IfVersion>
	
	<Location "/">
		# Options +Indexes +FollowSymlinks
		Options -Indexes -FollowSymlinks +SymLinksIfOwnerMatch
	</Location>

	<Directory "<?php echo $cpdocroot; ?>/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
	</Directory>

</VirtualHost>

<?php
		if ($webmailremote) {
?>

## webmail for '<?php echo $domainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName webmail.<?php echo $domainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $webmaildocroot; ?>"

	Redirect "/" "<?php echo $protocol; ?><?php echo $webmailremote; ?>"
<?php
			if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
				if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
				}
?>
	</IfModule>
<?php
			} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
			}
?>

</VirtualHost>

<?php
		} else {
?>

## webmail for '<?php echo $domainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName webmail.<?php echo $domainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $webmaildocroot; ?>"

	DirectoryIndex <?php echo $indexorder; ?>

<?php
			if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
				if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
				}
?>
	</IfModule>
<?php
			} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
			}
?>

	<IfModule suexec.c>
		SuexecUserGroup apache apache
	</IfModule>

	<IfModule mod_suphp.c>
		SuPhp_UserGroup apache apache
	</IfModule>

	#<IfVersion < 2.4>
		<IfModule mod_ruid2.c>
			RMode config
			RUidGid apache apache
			RMinUidGid apache apache
		</IfModule>

		<IfModule itk.c>
			AssignUserId apache apache
		</IfModule>

		<IfModule mod_fastcgi.c>
			Alias /webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake "<?php echo $webmaildocroot; ?>/webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake"
			#FastCGIExternalServer "<?php echo $webmaildocroot; ?>/webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmportapache; ?> -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			FastCGIExternalServer "<?php echo $webmaildocroot; ?>/webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake" -socket /opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			<FilesMatch \.php$>
				SetHandler application/x-httpd-fastphp
			</FilesMatch>
			Action application/x-httpd-fastphp /webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake
			<Files "webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake">
				RewriteCond %{REQUEST_URI} !webmail.<?php echo $domainname; ?>.<?php echo $count; ?>fake
			</Files>
		</IfModule>

		<IfModule !mod_ruid2.c>
			<IfModule !mod_itk.c>
				<IfModule !mod_fastcgi.c>
					<IfModule mod_fcgid.c>
						FcgidIOTimeout <?php echo $timeout; ?>

						<Directory "<?php echo $webmaildocroot; ?>/">
							Options +ExecCGI
							<FilesMatch \.php$>
								SetHandler fcgid-script
							</FilesMatch>
							FCGIWrapper /home/kloxo/client/php.fcgi .php
						</Directory>
					</IfModule>
				</IfModule>
			</IfModule>	
		</IfModule>
	#</IfVersion>

	<IfVersion >= 2.4>
		<IfModule mod_proxy_fcgi.c>
			ProxyRequests Off
			ProxyErrorOverride On
			ProxyPass /error !
			ErrorDocument 500 /error/500.html
			<FilesMatch \.php$>
				SetHandler "proxy:unix:/opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock|fcgi://localhost"
			</FilesMatch>
			<Proxy "fcgi://localhost">
				ProxySet timeout=<?php echo $timeout; ?>

				ProxySet connectiontimeout=<?php echo $timeout; ?>

				#ProxySet enablereuse=on
				ProxySet max=25
				ProxySet retry=0
			</Proxy>
		</IfModule>
	</IfVersion>

	<Location "/">
		Options -Indexes -FollowSymlinks +SymLinksIfOwnerMatch
	</Location>

	<Directory "<?php echo $webmaildocroot; ?>/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
	</Directory>

</VirtualHost>

<?php
			}
		}

		if (!$reverseproxy) {
			if ($ip !== '*') {
				$ip_special = '${ipalloc}';
			} else {
				$ip_special = '${ip}';
			}
		} else {
			$ip_special = '${ip}';
		}
?>

## web for '<?php echo $domainname; ?>'
<VirtualHost <?php echo $ip_special; ?>:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerAdmin webmaster@<?php echo $domainname; ?>


	ServerName <?php echo $domainname; ?>


	ServerAlias <?php echo $serveralias; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf
<?php
		if ($count !== 0) {
			if ($enablessl) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
				if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
				}
?>
	</IfModule>
<?php
			} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
			}
		}

		if (!$reverseproxy) {
			if ($wwwredirect) {
?>

	RewriteEngine On
	RewriteCond %{HTTP_HOST} ^<?php echo str_replace('.', '\.', $domainname); ?>$ [NC]
	RewriteRule ^(.*)/$ <?php echo $protocol; ?>www.<?php echo $domainname; ?>/$1 [R=301,L]
<?php
			}

			if (($count === 0) && ($httpsredirect)) {
?>

	RewriteEngine On
	RewriteCond %{HTTPS} off
	RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
<?php
			}
		}

		if ($disabled) {
			$rootpath = $disablepath;
		}
?>

	DocumentRoot "<?php echo $rootpath; ?>"

	DirectoryIndex <?php echo $indexorder; ?>


	AliasMatch "/__kloxo(/|$)(.*)" "/home/<?php echo $user; ?>/kloxoscript$1$2"

	Redirect "/kloxo" "https://cp.<?php echo $domainname; ?>:<?php echo $kloxoportssl; ?>"
	Redirect "/kloxononssl" "http://cp.<?php echo $domainname; ?>:<?php echo $kloxoportnonssl; ?>"
	Redirect "/webmail" "<?php echo $protocol; ?>webmail.<?php echo $domainname; ?>"
	Redirect "/cp" "<?php echo $protocol; ?>cp.<?php echo $domainname; ?>"
<?php
		if ($redirectionlocal) {
			foreach ($redirectionlocal as $rl) {
?>

	AliasMatch "<?php echo $rl[0]; ?>(/|$)(.*)" "<?php echo $rootpath; ?><?php echo $rl[1]; ?>$1$2"
<?php
			}
		}

		if ($redirectionremote) {
			foreach ($redirectionremote as $rr) {
				if ($rr[2] === 'both') {
?>

	Redirect "<?php echo $rr[0]; ?>" "<?php echo $protocol; ?><?php echo $rr[1]; ?>"
<?php
				} else {
					$protocol2 = ($rr[2] === 'https') ? "https://" : "http://";
?>

	Redirect "<?php echo $rr[0]; ?>" "<?php echo $protocol2; ?><?php echo $rr[1]; ?>"
<?php
				}
			}
		}
?>

	<IfModule suexec.c>
		SuexecUserGroup <?php echo $sockuser; ?> <?php echo $sockuser; ?>

	</IfModule>

	<IfModule mod_suphp.c>
		SuPhp_UserGroup <?php echo $sockuser; ?> <?php echo $sockuser; ?>

		suPHP_Configpath "/home/httpd/<?php echo $domainname; ?>/"
	</IfModule>

	#<IfVersion < 2.4>
		<IfModule mod_ruid2.c>
			RMode config
			RUidGid <?php echo $sockuser; ?> <?php echo $sockuser; ?>

			RMinUidGid <?php echo $sockuser; ?> <?php echo $sockuser; ?>

		</IfModule>

		<IfModule itk.c>
			AssignUserId <?php echo $sockuser; ?> <?php echo $sockuser; ?>

			<Location "/stats/">
				AssignUserId apache apache
			</Location>
		</IfModule>

		<IfModule mod_fastcgi.c>
			Alias /<?php echo $domainname; ?>.<?php echo $count; ?>fake "<?php echo $rootpath; ?>/<?php echo $domainname; ?>.<?php echo $count; ?>fake"
			#FastCGIExternalServer "<?php echo $rootpath; ?>/<?php echo $domainname; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmport; ?> -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			FastCGIExternalServer "<?php echo $rootpath; ?>/<?php echo $domainname; ?>.<?php echo $count; ?>fake" -socket /opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-<?php echo $sockuser; ?>.sock -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			<FilesMatch \.php$>
				SetHandler application/x-httpd-fastphp
			</FilesMatch>
			Action application/x-httpd-fastphp /<?php echo $domainname; ?>.<?php echo $count; ?>fake
			<Files "<?php echo $domainname; ?>.<?php echo $count; ?>fake">
				RewriteCond %{REQUEST_URI} !<?php echo $domainname; ?>.<?php echo $count; ?>fake
			</Files>
		</IfModule>

		<IfModule !mod_ruid2.c>
			<IfModule !mod_itk.c>
				<IfModule !mod_fastcgi.c>
					<IfModule mod_fcgid.c>
						FcgidIOTimeout <?php echo $timeout; ?>

						<Directory "<?php echo $rootpath; ?>/">
							Options +ExecCGI
							<FilesMatch \.php$>
								SetHandler fcgid-script
							</FilesMatch>
							FCGIWrapper /home/kloxo/client/<?php echo $user; ?>/php.fcgi .php
						</Directory>
					</IfModule>
				</IfModule>
			</IfModule>	
		</IfModule>
	#</IfVersion>

	<IfVersion >= 2.4>
		<IfModule mod_proxy_fcgi.c>
			ProxyRequests Off
			ProxyErrorOverride On
			ProxyPass /error !
			ErrorDocument 500 /error/500.html
			<FilesMatch \.php$>
				SetHandler "proxy:unix:/opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-<?php echo $sockuser; ?>.sock|fcgi://localhost"
			</FilesMatch>
			<Proxy "fcgi://localhost">
				ProxySet timeout=<?php echo $timeout; ?>

				ProxySet connectiontimeout=<?php echo $timeout; ?>

				#ProxySet enablereuse=on
				ProxySet max=25
				ProxySet retry=0
			</Proxy>
		</IfModule>
	</IfVersion>

	<Directory "<?php echo $rootpath; ?>/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
<?php
		if ($enablecgi) {
?>
		Options +ExecCGI
		<FilesMatch \.(cgi|pl)$>
			#<IfModule !mod_fastcgi.c>
				<IfModule mod_suphp.c>
					SuPhp_UserGroup <?php echo $sockuser; ?> <?php echo $sockuser; ?>

					SetHandler x-suphp-cgi
				</IfModule>
			#</IfModule>
		</FilesMatch>
<?php
		}
?>
	</Directory>
<?php
	//	if (($enablecgi) && ($driver[0] !== 'hiawatha')) {
		if ($enablecgi) {
?>

	ScriptAliasMatch "/cgi-bin(/|$)(.*)" "/home/<?php echo $user; ?>/<?php echo $domainname; ?>/cgi-bin$1$2"
<?php
		}
?>

	<IfModule mod_php5.c>
		php_admin_value sendmail_path "/usr/sbin/sendmail -t -i"
		php_admin_value sendmail_from "<?php echo $domainname; ?>"
		Include /home/kloxo/client/<?php echo $user; ?>/prefork.inc
	</IfModule>

	<Location "/">
		Options <?php echo $dirindex; ?> -FollowSymlinks +SymLinksIfOwnerMatch
		<IfModule mod_php5.c>
			php_admin_value open_basedir "/home/<?php echo $user; ?>:/tmp:/usr/share/pear:/var/lib/php/session/:/home/kloxo/httpd/script:/home/kloxo/httpd/disable/:<?php echo $extrabasedir; ?>"
		</IfModule>
	</Location>
<?php
		if ($enablestats) {
?>

	CustomLog "/home/httpd/<?php echo $domainname ?>/stats/<?php echo $domainname ?>-custom_log" combined
	ErrorLog "/home/httpd/<?php echo $domainname ?>/stats/<?php echo $domainname ?>-error_log"
<?php
			if ($statsapp === 'awstats') {
?>

	<Directory "/home/kloxo/httpd/awstats/wwwroot/cgi-bin/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>

		Options +ExecCGI
		<FilesMatch \.(cgi|pl)$>
			#<IfModule !mod_fastcgi.c>
				<IfModule mod_suphp.c>
					SuPhp_UserGroup apache apache
					SetHandler x-suphp-cgi
				</IfModule>
			#</IfModule>
		</FilesMatch>
	</Directory>

	ScriptAliasMatch "/awstats(/|$)(.*)" "/home/kloxo/httpd/awstats/wwwroot/cgi-bin$1$2"

	AliasMatch "/awstatscss(/|$)(.*)" "/home/kloxo/httpd/awstats/wwwroot/css$1$2"
	AliasMatch "/awstatsicons(/|$)(.*)" "/home/kloxo/httpd/awstats/wwwroot/icon$1$2"

	Redirect "/stats" "<?php echo $protocol; ?><?php echo $domainname; ?>/awstats/awstats.pl"
	Redirect "/stats/" "<?php echo $protocol; ?><?php echo $domainname; ?>/awstats/awstats.pl"
<?php
			} elseif ($statsapp === 'webalizer') {
?>

	AliasMatch "/stats(/|$)(.*)" "/home/httpd/<?php echo $domainname; ?>/webstats$1$2"
<?php
			}
?>

	<Location "/stats/">
		Options +Indexes
<?php
			if ($statsprotect) {
?>

		AuthType Basic
		AuthName "AuthStats"
		#AuthUserFile "/home/<?php echo $user; ?>/__dirprotect/__stats"
		AuthUserFile "/home/httpd/<?php echo $domainname ?>/__dirprotect/__stats"
		require valid-user
<?php
			}
?>
	</Location>
<?php
		}

		if ($apacheextratext) {
?>

	# Extra Tags - begin
<?php echo $apacheextratext; ?>

	# Extra Tags - end
<?php
		}

		if (!$enablephp) {
?>
	<FilesMatch \.php$>
		SetHandler application/x-httpd-php-source
	</FilesMatch>
<?php
		}

		if ($dirprotect) {
			foreach ($dirprotect as $k) {
				$protectpath = $k['path'];
				$protectauthname = $k['authname'];
				$protectfile = str_replace('/', '_', $protectpath) . '_';
?>

	<Location "/<?php echo $protectpath; ?>/">
		AuthType Basic
		AuthName "<?php echo $protectauthname; ?>"
		AuthUserFile "/home/httpd/<?php echo $domainname; ?>/__dirprotect/<?php echo $protectfile; ?>"
		require valid-user
	</Location>
<?php
			}
		}

		if ($blockips) {
?>

	<Location "/">
		Order deny,allow
		Deny from <?php echo $blockips; ?>

	</Location>
<?php
		}
?>

</VirtualHost>

<?php
		if ($domainredirect) {
			foreach ($domainredirect as $domredir) {
				$redirdomainname = $domredir['redirdomain'];
				$redirpath = ($domredir['redirpath']) ? $domredir['redirpath'] : null;
				$webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

				$randnum = rand(0, 32767);

				if ($redirpath) {
					if ($disabled) {
						$$redirfullpath = $disablepath;
					} else {
						$redirfullpath = str_replace('//', '/', $rootpath . '/' . $redirpath);
					}
?>

## web for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName <?php echo $redirdomainname; ?>


	ServerAlias www.<?php echo $redirdomainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $redirfullpath; ?>"

	DirectoryIndex <?php echo $indexorder; ?>

<?php
					if ($count !== 0) {
						if ($enablessl) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
							if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
							}
?>
	</IfModule>
<?php
						} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
						}
					}

					if ($enablephp) {
?>

	<IfModule suexec.c>
		SuexecUserGroup <?php echo $sockuser; ?> <?php echo $sockuser; ?>

	</IfModule>

	<IfModule mod_suphp.c>
		SuPhp_UserGroup <?php echo $sockuser; ?> <?php echo $sockuser; ?>

		suPHP_Configpath "/home/httpd/<?php echo $domainname; ?>/"
	</IfModule>

	#<IfVersion < 2.4>
		<IfModule mod_ruid2.c>
			RMode config
			RUidGid <?php echo $sockuser; ?> <?php echo $sockuser; ?>

			RMinUidGid <?php echo $sockuser; ?> <?php echo $sockuser; ?>

		</IfModule>

		<IfModule itk.c>
			AssignUserId <?php echo $sockuser; ?> <?php echo $sockuser; ?>

			<Location "/stats/">
				AssignUserId apache apache
			</Location>
		</IfModule>

		<IfModule mod_fastcgi.c>
			Alias /<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake "<?php echo $redirfullpath; ?>/<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake"
			#FastCGIExternalServer "<?php echo $redirfullpath; ?>/<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmport; ?> -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			FastCGIExternalServer "<?php echo $redirfullpath; ?>/<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake" -socket /opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-<?php echo $sockuser; ?>.sock -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			<FilesMatch \.php$>
				SetHandler application/x-httpd-fastphp
			</FilesMatch>
			Action application/x-httpd-fastphp /<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake
			<Files "<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake">
				RewriteCond %{REQUEST_URI} !<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake
			</Files>
		</IfModule>

		<IfModule !mod_ruid2.c>
			<IfModule !mod_itk.c>
				<IfModule !mod_fastcgi.c>
					<IfModule mod_fcgid.c>
						FcgidIOTimeout <?php echo $timeout; ?>

						<Directory "<?php echo $redirfullpath; ?>/">
							Options +ExecCGI
							<FilesMatch \.php$>
								SetHandler fcgid-script
							</FilesMatch>
							FCGIWrapper /home/kloxo/client/<?php echo $user; ?>/php.fcgi .php
						</Directory>
					</IfModule>
				</IfModule>
			</IfModule>	
		</IfModule>
	#</IfVersion>

	<IfVersion >= 2.4>
		<IfModule mod_proxy_fcgi.c>
			ProxyRequests Off
			ProxyErrorOverride On
			ProxyPass /error !
			ErrorDocument 500 /error/500.html
			<FilesMatch \.php$>
				SetHandler "proxy:unix:/opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-<?php echo $sockuser; ?>.sock|fcgi://localhost"
			</FilesMatch>
			<Proxy "fcgi://localhost">
				ProxySet timeout=<?php echo $timeout; ?>

				ProxySet connectiontimeout=<?php echo $timeout; ?>

				#ProxySet enablereuse=on
				ProxySet max=25
				ProxySet retry=0
			</Proxy>
		</IfModule>
	</IfVersion>

	<Directory "<?php echo $redirfullpath; ?>/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
<?php
					}

				//	if (($enablecgi) && ($driver[0] !== 'hiawatha')) {
					if ($enablecgi) {
?>
		Options +ExecCGI
		<FilesMatch \.(cgi|pl)$>
			#<IfModule !mod_fastcgi.c>
				<IfModule mod_suphp.c>
					SuPhp_UserGroup a <?php echo $sockuser; ?> <?php echo $sockuser; ?>

					SetHandler x-suphp-cgi
				</IfModule>
			#</IfModule>
		</FilesMatch>
<?php
					}
?>
	</Directory>
<?php
				//	if (($enablecgi) && ($driver[0] !== 'hiawatha')) {
					if ($enablecgi) {
?>

	ScriptAliasMatch "/cgi-bin(/|$)(.*)" "/home/<?php echo $user; ?>/<?php echo $redirdomainname; ?>/cgi-bin$1$2"
<?php
					}
?>

</VirtualHost>

<?php
				} else {
?>

## web for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName <?php echo $redirdomainname; ?>


	ServerAlias www.<?php echo $redirdomainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $rootpath; ?>"

	Redirect "/" "<?php echo $protocol; ?><?php echo $domainname; ?>/"
<?php
					if ($count !== 0) {
						if ($enablessl) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
							if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
							}
?>
	</IfModule>
<?php
						} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
						}
					}
?>

</VirtualHost>

<?php
				}
			}
		}

		if ($parkdomains) {
			foreach ($parkdomains as $dompark) {
				$parkdomainname = $dompark['parkdomain'];
				$webmailmap = ($dompark['mailflag'] === 'on') ? true : false;

				if ($disabled) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName webmail.<?php echo $parkdomainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $disablepath; ?>"

	DirectoryIndex <?php echo $indexorder; ?>

<?php
					if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
						if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
						}
?>
	</IfModule>
<?php
					} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
					}
?>

	<IfModule suexec.c>
		SuexecUserGroup apache apache
	</IfModule>

	<IfModule mod_suphp.c>
		SuPhp_UserGroup apache apache
	</IfModule>

	#<IfVersion < 2.4>
		<IfModule mod_ruid2.c>
			RMode config
			RUidGid apache apache
			RMinUidGid apache apache
		</IfModule>

		<IfModule itk.c>
			AssignUserId apache apache
		</IfModule>

		<IfModule mod_fastcgi.c>
			Alias /webmailwebmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake "<?php echo $disablepath; ?>/webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake"
			#FastCGIExternalServer "<?php echo $disablepath; ?>/webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmportapache; ?> -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			FastCGIExternalServer "<?php echo $disablepath; ?>/webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake" -socket /opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			<FilesMatch \.php$>
				SetHandler application/x-httpd-fastphp
			</FilesMatch>
			Action application/x-httpd-fastphp /webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake
			<Files "webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake">
				RewriteCond %{REQUEST_URI} !webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake
			</Files>
		</IfModule>

		<IfModule !mod_ruid2.c>
			<IfModule !mod_itk.c>
				<IfModule !mod_fastcgi.c>
					<IfModule mod_fcgid.c>
						FcgidIOTimeout <?php echo $timeout; ?>

						<Directory "<?php echo $disablepath; ?>/">
							Options +ExecCGI
							<FilesMatch \.php$>
								SetHandler fcgid-script
							</FilesMatch>
							FCGIWrapper /home/kloxo/client/php.fcgi .php
						</Directory>
					</IfModule>
				</IfModule>
			</IfModule>	
		</IfModule>
	#</IfVersion>

	<IfVersion >= 2.4>
		<IfModule mod_proxy_fcgi.c>
			ProxyRequests Off
			ProxyErrorOverride On
			ProxyPass /error !
			ErrorDocument 500 /error/500.html
			<FilesMatch \.php$>
				SetHandler "proxy:unix:/opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock|fcgi://localhost"
			</FilesMatch>
			<Proxy "fcgi://localhost">
				ProxySet timeout=<?php echo $timeout; ?>

				ProxySet connectiontimeout=<?php echo $timeout; ?>

				#ProxySet enablereuse=on
				ProxySet max=25
				ProxySet retry=0
			</Proxy>
		</IfModule>
	</IfVersion>

	<Location "/">
		Options -Indexes -FollowSymlinks +SymLinksIfOwnerMatch
	</Location>

	<Directory "<?php echo $disablepath; ?>/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
	</Directory>

</VirtualHost>

<?php
				} else {
					if ($webmailremote) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName webmail.<?php echo $parkdomainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $webmaildocroot; ?>"

	Redirect "/" "<?php echo $protocol; ?><?php echo $webmailremote; ?>"
<?php
						if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
							if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
							}
?>
		</IfModule>
<?php
						} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
						}
?>

</VirtualHost>

<?php
					} elseif ($webmailmap) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName webmail.<?php echo $parkdomainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $webmaildocroot; ?>"

	DirectoryIndex <?php echo $indexorder; ?>

<?php
						if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
							if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
							}
?>
	</IfModule>
<?php
						} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
						}
?>

	<IfModule suexec.c>
		SuexecUserGroup apache apache
	</IfModule>

	<IfModule mod_suphp.c>
		SuPhp_UserGroup apache apache
	</IfModule>

	#<IfVersion < 2.4>
		<IfModule mod_ruid2.c>
			RMode config
			RUidGid apache apache
			RMinUidGid apache apache
		</IfModule>

		<IfModule itk.c>
			AssignUserId apache apache
		</IfModule>

		<IfModule mod_fastcgi.c>
			Alias /webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake "<?php echo $webmaildocroot; ?>/webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake"
			#FastCGIExternalServer "<?php echo $webmaildocroot; ?>/webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmportapache; ?> -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			FastCGIExternalServer "<?php echo $webmaildocroot; ?>/webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake" -socket /opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			<FilesMatch \.php$>
				SetHandler application/x-httpd-fastphp
			</FilesMatch>
			Action application/x-httpd-fastphp /webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake
			<Files "webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake">
				RewriteCond %{REQUEST_URI} !webmail.<?php echo $parkdomainname; ?>.<?php echo $count; ?>fake
			</Files>
		</IfModule>

		<IfModule !mod_ruid2.c>
			<IfModule !mod_itk.c>
				<IfModule !mod_fastcgi.c>
					<IfModule mod_fcgid.c>
						FcgidIOTimeout <?php echo $timeout; ?>

						<Directory "<?php echo $webmaildocroot; ?>/">
							Options +ExecCGI
							<FilesMatch \.php$>
								SetHandler fcgid-script
							</FilesMatch>
							FCGIWrapper /home/kloxo/client/php.fcgi .php
						</Directory>
					</IfModule>
				</IfModule>
			</IfModule>	
		</IfModule>
	#</IfVersion>

	<IfVersion >= 2.4>
		<IfModule mod_proxy_fcgi.c>
			ProxyRequests Off
			ProxyErrorOverride On
			ProxyPass /error !
			ErrorDocument 500 /error/500.html
			<FilesMatch \.php$>
				SetHandler "proxy:unix:/opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock|fcgi://localhost"
			</FilesMatch>
			<Proxy "fcgi://localhost">
				ProxySet timeout=<?php echo $timeout; ?>

				ProxySet connectiontimeout=<?php echo $timeout; ?>

				#ProxySet enablereuse=on
				ProxySet max=25
				ProxySet retry=0
			</Proxy>
		</IfModule>
	</IfVersion>

	<Location "/">
		Options -Indexes -FollowSymlinks +SymLinksIfOwnerMatch
	</Location>

	<Directory "<?php echo $webmaildocroot; ?>/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
	</Directory>

</VirtualHost>

<?php
					} else {
?>

## No mail map for parked '<?php echo $parkdomainname; ?>'

<?php
					}
				}
			}
		}

		if ($domainredirect) {
			foreach ($domainredirect as $domredir) {
				$redirdomainname = $domredir['redirdomain'];
				$webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

				if ($disabled) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName webmail.<?php echo $redirdomainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $disablepath; ?>"

	DirectoryIndex <?php echo $indexorder; ?>

<?php
					if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
						if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
						}
?>
	</IfModule>
<?php
					} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
					}
?>

	<IfModule suexec.c>
		SuexecUserGroup apache apache
	</IfModule>

	<IfModule mod_suphp.c>
		SuPhp_UserGroup apache apache
	</IfModule>

	#<IfVersion < 2.4>
		<IfModule mod_ruid2.c>
			RMode config
			RUidGid apache apache
			RMinUidGid apache apache
		</IfModule>

		<IfModule itk.c>
			AssignUserId apache apache
		</IfModule>

		<IfModule mod_fastcgi.c>
			Alias /webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake "<?php echo $disablepath; ?>/webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake"
			#FastCGIExternalServer "<?php echo $disablepath; ?>/webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmportapache; ?> -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			FastCGIExternalServer "<?php echo $disablepath; ?>/webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake" -socket /opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			<FilesMatch \.php$>
				SetHandler application/x-httpd-fastphp
			</FilesMatch>
			Action application/x-httpd-fastphp /webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake
			<Files "webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake">
				RewriteCond %{REQUEST_URI} !webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake
			</Files>
		</IfModule>

		<IfModule !mod_ruid2.c>
			<IfModule !mod_itk.c>
				<IfModule !mod_fastcgi.c>
					<IfModule mod_fcgid.c>
						FcgidIOTimeout <?php echo $timeout; ?>

						<Directory "<?php echo $disablepath; ?>/">
							Options +ExecCGI
							<FilesMatch \.php$>
								SetHandler fcgid-script
							</FilesMatch>
							FCGIWrapper /home/kloxo/client/php.fcgi .php
						</Directory>
					</IfModule>
				</IfModule>
			</IfModule>	
		</IfModule>
	#</IfVersion>

	<IfVersion >= 2.4>
		<IfModule mod_proxy_fcgi.c>
			ProxyRequests Off
			ProxyErrorOverride On
			ProxyPass /error !
			ErrorDocument 500 /error/500.html
			<FilesMatch \.php$>
				SetHandler "proxy:unix:/opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock|fcgi://localhost"
			</FilesMatch>
			<Proxy "fcgi://localhost">
				ProxySet timeout=<?php echo $timeout; ?>

				ProxySet connectiontimeout=<?php echo $timeout; ?>

				#ProxySet enablereuse=on
				ProxySet max=25
				ProxySet retry=0
			</Proxy>
		</IfModule>
	</IfVersion>

	<Location "/">
		Options -Indexes -FollowSymlinks +SymLinksIfOwnerMatch
	</Location>

	<Directory "<?php echo $disablepath; ?>/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
	</Directory>

</VirtualHost>

<?php
				} else {
					if ($webmailremote) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName webmail.<?php echo $redirdomainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $webmaildocroot; ?>"

	Redirect "/" "<?php echo $protocol; ?><?php echo $webmailremote; ?>"
<?php
						if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
							if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
							}
?>
	</IfModule>
<?php
						} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
						}
?>

</VirtualHost>

<?php
					} elseif ($webmailmap) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
<VirtualHost ${ip}:<?php echo $portlist[$count]; ?> >

	SetEnvIf X-Forwarded-Proto https HTTPS=1

	ServerName webmail.<?php echo $redirdomainname; ?>


	Include <?php echo $globalspath; ?>/<?php echo $acmechallenge; ?>.conf

	DocumentRoot "<?php echo $webmaildocroot; ?>"

	DirectoryIndex <?php echo $indexorder; ?>

<?php
						if ($count !== 0) {
?>

	<IfModule mod_http2.c>
		Protocols h2 http/1.1
	</IfModule>

	<IfModule mod_ssl.c>
		Include <?php echo $globalspath; ?>/<?php echo $ssl_base; ?>.conf

		SSLCertificateFile <?php echo $certname; ?>.pem
		SSLCertificateKeyFile <?php echo $certname; ?>.key
<?php
							if (file_exists("{$certname}.ca")) {
?>
		SSLCACertificatefile <?php echo $certname; ?>.ca

		Include <?php echo $globalspath; ?>/<?php echo $header_base; ?>.conf
<?php
							}
?>
	</IfModule>
<?php
						} else {
?>

	<IfModule mod_http2.c>
		Protocols h2c http/1.1
	</IfModule>
<?php
						}
?>

	<IfModule suexec.c>
		SuexecUserGroup apache apache
	</IfModule>

	<IfModule mod_suphp.c>
		SuPhp_UserGroup apache apache
	</IfModule>

	#<IfVersion < 2.4>
		<IfModule mod_ruid2.c>
			RMode config
			RUidGid apache apache
			RMinUidGid apache apache
		</IfModule>

		<IfModule itk.c>
			AssignUserId apache apache
		</IfModule>

		<IfModule mod_fastcgi.c>
			Alias /webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake "<?php echo $webmaildocroot; ?>/webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake"
			#FastCGIExternalServer "<?php echo $webmaildocroot; ?>/webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmportapache; ?> -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			FastCGIExternalServer "<?php echo $webmaildocroot; ?>/webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake" -socket /opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock -idle-timeout <?php echo $timeout; ?> -pass-header Authorization
			<FilesMatch \.php$>
				SetHandler application/x-httpd-fastphp
			</FilesMatch>
			Action application/x-httpd-fastphp /webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake
			<Files "webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake">
				RewriteCond %{REQUEST_URI} !webmail.<?php echo $redirdomainname; ?>.<?php echo $count; ?>fake
			</Files>
		</IfModule>

		<IfModule !mod_ruid2.c>
			<IfModule !mod_itk.c>
				<IfModule !mod_fastcgi.c>
					<IfModule mod_fcgid.c>
						FcgidIOTimeout <?php echo $timeout; ?>

						<Directory "<?php echo $webmaildocroot; ?>/">
							Options +ExecCGI
							<FilesMatch \.php$>
								SetHandler fcgid-script
							</FilesMatch>
							FCGIWrapper /home/kloxo/client/php.fcgi .php
						</Directory>
					</IfModule>
				</IfModule>
			</IfModule>	
		</IfModule>
	#</IfVersion>

	<IfVersion >= 2.4>
		<IfModule mod_proxy_fcgi.c>
			ProxyRequests Off
			ProxyErrorOverride On
			ProxyPass /error !
			ErrorDocument 500 /error/500.html
			<FilesMatch \.php$>
				SetHandler "proxy:unix:/opt/configs/php-fpm/sock/<?php echo $phpselected; ?>-apache.sock|fcgi://localhost"
			</FilesMatch>
			<Proxy "fcgi://localhost">
				ProxySet timeout=<?php echo $timeout; ?>

				ProxySet connectiontimeout=<?php echo $timeout; ?>
				#ProxySet enablereuse=on
				ProxySet max=25
				ProxySet retry=0
			</Proxy>
		</IfModule>
	</IfVersion>
	
	<Location "/">
		Options -Indexes -FollowSymlinks +SymLinksIfOwnerMatch
	</Location>

	<Directory "<?php echo $webmaildocroot; ?>/">
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			Allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
	</Directory>

</VirtualHost>

<?php
					} else {
?>

## No mail map for redirect '<?php echo $redirdomainname; ?>'

<?php
					}
				}
			}
		}

		$count++;
	}
}
?>

### end - web of '<?php echo $domainname; ?>' - do not remove/modify this line
