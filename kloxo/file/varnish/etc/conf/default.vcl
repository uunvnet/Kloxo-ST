backend default {
	.host = "127.0.0.1";
	.port = "8080";
}

backend default_ssl{
	.host = "127.0.0.1";
	.port = "8443";
}

sub vcl_recv {
	if (req.restarts == 0) {
		if (req.http.x-forwarded-for) {
			set req.http.X-Forwarded-For =
			req.http.X-Forwarded-For + ", " + client.ip;
		} else {
			set req.http.X-Forwarded-For = client.ip;
		}
	}

	# Set the director to cycle between web servers.
	if (server.port == 443) {
		set req.backend = default_ssl;
	} else {
		set req.backend = default;
	}

	if (req.request != "GET" &&
		req.request != "HEAD" &&
		req.request != "PUT" &&
		req.request != "POST" &&
		req.request != "TRACE" &&
		req.request != "OPTIONS" &&
		req.request != "DELETE") {
		/* Non-RFC2616 or CONNECT which is weird. */
		return (pipe);
	}

	if (req.request != "GET" && req.request != "HEAD") {
		/* We only deal with GET and HEAD by default */
		return (pass);
	}

	if (req.http.Authorization || req.http.Cookie) {
		/* Not cacheable by default */
		return (pass);
	}

	return (lookup);
}

sub vcl_pipe {
	return (pipe);
}

sub vcl_pass {
	return (pass);
}

sub vcl_hash {
	hash_data(req.url);

	if (req.http.host) {
		hash_data(req.http.host);
	} else {
		hash_data(server.ip);
	}

	return (hash);
}

sub vcl_hit {
	return (deliver);
}

sub vcl_miss {
	return (fetch);
}

sub vcl_fetch {
	if (beresp.ttl <= 0s ||
		beresp.http.Set-Cookie ||
		beresp.http.Vary == "*") {
		set beresp.ttl = 120s;
		set req.grace = 30s;
		set beresp.grace = 1h;
		return (hit_for_pass);
	}

	return (deliver);
}

sub vcl_deliver {
	return (deliver);
}

sub vcl_error {
	set obj.http.Content-Type = "text/html; charset=utf-8";
	set obj.http.Retry-After = "5";
	synthetic {"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>"} + obj.status + " " + obj.response + {"</title>
  </head>
  <body>
    <h1>Error "} + obj.status + " " + obj.response + {"</h1>
    <p>"} + obj.response + {"</p>
    <h3>Guru Meditation:</h3>
    <p>XID: "} + req.xid + {"</p>
    <hr>
    <p>Varnish cache server</p>
  </body>
</html>
"};
	return (deliver);
}

sub vcl_init {
	return (ok);
}

sub vcl_fini {
	return (ok);
}
