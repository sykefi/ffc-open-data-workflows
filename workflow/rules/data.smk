storage:
    provider="http",


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
    shell:
        "unzip -p {input:q} > {output:q}"


rule unpack_stand_region:
    input:
        lambda w: ancient(
            storage.http(
                f"{SMK_DATA_ROOT_URL}/Historia/Metsavarakuviot/{w.day}_{w.month}_{w.year}/Maakunta/MV_{w.region}.zip"
            )
        ),
    output:
        protected(
            "resources/aineistot/Historia/Metsavarakuviot/{day}_{month}_{year}/Maakunta/MV_{region}.gpkg"
        ),
    shell:
        "unzip -p {input:q} > {output:q}"


rule unpack_kemera_region:
    input:
        lambda w: ancient(
            storage.http(f"{SMK_DATA_ROOT_URL}/Kemera/Maakunta/Kemera_{w.region}.zip")
        ),
    output:
        protected(
            "resources/aineistot/Kemera/{day:02d}_{month:02d}_{year}/Maakunta/Kemera_{{region}}.gpkg".format(
                day=date.today().day, month=date.today().month, year=date.today().year
            )
        ),
    shell:
        "unzip -p {input:q} > {output:q}"


rule unpack_forest_use_declaration_region:
    input:
        lambda w: ancient(
            storage.http(
                f"{SMK_DATA_ROOT_URL}/Metsankayttoilmoitukset/Maakunta/MKI_{w.region}.zip"
            )
        ),
    output:
        protected(
            "resources/aineistot/Metsankayttoilmoitukset/{day:02d}_{month:02d}_{year}/Maakunta/MKI_{{region}}.gpkg".format(
                day=date.today().day, month=date.today().month, year=date.today().year
            )
        ),
    shell:
        "unzip -p {input:q} > {output:q}"
