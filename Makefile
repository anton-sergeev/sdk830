

include etc/envvars.mk
include $(BUILDROOT)/.prjconfig


DIRS := $(FIRMWARE_DIR) $(TIMESTAMPS_DIR) $(COMPONENT_DIR) $(PACKAGES_DIR) $(BUILDROOT)/initramfs $(BUILDROOT)/rootfs
_ts_commonscript := $(TIMESTAMPS_DIR)/.commonscript

.PHONY : all firmware maketools make_components untar_rootfs clean br buildroot rootfs br_i buildroot_i initramfs linux kernel stapisdk stsdk scripts

all: scripts make_components untar_rootfs
firmware: scripts make_components make_firmware untar_rootfs
firmware: MAKE_FIRMWARE=1


maketools:
	make -C $(PRJROOT)/etc/tools


COMMON_SCRIPT_FILES=$(sort $(wildcard $(PRJROOT)/src/script/*.sh))
$(_ts_commonscript): $(COMMON_SCRIPT_FILES)
	$(call ECHO_MESSAGE,Common scripts)
	@echo "Scripts:"
	@for i in $?; do \
		is_script=`echo $$i | grep "script/.*.sh"`; \
		if [ -n "$$is_script" ]; then \
			echo -e "\n ***Execute $$i\n"; eval $$is_script; \
		fi; \
	done
	touch $(_ts_commonscript)

scripts: $(DIRS) $(_ts_commonscript)

define CHECK_COMP_SIZE
	@filesize=$$(stat -L -c%s $(1)); \
	if [ $$filesize -gt $(3) ]; then \
		echo "ERROR!!! $(1) $$filesize is greater than $(3) (partition size for 256MB NAND)"; \
	else \
		if [ $$filesize -gt $(2) ]; then \
			echo "WARNING!!! $(1) $$filesize is greater than $(2) (partition size for 128MB NAND)"; \
		fi; \
	fi;
endef

firmwarePackGenerator=$(PACKAGES_DIR)/buildroot/output_rootfs/host/usr/bin/firmwarePackGenerator
make_firmware: make_components
	$(call ECHO_MESSAGE,Creating firmware pack:)
	$(firmwarePackGenerator) $(COMPONENT_DIR)/stb830_efp.conf
	@echo "Creating symlink on latest firmware."
	@rm -f $(BUILDROOT)/firmware/STB830_last.efp;
	@ln -s `grep "OutputFile = " $(COMPONENT_DIR)/stb830_efp.conf | sed 's%.*/\(.*\.efp\).*%\1%'` $(BUILDROOT)/firmware/STB830_last.efp
	$(call CHECK_COMP_SIZE,$(COMPONENT_DIR)/kernel1,10485760,15728640)
	$(call CHECK_COMP_SIZE,$(COMPONENT_DIR)/rootfs1,77594624,134217728)

make_components: scripts
	INCREMENT_REVISION=$(MAKE_FIRMWARE) $(PRJROOT)/bin/genFirmwarePackConf.sh
ifneq ($(BUILD_WITHOUT_COMPONENTS_FW),1)
	make -C src/linux
	make -C src/rootfs
endif
	@$(PRJROOT)/bin/genScriptComp.sh
	@$(PRJROOT)/bin/genDescrComp.sh


$(TIMESTAMPS_DIR) $(COMPONENT_DIR) $(FIRMWARE_DIR) $(SDK_PACKAGES_DIR) $(PACKAGES_DIR):
	mkdir -p $@

#	cd $(BUILDROOT) && rm -f images_initramfs initramfs images rootfs
$(BUILDROOT)/initramfs:
	test -h $@ || ln -s packages/buildroot/output_initramfs/target $@

$(BUILDROOT)/rootfs:
	test -h $@ || ln -s packages/buildroot/output_rootfs/target $@


user=$(shell whoami)
group=$(shell id -g)
define UNTAR_ROOTFS_NFS
	$(call ECHO_MESSAGE,Untar rootfs for nfs share:);
	mkdir -p $(BUILDROOT)/rootfs_nfs;
	sudo tar -xf $(PACKAGES_DIR)/buildroot/output_rootfs/images/rootfs.tar -C $(BUILDROOT)/rootfs_nfs;
	sudo chown -R $(user):$(group) $(BUILDROOT)/rootfs_nfs
endef

untar_rootfs:
ifneq "$(BUILD_WITHOUT_COMPONENTS_FW)" "1"
	$(if $(CONFIG_UNTAR_ROOTFS_FOR_NFS),$(call UNTAR_ROOTFS_NFS),)
endif


clean:
	echo "clean"


br buildroot rootfs: scripts
	make -C $(PRJROOT)/src/rootfs

bri br_i buildroot_i initramfs: scripts
	make -C $(PRJROOT)/src/buildroot initramfs_rm_make_ts
	make -C $(PRJROOT)/src/initramfs

linux kernel: scripts
	make -C $(PRJROOT)/src/linux kernel_only

stb:
	make -C $(PRJROOT)/src/apps/StbMainApp

ifeq ($(STB830_SDK),)
packs: scripts $(SDK_PACKAGES_DIR)
	$(PRJROOT)/src/elecard/bin/genPackages.sh

stapisdk stsdk elcd: scripts
	make -C $(PRJROOT)/src/elecard/stapisdk stapisdk
else
stapisdk stsdk elcd packs: scripts
	@echo "You should run it in FULL build (not SDK)!"
endif

