from configparser import SectionProxy
from .section import Section
from .parameter import Parameter
from .core import get_module_class

from . import logger

class Cam(Section):
    section_name = 'cam'
    keyword = 'cam'

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'mode': Parameter(str)
        })

        self.streamer = None

    def parse_config(self, config_section: SectionProxy, *args, **kwargs):
        # Dynamically import module
        mode = config_section["mode"].split()[0]
        self.parameters["mode"].set_value(mode)
        mode_class = get_module_class('pylibs.streamer', mode)
        self.streamer = mode_class(self.name)
        return self.streamer.parse_config(config_section)

    async def execute(self):
        if self.streamer is None:
            print("No streamer loaded")
            return
        try:
            process = await self.streamer.execute()
            await process.wait()
            logger.log_error(f'Start of {self.parameters["mode"].value} [cam {self.name}] failed!')
        except Exception as e:
            pass

def load_module():
    return Cam

#if __name__ == "__main__":
#    print("This is a module and shouldn't be executed directly")
#else:
#    CN_Section.available_sections[CN_Cam.keyword] = CN_Cam