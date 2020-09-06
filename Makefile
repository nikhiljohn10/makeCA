HOSTNAME   := make
DOMAIN     := ca
ROOT_DIR   := /root/ca
INTER_DIR  := /root/ca/intermediate
FQDN       := $(HOSTNAME).$(DOMAIN)
CERT_FQDN  := ""
PASSPHRASE := ""
test:
	@sudo echo "$(FQDN)"

cleanall:
	@sudo rm -rf $(ROOT_DIR)

clean-inter:
	@sudo rm -rf $(INTER_DIR)

setup-root:
	@sudo mkdir -p $(UNIFI_DIR)/ $(ROOT_DIR)/certs $(ROOT_DIR)/crl $(ROOT_DIR)/newcerts $(ROOT_DIR)/private
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
	@sudo openssl req -config $(ROOT_DIR)/openssl.cnf -new -sha256 -key $(ROOT_DIR)/private/ca.key.pem -x509 -days 7300 -extensions v3_ca -out $(ROOT_DIR)/certs/ca.cert.pem

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
	@sudo openssl req -config $(INTER_DIR)/openssl.cnf -new -sha256 -key $(INTER_DIR)/private/intermediate.key.pem -out $(INTER_DIR)/csr/intermediate.csr.pem
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
ifneq ($(PASSPHRASE), "")
	@sudo openssl genrsa -aes256 -passout pass:$(PASSPHRASE) -out $(INTER_DIR)/private/$(FQDN).key.pem 2048
	@sudo chmod 400 $(INTER_DIR)/private/$(FQDN).key.pem
else
	@sudo echo "PASSPHRASE argument needed"
endif

csr:
	@sudo openssl req -config $(INTER_DIR)/openssl.cnf -key $(INTER_DIR)/private/$(FQDN).key.pem -new -sha256 -out $(INTER_DIR)/csr/$(FQDN).csr.pem

pem:
	@sudo openssl ca -config $(INTER_DIR)/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in $(INTER_DIR)/csr/$(FQDN).csr.pem -out $(INTER_DIR)/certs/$(FQDN).cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/$(FQDN).cert.pem

verify:
	@sudo openssl x509 -noout -text -in $(INTER_DIR)/certs/$(FQDN).cert.pem
	@sudo openssl verify -CAfile $(INTER_DIR)/certs/ca-chain.cert.pem $(INTER_DIR)/certs/$(FQDN).cert.pem
	@sudo echo
	@sudo echo "    Private Key: $(INTER_DIR)/private/$(FQDN).key.pem"
	@sudo echo "    Public Key: $(INTER_DIR)/certs/$(FQDN).cert.pem"
	@sudo echo "    CA Chain: $(INTER_DIR)/certs/ca-chain.cert.pem"
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

intermediate: clean-inter setup-inter inter-key inter-ca inter-verify ca-chain

certi: key csr pem verify

.PHONY: root intermediate certi ca-chain crl crl-point revoke-crl cleanall clean-inter