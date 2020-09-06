
ROOT_DIR        := /root/ca
INTER_DIR       := /root/ca/intermediate

UNIFI_FQDN      := ""
UNIFI_COUNTRY   := "IN"
UNIFI_STATE     := "Kerala"
UNIFI_CITY      := "Thrissur"
UNIFI_ORG       := "Happy Home"
UNIFI_EMAIL     := "me@nikz.in"

.PHONY: unifi
unifi:
ifneq ($(UNIFI_FQDN), "")
	@sudo echo "Unifi SSL Updating"
	@sudo java -jar /usr/lib/unifi/lib/ace.jar new_cert "$(UNIFI_FQDN)" "$(UNIFI_ORG)" "$(UNIFI_CITY)" "$(UNIFI_STATE)" "$(UNIFI_COUNTRY)"
	@sudo openssl ca -config $(INTER_DIR)/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in /usr/lib/unifi/data/unifi_certificate.csr.pem -out $(INTER_DIR)/certs/$(UNIFI_FQDN).cert.pem
	@sudo chmod 444 $(INTER_DIR)/certs/$(UNIFI_FQDN).cert.pem
	@sudo echo "Certificate for $(UNIFI_FQDN)"
	@sudo cat $(INTER_DIR)/certs/$(UNIFI_FQDN).cert.pem
	@sudo keytool -import -trustcacerts -alias root -file $(ROOT_DIR)/certs/ca.cert.pem -keystore /usr/lib/unifi/data/keystore -storepass aircontrolenterprise
	@sudo keytool -import -trustcacerts -alias intermediate -file $(INTER_DIR)/certs/intermediate.cert.pem -keystore /usr/lib/unifi/data/keystore -storepass aircontrolenterprise
	@sudo keytool -import -trustcacerts -alias unifi -file $(INTER_DIR)/certs/$(UNIFI_FQDN).cert.pem -keystore /usr/lib/unifi/data/keystore -storepass aircontrolenterprise
	@sudo service unifi restart
	@sudo echo "Successfully updated new SSL Certificate in your Unifi Controller"
else
	@sudo echo "UNIFI_FQDN argument needed"
endif