---
layout: default
title: "SSL: Overview of Puppet's HTTPS and CA Features"
canonical: "/puppet/latest/reference/ssl_overview.html"
---

[http_api]: (TODO: add link to https api docs)
[diagram_ca]: ./images/ssl_puppet_ca.jpg
[trusted]: ./lang_facts_and_builtin_vars.html#trusted-facts
[certificate extensions]: (todo: link cert extensions page)
[external ca]: (todo: link to external ca docs)
[server_ca]: /puppetserver/2.1/configuration.html#caconf
[ssldir]: todo
[autosign]: todo
[server_bootstrap]: todo


> Box at top: link to the SSL background stuff, it's at /background/ssl/index.html. explain that you can work with Puppet's security by just remembering the commands, but you'll find things easier to learn and remember if you have a working understanding of what SSL actually is.

Puppet secures its communications with **client-verified HTTPS.** It also includes built-in certificate authority (CA) tools to help manage node certificates.

(insert something here about how the practical workflow stuff is on another page.)

## Puppet's Use of HTTPS and Certificates

In the standard agent/master arrangement, agent nodes fetch configurations from a Puppet master server via [several HTTPS endpoints][http_api].

### CA Certificate

- Puppet doesn't use the built-in set of system CA certs. It uses its own.
- By default, there's just one CA that issues all certs for servers and agent nodes.
- In certain [external ca][] configurations, you can have one CA for masters and another for agents.

### Certificates for Puppet Master Servers

Every node has a `server` setting in puppet.conf; its value defaults to `puppet`. Puppet agent will try to contact a Puppet master at this hostname.

An agent will only trust the master if its certificate includes the value of that `server` setting. That name MUST be present in one of the following:

- The Subject CN (link to background: cert anatomy page)
- The X509v3 Subject Alternative Name field (link to background cert anatomy)

If a server has a certificate from the appropriate CA that lets it use that hostname, the agent will trust it completely.

### Certificates for Agent Nodes

Puppet agent needs a certificate to operate normally. See below for how it obtains one.

Puppet agent presents its certificate whenever it makes `catalog`, `node`, `report`, and `file_*` HTTPS requests. The server does two checks before allowing a request:

- It checks whether the cert is valid.
- It checks auth.conf to see whether this cert is allowed to make this request.

The rules in auth.conf are usually based on the certificate's Subject CN (often called the "certname"). For example, the default rules say that a node can only request a catalog with the same name as its certname.

#### Agent Cert Info in Manifests

Info from an agent's certificate is available in Puppet manifests via the `$trusted` variable. This hash usually just contains the agent's certname, but it also includes any [certificate extensions][] if those are in use.

### The Certificate Revocation List

Puppet agent and Puppet master both check certificates against a locally cached certificate revocation list (CRL) when validating them. See below for how this is distributed.





## The Puppet CA

Puppet needs a CA to function normally, since agents and masters both need signed certificates. By default, Puppet uses its own built-in CA, but you can disable it and use an [external CA][] instead.

The Puppet CA consists of the following components, running on a designated CA server:

* A collection of credentials, stored as directories of `.pem` files on the designated CA server. See [the reference page about the SSLdir for more info.][ssldir]
* Some HTTPS services, which allow agents to request certificates and, optionally, allow trusted clients to list, sign, and revoke certificates.
* A command-line tool, `puppet cert`, with which admin users can list, sign, and revoke certificates.
* [Autosigning configuration][autosign], which can approve incoming certificate signing requests (CSRs) that meet certain criteria.

By default, every Puppet master will act as a CA server; you should deliberately disable the CA service when using multiple Puppet masters. Do this by setting `ca = false` in puppet.conf and, if using Puppet Server, [disable the CA service in bootstrap.cfg][server_bootstrap]. Non-CA Puppet masters need to get a certificate from the CA, the same way an agent does; see the page on managing node certs (link).

![Diagram: a CA server has cert files, a CA API service that interacts with the files, CLI tools that interact with the files, and an autosigning policy that can interact with the files.][diagram_ca]

### The CA CLI Tools

- The main one is `puppet cert`. Link to man page. main actions are `list`, `sign`, `revoke`, `clean`, `generate`.
- There are some other cert-related command line tools: `puppet certificate`, `puppet certificate_request`, `puppet certificate_revocation_list`, and `puppet key`. Don't use them. They're basically incomplete interfaces to Puppet's internals; sometimes they act as clients to the CA service, and sometimes as local CA admin tools. They're only useful for certain weird workflows.


### The CA HTTPS Services

- Generally speaking, Puppet agent uses the CA API automatically, and you don't need to specifically interact with it. See the page about managing node certs. (link)
- The one service that's meant for users and non-agent tools is `certificate_status`. It's locked down by default, and you have to [selectively enable access in Puppet Server's ca.conf][server_ca] (or auth.conf for a Rack-based Puppet master).
- (Link to the HTTP API page) for more info
- Or just see the sidebar nav in this section.




