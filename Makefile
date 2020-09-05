NAME      := unifi
DOMAIN    := home
DURATION  := 5340
CDIR      := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

UNIFI_DIR := /usr/lib/unifi
BUILD_DIR := $(CDIR)build
ROOT_DIR  := $(CDIR)root

V3_EXT    := $(BUILD_DIR)/$(NAME)/v3.ext
CSR_FILE  := $(BUILD_DIR)/$(NAME)/server.csr
CRT_FILE  := $(BUILD_DIR)/$(NAME)/server.crt

ROOT_KEY  := $(ROOT_DIR)/rootCA.key
ROOT_PUB  := $(ROOT_DIR)/rootCA.crt
ROOT_CNF  := $(ROOT_DIR)/rootCA.cnf

UNIFI_CSR := $(UNIFI_DIR)/data/unifi_certificate.csr.pem
UNIFI_ACE := $(UNIFI_DIR)/lib/ace.jar
UNIFI_KEY := $(UNIFI_DIR)/data/keystore

CA_C      := IN
CA_ST     := Kerala
CA_L      := Thrissur
CA_O      := Happy Home CA
CA_OU     := Administration
CA_E      := me@nikz.in
CA_CN     := Happy Home Ceritificate Authority

define ROOT_CNF_STRING
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=$(CA_C)
ST=$(CA_ST)
L=$(CA_L)
O=$(CA_O)
OU=$(CA_OU)
emailAddress=$(CA_E)
CN = $(CA_CN)
endef

define V3_EXT_STRING
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $(NAME).$(DOMAIN)
endef

export ROOT_CNF_STRING
export V3_EXT_STRING

setup:
	@mkdir -p $(BUILD_DIR)/$(NAME)/ $(ROOT_DIR)/
	@echo "$$ROOT_CNF_STRING" > $(ROOT_CNF)
	@echo "$$V3_EXT_STRING" > $(V3_EXT)

clean:
	@rm -rf $(BUILD_DIR) $(ROOT_DIR) $(ROOT_CNF) $(V3_EXT)

root-ca: clean setup
	@echo "Generating Root Certificate Authority"
	@openssl req -x509 -new -nodes -sha256 -days $(DURATION) -keyout $(ROOT_KEY) -out $(ROOT_PUB) -config $(ROOT_CNF) -verify

unifi-ssl:
	@sudo echo "Unifi SSL Updating"
	@sudo java -jar $(UNIFI_ACE) new_cert $(CA_CN) "$(CA_O)" "$(CA_L)" "$(CA_ST)" $(CA_C)
	@sudo cat $(UNIFI_CSR) > $(CSR_FILE)
	@sudo openssl x509 -req -in $(CSR_FILE) -CA $(ROOT_PUB) -CAkey $(ROOT_KEY) -CAcreateserial -out $(CRT_FILE) -days $(DURATION) -sha256 -extfile $(V3_EXT)
	@sudo keytool -import -trustcacerts -alias root -file $(ROOT_PUB) -keystore $(UNIFI_KEY)
	@sudo keytool -import -trustcacerts -alias unifi -file $(CRT_FILE) -keystore $(UNIFI_KEY)
	@sudo service unifi restart
