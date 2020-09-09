HOSTNAME   := make
DOMAIN     := ca
ROOT_DIR   := /root/ca
SSL_DIR    := /root/ssl
INTER_DIR  := /root/ca/intermediate
FQDN       := $(HOSTNAME).$(DOMAIN)
RVK_FQDN   := ""
CRL_URI    := http://$(FQDN)/intermediate.crl.pem

COUNTRY    := IN
STATE      := Kerala
LOCATION   := Thrissur
ORG        := Jwala Diamonds
ORG_UNIT   := Jwala Diamonds Certificate Authority
ROOT_CN    := Jwala Diamonds Root CA
INTER_CN   := Jwala Diamonds Intermediate CA

ROOT_SUBJ  := "/C=$(COUNTRY)/ST=$(STATE)/L=$(LOCATION)/O=$(ORG)/OU=$(ORG_UNIT)/CN=$(ROOT_CN)"
INTER_SUBJ := "/C=$(COUNTRY)/ST=$(STATE)/L=$(LOCATION)/O=$(ORG)/OU=$(ORG_UNIT)/CN=$(INTER_CN)"

define DIR_TREE

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

endef

export DIR_TREE

help:
	@echo "Welcome to Certificate Authority Generator"
	@echo
	@echo "Please use 'sudo make <target>' where <target> is one of"
	@echo "  root                   to generate Root CA"
	@echo "  intermediate           to generate Intermediate CA"
	@echo "  server FQDN=<x>        to generate Certificate and Private key for the corresponding FQDN"
	@echo "  quick FQDN=<x>         to generate Certificate and Private key for the corresponding FQDN without Passphrase"
	@echo "  crl                    to generate CRL"
	@echo "  rvk-crl RVK_FQDN=<x>   to revoke a domain"
	@echo "  rvk-show RVK_FQDN=<x>  to show list of revoked domains"
	@echo
	@echo "Default FQDN is '$(FQDN)'. Use FQDN=<x> after 'make' target where '<x>' is your domain name"
	@echo "Default RVK_FQDN is ''. Use RVK_FQDN=<x> after 'make' target where '<x>' is your domain name"
	@echo
	@echo "Tree Structure:"
	@echo "$$DIR_TREE"
	@echo

cleanall:
	@sudo rm -rf $(ROOT_DIR)

cleanin:
	@sudo rm -rf $(INTER_DIR)

clean:
	@sudo rm -rf $(INTER_DIR)/certs/$(FQDN).chain.pem  $(INTER_DIR)/certs/$(FQDN).cert.pem $(INTER_DIR)/csr/$(FQDN).csr.pem $(INTER_DIR)/private/$(FQDN).key.pem

setup-root:
	@sudo mkdir -p $(ROOT_DIR)/certs $(ROOT_DIR)/crl $(ROOT_DIR)/newcerts $(ROOT_DIR)/private $(ROOT_DIR)/db
	@sudo chmod 700 $(ROOT_DIR)/private
	@sudo touch $(ROOT_DIR)/db/index.txt
	@sudo echo 1000 > $(ROOT_DIR)/db/serial
	@sudo cp config/root.cnf $(ROOT_DIR)/openssl.cnf

root-key:
	@sudo echo
	@sudo echo "    Generating Root Private key"
	@sudo echo
	@sudo openssl genrsa -aes256 -out $(ROOT_DIR)/private/ca.key.pem 4096
	@sudo chmod 400  $(ROOT_DIR)/private/ca.key.pem

root-ca:
	@sudo echo
	@sudo echo "    Generating Root Public key"
	@sudo echo
	@sudo openssl req -new -sha256 -x509 -config $(ROOT_DIR)/openssl.cnf -key $(ROOT_DIR)/private/ca.key.pem -days 7300 -extensions v3_ca -out $(ROOT_DIR)/certs/ca.cert.pem -subj $(ROOT_SUBJ)

root-verify:
	@sudo echo
	@sudo echo "    Verifying Root Public key"
	@sudo echo
	@sudo openssl x509 -noout -text -in $(ROOT_DIR)/certs/ca.cert.pem

setup-inter:
	@sudo mkdir -p $(INTER_DIR)/certs $(INTER_DIR)/crl $(INTER_DIR)/csr $(INTER_DIR)/newcerts $(INTER_DIR)/private $(INTER_DIR)/db
	@sudo chmod 700 $(INTER_DIR)/private
	@sudo touch $(INTER_DIR)/db/index.txt
	@sudo echo 1000 > $(INTER_DIR)/db/serial
	@sudo echo 1000 > $(INTER_DIR)/db/crlnumber
	@sudo sed -e 's/{YOUR_CRL_URI}/$(subst /,\/,$(CRL_URI))/' config/intermediate.cnf > $(INTER_DIR)/openssl.cnf

inter-key:
	@sudo echo
	@sudo echo "    Generating Intermediate Private key"
	@sudo echo
	@sudo openssl genrsa -aes256 -out $(INTER_DIR)/private/intermediate.key.pem 4096
	@sudo chmod 400 $(INTER_DIR)/private/intermediate.key.pem

inter-ca:
	@sudo echo
	@sudo echo "    Generating Intermediate Public key"
	@sudo echo
	@sudo openssl req -config $(INTER_DIR)/openssl.cnf -new -sha256 -key $(INTER_DIR)/private/intermediate.key.pem -out $(INTER_DIR)/csr/intermediate.csr.pem -subj $(INTER_SUBJ)
	@sudo openssl ca -config $(ROOT_DIR)/openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in $(INTER_DIR)/csr/intermediate.csr.pem -out $(INTER_DIR)/certs/intermediate.cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/intermediate.cert.pem

