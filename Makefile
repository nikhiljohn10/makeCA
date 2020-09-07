HOSTNAME   := make
DOMAIN     := ca
ROOT_DIR   := /root/ca
INTER_DIR  := /root/ca/intermediate
FQDN       := $(HOSTNAME).$(DOMAIN)
CERT_FQDN  := ""

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

	/root/ca
	├── certs
	│   └── ca.cert.pem ( RootCA Certificate )
	├── crl
	├── index.txt
	├── index.txt.attr
	├── index.txt.old
	├── intermediate
	│   ├── certs
	│   │   ├── ca-chain.cert.pem ( Chain of Certificates )
	│   │   ├── dhparam2048.pem ( 2048 bit Diffie-Hellman Certificate )
	│   │   ├── intermediate.cert.pem ( IntermediateCA Certificate )
	│   │   └── make.ca.cert.pem ( Server Certificate )
	│   ├── crl
	│   ├── crlnumber
	│   ├── csr
	│   │   ├── intermediate.csr.pem ( IntermediateCA Signing Request )
	│   │   └── make.ca.csr.pem ( Server Signing Request )
	│   ├── index.txt
	│   ├── index.txt.attr
	│   ├── index.txt.old
	│   ├── newcerts
	│   │   └── 1000.pem
	│   ├── openssl.cnf ( IntermediateCA Configuration )
	│   ├── private
	│   │   ├── intermediate.key.pem ( IntermediateCA Private Key )
	│   │   └── make.ca.key.pem ( Server Private Key )
	│   ├── serial
	│   └── serial.old
	├── newcerts
	│   └── 1000.pem
	├── openssl.cnf ( RootCA Configuration )
	├── private
	│   └── ca.key.pem ( RootCA Certificate )
	├── serial
	└── serial.old
endef

export DIR_TREE

help:
	@echo "Welcome to Certificate Authority Generator"
	@echo
	@echo "Please use 'sudo make <target>' where <target> is one of"
	@echo "  root             to generate Root CA"
	@echo "  intermediate     to generate Intermediate CA"
	@echo "  server FQDN=<x>  to generate Certificate and Private key for the corresponding FQDN"
	@echo "  quick FQDN=<x>   to generate Certificate and Private key for the corresponding FQDN without Passphrase"
	@echo
	@echo "Default FQDN is '$(FQDN)'. Use FQDN=<x> after 'make' command where '<x>' is your domain name"
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
	@sudo mkdir -p $(ROOT_DIR)/certs $(ROOT_DIR)/crl $(ROOT_DIR)/newcerts $(ROOT_DIR)/private
	@sudo chmod 700 $(ROOT_DIR)/private
	@sudo touch $(ROOT_DIR)/index.txt
	@sudo echo 1000 > $(ROOT_DIR)/serial
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
	@sudo openssl req -new -sha256 -x509 -config $(ROOT_DIR)/openssl.cnf -key $(ROOT_DIR)/private/ca.key.pem -days 7300 -extensions v3_ca -out $(ROOT_DIR)/certs/ca.cert.pem -subj ROOT_SUBJ

root-verify:
	@sudo echo
	@sudo echo "    Verifing Root Public key"
	@sudo echo
	@sudo openssl x509 -noout -text -in $(ROOT_DIR)/certs/ca.cert.pem

setup-inter:
	@sudo mkdir -p $(INTER_DIR)/certs $(INTER_DIR)/crl $(INTER_DIR)/csr $(INTER_DIR)/newcerts $(INTER_DIR)/private 
	@sudo chmod 700 $(INTER_DIR)/private
	@sudo touch $(INTER_DIR)/index.txt
	@sudo echo 1000 > $(INTER_DIR)/serial
	@sudo echo 1000 > $(INTER_DIR)/crlnumber
	@sudo cp config/intermediate.cnf $(INTER_DIR)/openssl.cnf

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
	@sudo openssl req -config $(INTER_DIR)/openssl.cnf -new -sha256 -key $(INTER_DIR)/private/intermediate.key.pem -out $(INTER_DIR)/csr/intermediate.csr.pem -subj INTER_SUBJ
	@sudo openssl ca -config $(ROOT_DIR)/openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in $(INTER_DIR)/csr/intermediate.csr.pem -out $(INTER_DIR)/certs/intermediate.cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/intermediate.cert.pem

inter-verify:
	@sudo echo
	@sudo echo "    Verifing Intermediate Public key"
	@sudo echo
	@sudo openssl x509 -noout -text -in $(INTER_DIR)/certs/intermediate.cert.pem
	@sudo openssl verify -CAfile $(ROOT_DIR)/certs/ca.cert.pem $(INTER_DIR)/certs/intermediate.cert.pem

ca-chain:
	@sudo echo
	@sudo echo "    Generating Chain of Certificate"
	@sudo echo
	@sudo cat $(INTER_DIR)/certs/intermediate.cert.pem $(ROOT_DIR)/certs/ca.cert.pem > $(INTER_DIR)/certs/ca-chain.cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/ca-chain.cert.pem
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

dhparam:
	@sudo echo
	@sudo echo "    Generating 2048 bit Diffie-Hellman Certificate"
	@sudo echo
	@sudo openssl dhparam -outform pem -out $(INTER_DIR)/certs/dhparam2048.pem 2048

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

crl-point:
ifneq ($(CERT_FQDN), "")
	@sudo openssl x509 -in $(INTER_DIR)/certs/$(CERT_FQDN).cert.pem -noout -text
else
	@sudo echo "CERT_FQDN argument needed"
endif

revoke-crl: crl-point
ifneq ($(CERT_FQDN), "")
	@sudo openssl ca -config $(INTER_DIR)/openssl.cnf -revoke $(INTER_DIR)/certs/$(CERT_FQDN).cert.pem
else
	@sudo echo "CERT_FQDN argument needed"
endif

root: cleanall setup-root root-key root-ca root-verify

intermediate: cleanin setup-inter inter-key inter-ca inter-verify ca-chain

ca: dhparam root intermediate

server: clean key csr pem verify

quick: clean keyless pem verify

publish:
	@sudo rm -rf dist
	@sudo mkdir dist
	@sudo cp $(ROOT_DIR)/certs/ca.cert.pem ./dist
	@sudo sudo find /root/ca/intermediate/certs -type f \( ! -name 'dhparam2048.pem' -name '*.pem' \) -exec cp -at ./dist {} +
	@sudo find ./dist/ -name '*.pem' -exec sh -c 'x="{}"; y=$$\(echo "$$x" | sed -e "s/pem$/crt/"\); mv "$$x" "$$y"' \;
	@sudo chown -R $(whoami):$(whoami) dist
	@cd dist && python3 -m http.server 9090

.PHONY: ca server quick crl crl-point revoke-crl publish