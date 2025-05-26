storage:
    provider="http"


localrules:
    download_grid_region,


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