inter-verify:
	@sudo echo
	@sudo echo "    Verifying Intermediate Public key"
	@sudo echo
	@sudo openssl x509 -noout -text -in $(INTER_DIR)/certs/intermediate.cert.pem
	@sudo openssl verify -CAfile $(ROOT_DIR)/certs/ca.cert.pem $(INTER_DIR)/certs/intermediate.cert.pem

ca-chain:
	@sudo echo
	@sudo echo "    Generating Chain of Certificate"
	@sudo echo
	@sudo cat $(INTER_DIR)/certs/intermediate.cert.pem $(ROOT_DIR)/certs/ca.cert.pem > $(INTER_DIR)/certs/ca-chain.cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/ca-chain.cert.pem
	@sudo echo "Root Certificate: $(ROOT_DIR)/certs/ca.cert.pem"
	@sudo echo "Intermediate Certificate: $(INTER_DIR)/certs/intermediate.cert.pem"
	@sudo echo "Certificate Chain: $(INTER_DIR)/certs/ca-chain.cert.pem"

key:
	@sudo openssl genrsa -aes256 -out $(INTER_DIR)/private/$(FQDN).key.pem 2048
	@sudo chmod 400 $(INTER_DIR)/private/$(FQDN).key.pem

csr:
	@sudo openssl req -new -sha256 -config $(INTER_DIR)/openssl.cnf -key $(INTER_DIR)/private/$(FQDN).key.pem -out $(INTER_DIR)/csr/$(FQDN).csr.pem

keyless:
	@sudo openssl req -nodes -new -sha256 -config $(INTER_DIR)/openssl.cnf -keyout $(INTER_DIR)/private/$(FQDN).key.pem -out $(INTER_DIR)/csr/$(FQDN).csr.pem
	
pem:
	@sudo openssl ca -config $(INTER_DIR)/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in $(INTER_DIR)/csr/$(FQDN).csr.pem -out $(INTER_DIR)/certs/$(FQDN).cert.pem
	@sudo cat $(INTER_DIR)/certs/$(FQDN).cert.pem $(INTER_DIR)/certs/ca-chain.cert.pem > $(INTER_DIR)/certs/$(FQDN).chain.pem
	@sudo chmod 444 $(INTER_DIR)/certs/$(FQDN).cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/$(FQDN).chain.pem

verify:
	@sudo openssl x509 -noout -text -in $(INTER_DIR)/certs/$(FQDN).cert.pem
	@sudo openssl verify -CAfile $(INTER_DIR)/certs/ca-chain.cert.pem $(INTER_DIR)/certs/$(FQDN).cert.pem
	@sudo echo
	@sudo echo "    Certificate: $(INTER_DIR)/certs/$(FQDN).cert.pem"
	@sudo echo "    Certificate Chain: $(INTER_DIR)/certs/$(FQDN).chain.pem"
	@sudo echo "    Private Key: $(INTER_DIR)/private/$(FQDN).key.pem"
	@sudo echo

crl:
	@sudo openssl ca -config $(INTER_DIR)/openssl.cnf -gencrl -out $(INTER_DIR)/crl/intermediate.crl.pem
	@sudo openssl crl -in $(INTER_DIR)/crl/intermediate.crl.pem -noout -text

rvk-show:
ifneq ($(RVK_FQDN), "")
	@sudo openssl x509 -in $(INTER_DIR)/certs/$(RVK_FQDN).cert.pem -noout -text
else
	@sudo echo "RVK_FQDN argument needed"
endif

rvk-crl: rvk-show
ifneq ($(RVK_FQDN), "")
	@sudo openssl ca -config $(INTER_DIR)/openssl.cnf -revoke $(INTER_DIR)/certs/$(RVK_FQDN).cert.pem
else
	@sudo echo "RVK_FQDN argument needed"
endif

dh:
	@sudo echo
	@sudo echo "    Generating 2048 bit Diffie-Hellman (DH) Parameters"
	@sudo echo
	@sudo mkdir -p $(ROOT_DIR)
	@sudo openssl dhparam -outform pem -out $(ROOT_DIR)/private/dhparam2048.pem 2048
	@sudo echo
	@sudo echo "DH Parameters: $(ROOT_DIR)/private/dhparam2048.pem"
	@sudo echo

root: cleanall setup-root root-key root-ca root-verify

intermediate: cleanin setup-inter inter-key inter-ca inter-verify ca-chain

ca: root intermediate

server: clean key csr pem verify

quick: clean keyless pem verify

publish: crl
	@sudo mkdir -p $(ROOT_DIR)/web
	@sudo cp $(INTER_DIR)/crl/intermediate.crl.pem $(ROOT_DIR)/web/intermediate.crl.pem
	@sudo cp $(ROOT_DIR)/certs/ca.cert.pem $(ROOT_DIR)/web/ca.cert.crt
	@sudo find $(INTER_DIR)/certs -type f -name '*.pem' -exec cp -at $(ROOT_DIR)/web {} \;
	@sudo chmod -R 755 $(ROOT_DIR)/web

share:
	@sudo echo "Sharing certificates..."
	@cd $(ROOT_DIR)/web && python3 -m http.server 5555

.PHONY: ca server quick crl rvk-show rvk-crl dh publish
