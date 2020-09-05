NAME      := unifi
DOMAIN    := home
DURATION  := 5340

ROOT_DIR  := /root/ca
UNIFI_DIR := /usr/lib/unifi
BUILD_DIR := $(ROOT_DIR)/$(NAME)

V3_EXT    := $(BUILD_DIR)/v3.ext
CSR_FILE  := $(BUILD_DIR)/server.csr
CRT_FILE  := $(BUILD_DIR)/server.crt

ROOT_KEY  := $(ROOT_DIR)/private/ca.key.pem
ROOT_PUB  := $(ROOT_DIR)/certs/ca.cert.pem
ROOT_CNF  := $(ROOT_DIR)/openssl.cnf

UNIFI_ACE := $(UNIFI_DIR)/lib/ace.jar
UNIFI_KEY := $(UNIFI_DIR)/data/keystore
UNIFI_CSR := $(UNIFI_DIR)/data/unifi_certificate.csr.pem

U_C      := "IN"
U_ST     := "Kerala"
U_L      := "Thrissur"
U_O      := "Happy Home CA"
U_CN     := $(NAME).$(DOMAIN)

define V3_EXT_STRING
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $(U_CN)
endef

export V3_EXT_STRING

setup:
	@sudo mkdir -p $(ROOT_DIR)/private $(ROOT_DIR)/certs $(BUILD_DIR)/ 
	@sudo cp openssl.cnf $(ROOT_CNF)
	@sudo cp v3.ext $(V3_EXT)

root-ca: setup
	@sudo echo "Generating Root Certificate Authority"
	@sudo openssl req -x509 -new -nodes -sha256 -days $(DURATION) -keyout $(ROOT_KEY) -out $(ROOT_PUB) -config $(ROOT_CNF) -verify

unifi-ssl: root-ca
	@sudo echo "Unifi SSL Updating"
	@sudo java -jar $(UNIFI_ACE) new_cert "$(U_CN)" "$(U_O)" "$(U_L)" "$(U_ST)" "$(U_C)"
	@sudo cat $(UNIFI_CSR) > $(CSR_FILE)
	@sudo openssl x509 -req -in $(CSR_FILE) -CA $(ROOT_PUB) -CAkey $(ROOT_KEY) -CAcreateserial -out $(CRT_FILE) -days $(DURATION) -sha256 -extfile $(V3_EXT)
	@sudo keytool -import -trustcacerts -alias root -file $(ROOT_PUB) -keystore $(UNIFI_KEY) -storepass aircontrolenterprise
	@sudo keytool -import -trustcacerts -alias unifi -file $(CRT_FILE) -keystore $(UNIFI_KEY) -storepass aircontrolenterprise
	@sudo service unifi restart
	@sudo echo "Successfully updated new SSL Certificate in your Unifi Controller"
