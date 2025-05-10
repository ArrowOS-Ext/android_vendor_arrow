#
# Copyright (C) 2018-2023 ArrowOS
#           (C) 2025 ArrowOS Extended
#
# SPDX-License-Identifier: Apache-2.0
#

ARROW_TARGET_PACKAGE := $(PRODUCT_OUT)/$(ARROW_VERSION).zip
RELATIVE_TARGET_PACKAGE := $(subst $(shell pwd)/,,$(ARROW_TARGET_PACKAGE))
SHA256 := prebuilts/build-tools/path/$(HOST_PREBUILT_TAG)/sha256sum

$(ARROW_TARGET_PACKAGE): $(INTERNAL_OTA_PACKAGE_TARGET)
	$(hide) ln -f $(INTERNAL_OTA_PACKAGE_TARGET) $(ARROW_TARGET_PACKAGE)
	$(hide) $(SHA256) $(ARROW_TARGET_PACKAGE) | sed "s|$(PRODUCT_OUT)/||" > $(ARROW_TARGET_PACKAGE).sha256sum
	$(hide) ./vendor/arrow/build/tools/generate_ota_json.sh $(TARGET_DEVICE) $(PRODUCT_OUT) $(ARROW_VERSION).zip $(ARROW_MAINTAINER) $(ARROW_MOD_VERSION)

.PHONY: bacon
bacon: $(ARROW_TARGET_PACKAGE)
	echo -e "========================================================================================================"
	echo -e ""
	echo -e "                 \033[1;34m''\033[0m                  "
	echo -e "           \`\`\`\`\`\033[1;34m.oy.\033[0m\`\`\`\`\`\`\`          "
	echo -e "        \`\`\`\`\`\`\`\033[1;34m:dMMh.\033[0m\`\`\`\`\`\`\`\`        "
	echo -e "      \`\`\`\`\`\`\`\033[1;34m.sMMMMMy.\033[0m\`\`\`\`\`\`\`\`\`      "
	echo -e "    \`\`\`\`\`\`\`\033[1;34m./mMMMMMMMy.\033[0m\`\`\`\`\`\`\`\`\`\`    "
	echo -e "   \`\`\`\`\`\`\`\033[1;34m-yMMMMMMMMMMy.\033[0m\`\`\`\`\`\`\`\`\`\`   "
	echo -e "   \`\`\`\`\`\033[1;34m./mMMNNNMMMMMMMy.\033[0m\`\`\`\`\`\`\`\`\`\`  "
	echo -e "  \`\`\`\`\`\033[1;34m-ymmhMMMMMMhNMMMMs.\033[0m\`\`\`\`\`\`\`\`\`  "
	echo -e "  \`\`\`\`\033[1;34m./M..\033[0m\`\`\`\`\`\`\`\033[1;34m.-odMMMs.\033[0m\`\`\`\`\`\`\`\`  "
	echo -e "  \`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\033[1;34m./hMMs.\033[0m\`\`\`\`\`\`\`  "
	echo -e "   \`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\033[1;34m./dMs.\033[0m\`\`\`\`\`\`  "
	echo -e "    \`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\033[1;34m.+ms\033[0m\`\`\`\`\`  "
	echo -e "     \`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\033[1;34m-yo\033[0m\`\`\`   "
	echo -e "      \`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\033[1;34m...d\033[0m\`    "
	echo -e "        \`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\` \`\` \033[1;34m.   \033[0m"
	echo -e "           \`\`\`\`\`\`\`\`\`\`\`\`\`\`\`\`          "
	echo -e ""
	echo -e "                ArrowOS"
	echo -e ""
	echo -e "========================================================================================================"
	echo -e "\033[94m=>\033[0m Zip File : \033[93m$(RELATIVE_TARGET_PACKAGE)\033[0m"
	echo -e "\033[91m=>\033[0m MD5      : \033[94m$$(md5sum $(ARROW_TARGET_PACKAGE) | awk '{print $$1}')\033[0m"
	echo -e "\033[93m=>\033[0m Size     : \033[91m$$(du -h $(ARROW_TARGET_PACKAGE) | awk '{print $$1}')\033[0m"
	echo -e "========================================================================================================"
