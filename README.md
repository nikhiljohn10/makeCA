# Make CertificateAuthority

Generate Root, Intermediate and Server certificates using Makefile

### Usage

For generating rootCA certificate:
```
sudo make root
```

For generating intermediateCA certificate:
```
sudo make intermediate
```

For generating server certificate:
```
sudo make server FQDN=www.example.com
```

For generating server certificate without passphrase:
```
sudo make quick FQDN=www.example.com
```
