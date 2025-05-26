storage:
    provider="http"


localrules:
    download_grid_region,
    unpack_grid_region,


rule download_grid_region:
    input:
        lambda w: (
            []
            if exists(
                f"resources/aineistot/Historia/Hila/{w.day}_{w.month}_{w.year}/Maakunta/Hila_{w.region}.zip"
            )
            else storage.http(
                f"{SMK_DATA_ROOT_URL}/Historia/Hila/{w.day}_{w.month}_{w.year}/Maakunta/Hila_{w.region}.zip"
            )
        ),
    output:
        protected(
            "resources/aineistot/Historia/Hila/{day}_{month}_{year}/Maakunta/Hila_{region}.zip"
        ),
    message:
        "Download grid data for {wildcards.region} ({wildcards.year}-{wildcards.month}-{wildcards.day})."
    shell:
        "cp {input:q} {output:q}"


rule unpack_grid_region:
    input:
        rules.download_grid_region.output[0],
    output:
        temp(rules.download_grid_region.output[0].replace(".zip", ".gpkg")),
    params:
        dirname=lambda w, output: dirname(output[0]),
    shell:
        "unzip -d {params.dirname:q} -j {input:q}"
