---
layout: default
title: "SSL: Revoking and Deleting Node Certificates With the Puppet CA"
canonical: "/puppet/latest/reference/ssl_remove_certs.html"
---


Two main concerns here:

* un-trust the old cert. usually not urgent, unless the private key was stolen at some point, but it's considered good hygiene.
* clear a spot, so that the CA won't mess things up if another node tries to request a cert by the same name sometime in the future.

The second one is easy, but comprehensively un-trusting a cert is a bit more complicated. a lot of people don't bother, and puppet doesn't make it as easy as getting new certs.

Cleaning/revoking a cert accomplishes the second goal and a tiny part of the first one. Updating CRLs is the long annoying step that accomplishes the rest of the first goal.

## Cleaning a Certificate

This can only be done on the CLI or with the API; the pe console can't do it.

### On the CLI

On the CA server, an admin user with appropriate sudo privileges can run:

    puppet cert clean <NAME>

This revokes the certificate (updating the CA's copy of the CRL) and deletes everything else the CA knows about it. You can now issue a new certificate with the same name to a new node, if you need to.

### With the CA API

Two steps to accomplish the same thing with the CA API:

* Do a PUT request to the `certificate_status` API, using the name of the cert as the key, with a request body of `{"desired_state":"revoked"}`.
* Do a DELETE request to the `certificate_status` API, using the name of the cert as the key.

## Updating CRLs

Puppet agent and Puppet Server never _automatically_ update the certificate revocation list with the latest info from the CA. They only fetch the CRL if it's not present on disk.

This means when you revoke a certificate, only the CA knows it's revoked at first. For Puppet Server or Puppet agent to reject that certificate, you need to manually update the CRLs.

### For Puppet Agent

* Either delete the CRL from the SSLdir (it'll automatically grab a replacement the next time Puppet agent starts up), or manually copy a new one into place (which is more secure, since I think Puppet agent doesn't check the validity of the server when fetching a CRL).
* Restart the Puppet agent service.

### For Puppet Server

* Manually copy a new CRL into the SSLdir.
* Restart Puppet Server.


