rule timestamp_forest_use_declaration_region:
    input:
        forest_use_declaration_url,
    output:
        protected(
            "<resources>/aineistot/Metsankayttoilmoitukset/{day:02d}_{month:02d}_{year}/Maakunta/MKI_{{region}}.zip".format(
                day=date.today().day, month=date.today().month, year=date.today().year
            )
        ),
    shell:
        "cp -p {input:q} {output:q}"


rule unpack_forest_use_declaration_region:
    input:
        ancient(rules.timestamp_forest_use_declaration_region.output[0]),
    output:
        temp(
            rules.timestamp_forest_use_declaration_region.output[0].replace(
                ".zip", ".gpkg"
            )
        ),
    shell:
        "unzip -p {input:q} > {output:q}"


rule forest_use_declaration_data:
    input:
        "<resources>/aineistot/Metsankayttoilmoitukset/{day}_{month}_{year}/Maakunta/MKI_{region}.gpkg",
    output:
        temp(
            "<results>/forest_use_declaration/{year}-{month}-{day}/forest_use_declaration/{region}.gpkg"
        ),
    container:
        "gdal-3.12.sif"
    params:
        layer="forestusedeclaration",
        sql="SELECT * FROM forestusedeclaration",
    shell:
        "gdal vector pipeline --quiet"
        " ! read {input[0]:q}"
        " ! sql -l {params.layer} --sql {params.sql:q}"
        " ! write {output[0]:q}"


rule merge_forest_use_declaration_data:
    input:
        collect(
            "<results>/forest_use_declaration/{{year}}-{{month}}-{{day}}/forest_use_declaration/{region}.gpkg",
            region=region_list,
        ),
    output:
        "<results>/forest_use_declaration/{year}-{month}-{day}/forest_use_declaration.gpkg",
    container:
        "gdal-3.12.sif"
    params:
        layer="forestusedeclaration",
        sql="SELECT * FROM (SELECT *, row_number() OVER (PARTITION BY objectid) AS row_number FROM forestusedeclaration) WHERE row_number = 1",
    shell:
        "gdal vector pipeline --quiet"
        " ! concat --source-layer-field-name source_dataset --source-layer-field-content {{DS_BASENAME}} {input:q}"
        " ! sql --dialect SQLITE -l {params.layer} --sql {params.sql:q}"
        " ! select --exclude --fields row_number"
        " ! write {output[0]:q}"
