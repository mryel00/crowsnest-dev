import os
from pylibs import logger

configured_devices: list[str] = []

def crowsnest_watchdog():
    global configured_devices
    prefix = "Crowsnest Watchdog: "
    lost_devices = []

    for device in configured_devices:
        if device.startswith('/base'):
            continue
        if not os.path.exists(device):
            lost_devices.append(device)
            logger.log_quiet(f"Lost Devicve: '{device}'", prefix)
        elif device in lost_devices and os.path.exists(device):
            lost_devices.remove(device)
            logger.log_quiet(f"Device '{device}' returned.", prefix)
