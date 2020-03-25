###############################################################################
# SDK Metadata

OS_VARIANT = "Sailfish OS"
SDK_VARIANT = "Sailfish SDK"
SDK_VERSION = "3.1.2"
OS_VERSION = {"ea": "3.3.0.11",
              "latest": "3.3.0.11",
              "oldest": "3.0.0.8"}

###############################################################################
# Execution Profile
#
# These are the defaults that are meant to be overriden on robot command line or
# by similar means

# Set to True to use an existing SDK installation. The most common use case for
# this feature is to shorten the execution times during test case
# development/debugging to achieve shorter execution times.
USE_EXISTING_SDK_INSTALLATION = False

# Relative paths are resolved relatively to robot execution directory
INSTALLER = "../SailfishSDK-installer.run"
SDK_INSTALL_DIR = "~/SailfishOS"

# Either "vbox" or "docker"
BUILD_ENGINE_TYPE = "vbox"

# Either "emulator" or "hardware".
#
# FIXME: Testing with HW devices is currently only possible with preinstalled
# and preconfigured SDK instance - see USE_EXISTING_SDK_INSTALLATION. The device
# must be available under the name matching the name of the corresponding build
# target, e.g.  SailfishOS-1.2.3.4-armv7hl, SailfishOS-1.2.3.4EA-armv7hl.
DEVICE_TYPE = "emulator"

# "i486", "armv7hl", ...
DEVICE_ARCH = "i486"

# Either a symbolic version mentioned in OS_VERSION or an explicit version
DEVICE_OS_VERSION = "latest"

# Device's regular user name
DEVICE_USER = "nemo"
