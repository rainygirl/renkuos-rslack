# R Slack is a launcher script for R Chromium, so there is nothing to
# compile: `make` copies the script and gives the
# script the attributes Tracker, Deskbar and the roster read.

BUILD_DIR ?= build
APP := $(BUILD_DIR)/RSlack/R Slack
INSTALL_DIR ?= $(HOME)/config/non-packaged/apps/RSlack
DESKBAR_DIR ?= $(HOME)/config/settings/deskbar/menu/Applications

.PHONY: all install run clean

all: $(APP)

$(APP): src/RSlack.sh assets/RSlack.hvif
	mkdir -p "$(BUILD_DIR)/RSlack"
	cp src/RSlack.sh "$(APP)"
	chmod +x "$(APP)"
	@# A script has no resource fork, so the attributes are written directly.
	@# BEOS:APP_SIG is how the roster finds this file for slack:// links.
	addattr -t mime BEOS:TYPE text/x-shellscript "$(APP)"
	addattr -t mime BEOS:APP_SIG application/x-vnd.rainygirl-RSlack "$(APP)"
	addattr -f assets/RSlack.hvif -c VICN BEOS:ICON "$(APP)"

install: $(APP)
	mkdir -p "$(INSTALL_DIR)" "$(DESKBAR_DIR)"
	@# -a to carry the attributes across; a plain cp drops them.
	cp -a "$(APP)" "$(INSTALL_DIR)/"
	ln -sfn "$(INSTALL_DIR)/R Slack" "$(DESKBAR_DIR)/R Slack"

run: $(APP)
	"./$(APP)"

clean:
	rm -rf $(BUILD_DIR)
