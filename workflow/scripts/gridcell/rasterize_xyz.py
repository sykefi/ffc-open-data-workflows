import typing

if typing.TYPE_CHECKING:
    from snakemake.script import snakemake

import subprocess
import sys

from os.path import join
from tempfile import TemporaryDirectory

sys.stdout = open(snakemake.log[0], "w")
sys.stderr = sys.stdout

sys.path.append(
    subprocess.check_output(["grass", "--config", "python_path"], text=True).strip()
)

from grass.script.core import create_project
from grass.script.setup import init as init_grass
from grass.experimental import TemporaryMapsetSession
from grass.tools import Tools

with TemporaryDirectory() as gisdb:
    create_project(path=join(gisdb, "project"), epsg=3067)

    with init_grass(gisdb, "project", "PERMANENT") as session:

        resolution = snakemake.params.resolution
        field_type = snakemake.params.field_type

        input_xyz = snakemake.input.xyz

        output_field = snakemake.wildcards.gridcell_field

        export_config = dict()

        match field_type:

            case "category" | "integer" | "date":
                grass_type = "CELL"

                match field_type:
                    case "category":
                        export_config |= {
                            "type": "Byte",
                            "nodata": 0,
                            "createopt": ["PREDICTOR=2"],
                        }

                    case "integer" if output_field[:9] == "stemcount":
                        export_config |= {
                            "type": "UInt32",
                            "nodata": 2**20 - 1,
                            "createopt": ["NBITS=20"],
                        }

                    case _:
                        export_config |= {
                            "type": "UInt16",
                            "nodata": 2**16 - 1,
                            "createopt": ["PREDICTOR=2"],
                        }

            case "real":
                grass_type = "FCELL"

                export_config |= {
                    "type": "Float32",
                    "createopt": [
                        "PREDICTOR=3",
                    ],
                }

        export_config["createopt"] += ["COMPRESS=DEFLATE", "TILED=YES"]

        tools = Tools(quiet=True)

        extent = {
            x[0]: x[1]
            for x in (
                x.split("=")
                for x in tools.r_in_xyz(
                    flags="gs", input=input_xyz, separator="tab", skip="1"
                ).space_items
            )
            if x[0] in ["n", "s", "e", "w"]
        }

        tools.g_region(res=resolution, **extent)

        tools.g_region(
            n=f"n+{resolution/2}",
            s=f"s-{resolution/2}",
            e=f"e+{resolution/2}",
            w=f"w-{resolution/2}",
        )

        tools.r_in_xyz(
            input=input_xyz,
            output=output_field,
            separator="tab",
            skip="1",
            type=grass_type,
        )

        tools.r_out_gdal(
            flags="c", input=output_field, output=snakemake.output[0], **export_config
        )
