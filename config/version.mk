# Copyright (C) 2016 The Pure Nexus Project
# Copyright (C) 2016 The JDCTeam
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARROW_MAJOR_VERSION = 13
ARROW_MINOR_VERSION = 2
ARROW_BUILD_TYPE ?= UNOFFICIAL
ARROW_BUILD_ZIP_TYPE ?= VANILLA

ARROW_MAINTAINER ?= Unknown

GET_DEVICE_CODENAME := $(word 2,$(subst _, ,$(TARGET_PRODUCT)))
CURRENT_DEVICE := $(basename $(GET_DEVICE_CODENAME))
ARROW_DEVICE_LIST := $(file < infrastructure/devices/arrow.devices)
ARROW_MAINTAINER_LIST := $(file < infrastructure/devices/arrow.maintainers)

ifneq ($(filter $(CURRENT_DEVICE),$(ARROW_DEVICE_LIST)),)
    ifneq ($(ARROW_MAINTAINER),)
        ifneq ($(filter $(ARROW_MAINTAINER),$(ARROW_MAINTAINER_LIST)),)
            ARROW_BUILD_TYPE := OFFICIAL
            IS_OFFICIAL_BUILD=true
        endif
    endif
endif

ifeq ($(ARROW_GAPPS), true)
    $(call inherit-product, vendor/gapps/common/common-vendor.mk)
    ARROW_BUILD_ZIP_TYPE := GAPPS
endif

ifeq ($(IS_OFFICIAL_BUILD), true)
PRODUCT_PACKAGES += \
    Updater

PRODUCT_COPY_FILES += \
    vendor/arrow/prebuilt/common/etc/init/init.arrow-updater.rc:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/init/init.arrow-updater.rc
endif

ARROW_MOD_VERSION := $(ARROW_MAJOR_VERSION).$(ARROW_MINOR_VERSION)

ARROW_VERSION := ArrowExtended-v$(ARROW_MOD_VERSION)-$(CURRENT_DEVICE)-$(ARROW_BUILD_TYPE)-$(shell date -u +%Y%m%d)-$(ARROW_BUILD_ZIP_TYPE)

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
  ro.arrow.version=$(ARROW_VERSION) \
  ro.arrow.releasetype=$(ARROW_BUILD_TYPE) \
  ro.arrow.ziptype=$(ARROW_BUILD_ZIP_TYPE) \
  ro.modversion=$(ARROW_MOD_VERSION)

ARROW_DISPLAY_VERSION := ArrowExtended-$(ARROW_MOD_VERSION)-$(ARROW_BUILD_TYPE)

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
  ro.arrow.display.version=$(ARROW_DISPLAY_VERSION)

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
  ro.device.maintainer=$(ARROW_MAINTAINER)

# Bypass charge
TARGET_SUPPORT_BYPASS_CHARGE ?= false

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
  persist.sys.battery_bypass_charge_support=$(TARGET_SUPPORT_BYPASS_CHARGE)
