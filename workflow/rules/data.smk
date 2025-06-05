storage:
    provider="http"


rule unpack_gridcell_region:
    input:
        lambda w: ancient(
            storage.http(
                f"{SMK_DATA_ROOT_URL}/Historia/Hila/{w.day}_{w.month}_{w.year}/Maakunta/Hila_{w.region}.zip"
            )
        ),
    output:
        protected(
            "resources/aineistot/Historia/Hila/{day}_{month}_{year}/Maakunta/Hila_{region}.gpkg"
        ),
    params:
        dirname=lambda w, output: dirname(output[0]),
    shell:
        "unzip -p {input:q} > {output:q}"
