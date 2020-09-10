
ROOT_DIR        := /root/ca
INTER_DIR       := /root/ca/intermediate
UNIFI_DIR       := /usr/lib/unifi

UNIFI_KEYSTORE  := $(UNIFI_DIR)/data/keystore
UNIFI_CSR       := $(UNIFI_DIR)/data/unifi_certificate.csr.pem
UNIFI_PASS      := aircontrolenterprise

# Edit the following variables as required
UNIFI_FQDN      := UniFi
UNIFI_COUNTRY   := New York
UNIFI_STATE     := New York
UNIFI_CITY      := New York
UNIFI_ORG       := Ubiquiti Inc.

.PHONY: unifi
unifi:
	@sudo echo "Generating Unifi CSR"
	@sudo java -jar $(UNIFI_DIR)/lib/ace.jar new_cert "$(UNIFI_FQDN)" "$(UNIFI_ORG)" "$(UNIFI_CITY)" "$(UNIFI_STATE)" "$(UNIFI_COUNTRY)"
	@sudo echo "Generating certificate and signing using Unifi certificate signing request"
	@sudo openssl ca -config $(INTER_DIR)/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in $(UNIFI_CSR) -out $(INTER_DIR)/certs/$(UNIFI_FQDN).cert.pem
	@sudo echo "Configuring permissions"
	@sudo chmod 755 $(INTER_DIR)/certs/$(UNIFI_FQDN).cert.pem
	@sudo echo "Certificate for $(UNIFI_FQDN) os created"
	@sudo echo "Importing certificate into Unifi Controller"
	@sudo keytool -import -trustcacerts -alias root -file $(ROOT_DIR)/certs/ca.cert.pem -keystore $(UNIFI_KEYSTORE) -storepass $(UNIFI_PASS)
	@sudo keytool -import -trustcacerts -alias intermediate -file $(INTER_DIR)/certs/intermediate.cert.pem -keystore $(UNIFI_KEYSTORE) -storepass $(UNIFI_PASS)
	@sudo keytool -import -trustcacerts -alias unifi -file $(INTER_DIR)/certs/$(UNIFI_FQDN).cert.pem -keystore $(UNIFI_KEYSTORE) -storepass $(UNIFI_PASS)
	@sudo echo "Unifi import completed"
	@sudo echo "Restarting Unifi"
	@sudo service unifi restart
	@sudo echo "Successfully updated new SSL Certificate in your Unifi Controller"
