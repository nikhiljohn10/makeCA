NAME      := unifi
DOMAIN    := home
DURATION  := 5340

ROOT_DIR  := /root/ca
INTER_DIR := /root/ca/intermediate
UNIFI_DIR := $(ROOT_DIR)/$(NAME)

UNIFI_ACE := /usr/lib/unifi/lib/ace.jar
UNIFI_KEY := /usr/lib/unifi/data/keystore
UNIFI_CSR := /usr/lib/unifi/data/unifi_certificate.csr.pem

U_C      := "IN"
U_ST     := "Kerala"
U_L      := "Thrissur"
U_O      := "Happy Home CA"
U_E      := "me@nikz.in"
U_CN     := $(NAME).$(DOMAIN)

CERT_FQDN := ""

setup:
	@sudo mkdir -p $(UNIFI_DIR)/ $(ROOT_DIR)/certs $(ROOT_DIR)/crl $(ROOT_DIR)/newcerts $(ROOT_DIR)/private  $(INTER_DIR)/certs $(INTER_DIR)/crl $(INTER_DIR)/csr $(INTER_DIR)/newcerts $(INTER_DIR)/private 
	@sudo chmod 700 $(ROOT_DIR)/private
	@sudo chmod 700 $(INTER_DIR)/private
	@sudo touch $(ROOT_DIR)/index.txt
	@sudo touch $(INTER_DIR)/index.txt
	@sudo echo 1000 > $(ROOT_DIR)/serial
	@sudo echo 1000 > $(INTER_DIR)/serial
	@sudo echo 1000 > $(INTER_DIR)/crlnumber
	@sudo cp openssl.cnf $(ROOT_DIR)/openssl.cnf
	@sudo cp openssl.intermediate.cnf $(INTER_CNF)/openssl.cnf

root-key: setup
	@sudo echo
	@sudo echo "    Generating Root Private key"
	@sudo echo
	@sudo openssl genrsa -aes256 -out $(ROOT_DIR)/private/ca.key.pem 4096
	@sudo chmod 400  $(ROOT_DIR)/private/ca.key.pem

root-ca: root-key
	@sudo echo
	@sudo echo "    Generating Root Public key"
	@sudo echo
	@sudo openssl req -config $(ROOT_DIR)/openssl.cnf -new -sha256 -key $(ROOT_DIR)/private/ca.key.pem -x509 -days 7300 -extensions v3_ca -out $(ROOT_DIR)/certs/ca.cert.pem

root-verify: root-ca
	@sudo echo
	@sudo echo "    Verifing Root Public key"
	@sudo echo
	@sudo openssl x509 -noout -text -in $(ROOT_DIR)/certs/ca.cert.pem

inter-key: root-verify
	@sudo echo
	@sudo echo "    Generating Intermediate Private key"
	@sudo echo
	@sudo openssl genrsa -aes256 -out $(INTER_DIR)/private/intermediate.key.pem 4096
	@sudo chmod 400 $(INTER_DIR)/private/intermediate.key.pem

inter-ca: inter-key
	@sudo echo
	@sudo echo "    Generating Intermediate Public key"
	@sudo echo
	@sudo openssl req -config $(INTER_DIR)/openssl.cnf -new -sha256 -key $(INTER_DIR)/private/intermediate.key.pem -out $(INTER_DIR)/csr/intermediate.csr.pem
	@sudo openssl ca -config $(ROOT_DIR)/openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in $(INTER_DIR)/csr/intermediate.csr.pem -out $(INTER_DIR)/certs/intermediate.cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/intermediate.cert.pem

inter-verify: inter-ca
	@sudo echo
	@sudo echo "    Verifing Intermediate Public key"
	@sudo echo
	@sudo openssl x509 -noout -text -in $(INTER_DIR)/certs/intermediate.cert.pem
	@sudo openssl verify -CAfile $(ROOT_DIR)/certs/ca.cert.pem $(INTER_DIR)/certs/intermediate.cert.pem

ca-chain: inter-verify
	@sudo echo
	@sudo echo "Generating Chain of Certificate"
	@sudo echo
	@sudo cat $(INTER_DIR)/certs/intermediate.cert.pem $(ROOT_DIR)/certs/ca.cert.pem > $(INTER_DIR)/certs/ca-chain.cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/ca-chain.cert.pem

key:
	@sudo openssl genrsa -aes256 -out $(INTER_DIR)/private/$(U_CN).key.pem 2048
	@sudo chmod 400 $(INTER_DIR)/private/$(U_CN).key.pem

ca: key
	@sudo openssl req -config $(INTER_DIR)/openssl.cnf -key $(INTER_DIR)/private/$(U_CN).key.pem -new -sha256 -out $(INTER_DIR)/csr/$(U_CN).csr.pem
	@sudo openssl ca -config $(INTER_DIR)/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in $(INTER_DIR)/csr/$(U_CN).csr.pem -out $(INTER_DIR)/certs/$(U_CN).cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/$(U_CN).cert.pem

verify: ca
	@sudo openssl x509 -noout -text -in $(INTER_DIR)/certs/$(U_CN).cert.pem
	@sudo openssl verify -CAfile $(INTER_DIR)/certs/ca-chain.cert.pem $(INTER_DIR)/certs/$(U_CN).cert.pem
	@sudo echo
	@sudo echo "Private Key: $(INTER_DIR)/private/$(U_CN).key.pem"
	@sudo echo "Public Key: $(INTER_DIR)/certs/$(U_CN).cert.pem"
	@sudo echo "CA Chain: $(INTER_DIR)/certs/ca-chain.cert.pem"
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

revoke-crl:
ifneq ($(CERT_FQDN), "")
	@sudo openssl ca -config $(INTER_DIR)/openssl.cnf -revoke $(INTER_DIR)/certs/$(CERT_FQDN).cert.pem
else
	@sudo echo "CERT_FQDN argument needed"
endif

unifi-ssl: root-verify
	@sudo echo "Unifi SSL Updating"
	@sudo java -jar $(UNIFI_ACE) new_cert "$(U_CN)" "$(U_O)" "$(U_L)" "$(U_ST)" "$(U_C)"
	@sudo cat $(UNIFI_CSR) > $(UNIFI_DIR)/server.csr
	@sudo openssl x509 -req -in $(UNIFI_DIR)/server.csr -CA $(ROOT_DIR)/certs/ca.cert.pem -CAkey $(ROOT_DIR)/private/ca.key.pem -CAcreateserial -out $(UNIFI_DIR)/server.crt -days $(DURATION) -sha256 -extfile $(UNIFI_DIR)/v3.ext
	@sudo keytool -import -trustcacerts -alias root -file $(ROOT_DIR)/certs/ca.cert.pem -keystore $(UNIFI_KEY) -storepass aircontrolenterprise
	@sudo keytool -import -trustcacerts -alias unifi -file $(UNIFI_DIR)/server.crt -keystore $(UNIFI_KEY) -storepass aircontrolenterprise
	@sudo service unifi restart
	@sudo echo "Successfully updated new SSL Certificate in your Unifi Controller"
