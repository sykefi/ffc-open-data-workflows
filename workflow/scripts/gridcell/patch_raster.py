from snakemake.script import snakemake

import subprocess
import sys

from os.path import join
from tempfile import TemporaryDirectory, NamedTemporaryFile

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

        field_type = snakemake.params.field_type
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
                    "nodata": -65504,
                    "createopt": [
                        "PREDICTOR=3",
                        "NBITS=16",
                    ],
                }

        export_config["createopt"] += ["COMPRESS=DEFLATE", "TILED=YES", "BIGTIFF=YES"]

        tools = Tools(quiet=True)

        input_rasters = {f"r.{i}": v for i, v in enumerate(snakemake.input)}

        for k, v in input_rasters.items():
            tools.r_external(
                flags="o",
                input=v,
                output=k,
            )

        tools.g_region(raster=input_rasters)

        tools.r_buildvrt(input=input_rasters, output=output_field)

        if output_field == "developmentclass":
            with NamedTemporaryFile(
                mode="w+",
                encoding="ascii",
                delete=False,
                dir=gisdb,
            ) as category_file:
                category_file.writelines(
                    f"{x}\n"
                    for x in [
                        "1:A0",
                        "2:S0",
                        "3:T1",
                        "4:T2",
                        "5:Y1",
                        "6:ER",
                        "7:02",
                        "8:03",
                        "9:04",
                        "10:05",
                    ]
                )
                category_file.close()

                tools.r_category(
                    map=output_field, separator=":", rules=category_file.name
                )

            flags = "cft"
        else:
            flags = "cf"

        tools.r_out_gdal(
            flags=flags, input=output_field, output=snakemake.output[0], **export_config
        )
