---
layout: default
title: "SSL: Managing Node Certificates With the Puppet CA"
canonical: "/puppet/latest/reference/ssl_manage.html"
---



> Box at top: link to the SSL background stuff, it's at /background/ssl/index.html. explain that you can work with Puppet's security by just remembering the commands, but you'll find things easier to learn and remember if you have a working understanding of what SSL actually is.


Intro: basically, Puppet needs certificates and the built-in CA makes it fairly simple to manage them. If you use an external CA, you have to do a bunch of stuff manually that otherwise happens automatically.

There are really only two or three things most people need to do with certificates:

* Get new credentials (to add a new agent node)
* Revoke and clean a node's credentials
* Get new credentials for some external system that can't automatically talk to the Puppet CA the way Puppet agent can.

## Getting New Credentials for an Agent Node (needs better title)

A new agent node starts with no credentials at all. (Unless your provisioning process puts some into place.) It needs a certificate to start managing a machine.

The steps to get these credentials are:

1. Start the Puppet agent service. It will automatically request a certificate and start polling to see if one is ready.
2. Use the Puppet CA to sign the certificate.

### Requesting a Certificate

Puppet agent will try to talk to a CA server, using the Puppet CA API (link to api docs). It contacts the server designated in its `ca_server` setting (defaults to value of `server` setting).

Once a CSR is submitted, Puppet agent will repeatedly try to retrieve a signed certificate, waiting a short while between attempts as specified by [the `waitforcert` setting](/references/latest/configuration.html#waitforcert)(defaults to every 2 minutes).

#### Unique Data in an Agent CSR

* name
* attributes and extensions
* alternate DNS names

Puppet agent requests a certificate by name, using the value of its `certname` setting. This is the Subject CN it will request for its certificate. (If that name isn't unique and there's already a signed certificate by that name, it might fetch a certificate it won't be able to use, since it won't have the corresponding private key.)

If there's a `csr_attributes.yaml` file present (link), Puppet agent will add any specified attributes to its CSR and request any specified extensions in its final certificate.

If the `dns_alt_names` setting has a value, Puppet agent will request those alt names in its certificate. (Useful for requesting a new Puppet master certificate for a non-CA master.)

### Signing a Certificate

When the CA receives a CSR via its API, it stores it and awaits a decision re: signing it.

There are a few ways the CA can sign a cert:

* Autosigning, which happens immediately. link to autosigning docs for full details.
* Admin user using `puppet cert` command
* Admin user using PE console node manager
* Trusted certificate making requests to the `certificate_status` API endpoint.

#### Signing Certs With `puppet cert`

* can be run by an admin user w/ appropriate sudo privs on the Puppet CA server.
* use `puppet cert list` to see info about outstanding unsigned cert requests
    * (`puppet cert list --all` to see all certificates as well as unsigned requests)
* `puppet cert sign <NAME>` to sign a request
    * `puppet cert sign --all` to sign all outstanding requests
* `puppet cert sign --allow-dns-alt-names <NAME>` to sign a request that includes one or more alternate DNS names
    * this is extra security to make it harder to sign a cert that could potentially impersonate a puppet master.

Also, here's an example of puppet cert list, including one request with alt names. (change the names to be plausible thing.example.com names.)

    "boo.fakepie.lan"                 (SHA256) F3:9C:52:73:B9:5D:E2:3F:83:6A:6A:EE:75:91:C6:A8:C7:D6:1B:32:77:38:91:4E:F3:F4:F6:4C:96:79:B9:D1
    "has_alts"                        (SHA256) 64:D7:FF:62:76:3D:30:1C:70:70:EF:74:66:EE:2A:7C:35:B7:B8:B3:02:A7:1F:16:6E:FC:C7:35:D4:CB:B7:FD (alt names: "DNS:first", "DNS:has_alts", "DNS:second", "DNS:third.example.com")
    "muckpie.lan"                     (SHA256) C9:A9:1C:B4:85:C7:1C:E4:61:88:53:02:2A:C6:9B:38:90:CD:F6:D8:27:03:E2:65:62:49:76:00:97:1E:93:0C
    "test-attributes-now2.magpie.lan" (SHA256) FA:E9:DF:6F:F5:43:47:7E:9B:9C:74:80:45:E4:78:9D:1B:B4:3D:AE:1A:31:C0:88:1E:85:E9:BB:8A:72:05:63
    "uhetnaoeu"                       (SHA256) FF:4D:46:BE:67:B8:D2:B8:A1:26:DC:B0:86:8E:D6:79:36:EB:EB:50:4E:7C:4E:6B:6E:E5:56:F3:02:04:C6:FD


#### signing certs with PE console

link to the main docs.

#### signing certs with `certificate_status`

link to the API docs.




## Revoking and Cleaning a Node's Credentials














## Workflow: recovering from weird problems

maybe this part should be its own whole page, because it's not part of the normal course of events. What do you think?

### Gory Details

here's what actually happens during the agent credentials process:

1. agent checks for CA cert and CRL on disk.
    - If found, continue to step 2
    - if not found, retrieve them and then continue to step 2
3. agent checks for its certificate on disk
    - if found, we're done! Skip to step 6.
    - if not found, continue to step 4.
2. agent checks for its own private key on disk
    - if found, continue to step 3
    - if not found, generate a key pair and then continue to step 3.
4. agent checks for its own CSR on disk.
    - if found, we've already submitted a CSR to the CA; don't submit it again, and continue to step 5.
    - if not found, agent requests a copy of its own CSR from the CA server with the CA API.
        - if found, we've already submitted a CSR to the CA but somehow forgot about it; download the forgotten CSR, store it for later, don't submit it again, and continue to step 5.
        - if not found, we've never submitted a CSR to the CA. Construct a new CSR, store it for later, and submit it to the CA server using the CA API. continue to step 5.
5. Agent requests a signed certificate from the CA server.
    - if found, retrieve it and store it, then continue to step 6.
    - If not found, the CA hasn't signed a cert for us. If `waitforcert` is set to 0, exit now; otherwise, wait the specified amount of time and repeat this step.
6. Use your private key and signed certificate to start a client-verified HTTPS session with the Puppet master, and do a regular catalog request and agent run.

Okay, so there are a few places to go wrong here. To ID them, you kind of have to be ULTRA LITERAL when reading these steps, because it will do exactly what they say without thinking about why it's doing them.

### Certificate / Private Key Mismatch

    Error: Could not request certificate: The certificate retrieved from the master does not match the agent's private key.

This happens at step 6.

If you get this error, the agent found a signed certificate during either step 3 or step 5, but it doesn't match the private key it found in step 2.