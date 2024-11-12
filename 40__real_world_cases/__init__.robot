*** Settings ***
Suite Setup       Maybe Install SDK    vbox_engine_memory_size_mb=4096
Suite Teardown    Maybe Uninstall SDK
Library           ../SailfishSDK.py
Variables         ../SailfishSDK.py
