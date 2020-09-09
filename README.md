# Make CertificateAuthority

Generate Root, Intermediate and Server certificates with CRL using Makefile

### Usage

**All `make` commands require `sudo` privilege to execute properly**

Following are the `make` options:

| Command | Description |
|---|---|
| `make root` | Generate rootCA certificate |
| `make intermediate` | Generate intermediateCA certificate |
| `make ca` | Generate both rootCA and intermediateCA certificate |
| `make server [FQDN]` | Generate server certificate with passphrase for `FQDN` |
| `make quick [FQDN]` | Generate server certificate without passphrase for `FQDN` (NGINX need this) |
| `make dh` | Generate Diffie-Hellman Parameters for WebServer SSL Configuration |
| `make crl` | Generate Certificate revocation lists |
| `make info [FQDN]` | Show details about the certificate |
| `make rvk-crl RVK_FQDN` | Revoke the certificate from `RVK_FQDN` argument passed |
| `make publish` | Pool all the necessary certificates to be published |
| `make share` | Share the pooled certificates on localhost:5555 (This is only for development purpose) |

### Example

Let us make a CA and server certificate for `www.example.com`:

```
sudo make ca
sudo make dh
sudo make quick CRL_URI_PROTOCOL=https FQDN=www.example.com
sudo make publish
sudo make share
```
