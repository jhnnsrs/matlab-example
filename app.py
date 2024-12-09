from mikro_next.api.schema import Image, from_array_like
from arkitekt_next import init, register, register_structure, App, afakt, require
from rekuest_next.agents.extensions.delegating.extension import CLIExtension
from rekuest_next.rekuest import RekuestNext
import tifffile
import os
import xarray as xr



require("matlab", "matlab", "A matlab installation is required to run the script")


@register_structure(identifier="OME_TIFF")
class OMETiffStructure:

    def __init__(self, file: str):
        self.file = file

    async def ashrink(self):
        return self.file

    @classmethod
    async def aexpand(cls, name: str):
        return cls(name)

    @classmethod
    def from_image(cls, image: Image):
        file_name = "image.tiff"
        tifffile.imwrite(file_name, image.data)
        return cls(file_name)

    def to_xarray(self) -> xr.DataArray:
        data = tifffile.imread(self.file)
        return data

    async def acollect(self):
        os.remove(self.file)


@register
def image_to_ome_tiff(image: Image) -> OMETiffStructure:
    return OMETiffStructure.from_image(image)


@register
def ome_tiff_to_timage(file: OMETiffStructure, name: str) -> Image:
    return from_array_like(file.to_xarray(), name=name)


@init
def app(app: App):
    print("Init function is beiing called")

    rekuest: RekuestNext = app.services.get("rekuest")

    async def awrite_credentials(handle):

        username = await afakt("matlab.username")
        password = await afakt("matlab.password")
        print("Writing credentials", username, password)

        # Wait for the username prompt

        print(await handle.read(until="Enter: "))
        await handle.write(username)

        # Wait for the password prompt
        print(await handle.read("Enter: "))
        await handle.write(password)

    async def aprint(x):
        print(x)

    rekuest.agent.register_extension(
        "cli",
        CLIExtension(
            run_script=f'''/bin/run.sh -nodesktop -nosplash -nodisplay -r "run('/home/matlab/karl.m'); exit;"''',
            on_init=awrite_credentials,
            on_process_stdout=aprint,
            initial_timeout=6000,
        ),
    )

