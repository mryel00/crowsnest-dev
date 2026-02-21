
import asyncio
from configparser import SectionProxy
from typing import Optional

from .section import Section


class Crowsnest(Section):
    def __init__(self, config_section: SectionProxy) -> None:
        self.section = "[crowsnest]"
        super().__init__("crowsnest", config_section)

    def parse_config_section(self, section: SectionProxy) -> None:
        super().parse_config_section(section)
        self.parameters.update(
            {
                "log_level": section.getloglevel("log_level", "INFO"),
                "delete_log": section.getboolean("delete_log", False),
                "no_proxy": section.getboolean("no_proxy", False),
            }
        )

    async def execute(self, lock: asyncio.Lock) -> Optional[asyncio.subprocess.Process]:
        raise NotImplementedError("If you see this, something went wrong!!!")


def load_component(name: str, config_section: SectionProxy) -> Crowsnest:
    return Crowsnest(config_section)
