#
# Common recovery product for the Nothing Phone (3a) Lite.
#
# The same product is used by TWRP, OrangeFox R12 and AERA R1.0. Select the
# recovery by building in the matching vendor workspace; lunch is always
# twrp_Galaxian.
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_Galaxian.mk

COMMON_LUNCH_CHOICES := \
    twrp_Galaxian-bp2a-eng \
    twrp_Galaxian-bp2a-userdebug \
    twrp_Galaxian-bp2a-user
