# Make CertificateAuthority

Generate Root, Intermediate and Server certificates with CRL using Makefile

### Structure

<pre>
/root/ca/
    ├── certs
    │   └── ca.cert.pem ( RootCA Certificate )
    ├── crl
    ├── db
    │   ├── index.txt
    │   └── serial
    ├── intermediate
    │   ├── certs
    │   │   ├── ca-chain.cert.pem ( Chain of Certificates )
    │   │   ├── intermediate.cert.pem ( IntermediateCA Certificate )
    │   │   ├── make.ca.cert.pem ( Server Certificate )
    │   │   └── make.ca.chain.pem ( Server Certificate Chain )
    │   ├── crl
    │   │   └── intermediate.crl.pem ( Certificate revocation lists )
    │   ├── csr
    │   │   ├── intermediate.csr.pem ( IntermediateCA Signing Request )
    │   │   └── make.ca.csr.pem ( Server Signing Request )
    │   ├── db
    │   │   ├── crlnumber
    │   │   ├── index.txt
    │   │   └── serial
    │   ├── newcerts
    │   │   └── 1000.pem
    │   ├── openssl.cnf ( IntermediateCA Configuration )
    │   └── private
    │       ├── intermediate.key.pem ( IntermediateCA Private Key )
    │       └── make.ca.key.pem ( Server Private Key )
    ├── newcerts
    │   └── 1000.pem
    ├── openssl.cnf ( RootCA Configuration )
    ├── private
    │   ├── ca.key.pem ( RootCA Private key )
    │   └── dhparam2048.pem ( 2048 bit Diffie-Hellman Parameters )
    └── web
        ├── ca.cert.crt
        ├── ca-chain.cert.pem
        ├── intermediate.cert.pem
        ├── intermediate.crl.pem
        ├── make.ca.cert.pem
        └── make.ca.chain.pem

</pre>

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
