rule timestamp_kemera_region:
    input:
        kemera_url,
    output:
        protected(
            "<resources>/aineistot/Kemera/{day:02d}_{month:02d}_{year}/Maakunta/Kemera_{{region}}.zip".format(
                day=date.today().day, month=date.today().month, year=date.today().year
            )
        ),
    log:
        "<logs>/timestamp_kemera_region/{{region}}_{year:04d}-{month:02d}-{day:02d}.log".format(
            day=date.today().day, month=date.today().month, year=date.today().year
        ),
    envmodules:
        "StdEnv",
    container:
        "base-env.sif"
    shell:
        "cp -p {input:q} {output:q} > {log:q} 2>&1"


rule unpack_kemera_region:
    input:
        ancient(rules.timestamp_kemera_region.output[0]),
    output:
        temp(rules.timestamp_kemera_region.output[0].replace(".zip", ".gpkg")),
    log:
        "<logs>/unpack_kemera_region/{{region}}_{year:04d}-{month:02d}-{day:02d}.log".format(
            day=date.today().day, month=date.today().month, year=date.today().year
        ),
    envmodules:
        "StdEnv",
    container:
        "base-env.sif"
    shell:
        "unzip -p {input:q} > {output:q} 2> {log:q}"


rule merge_kemera_data:
    input:
        collect(
            "<resources>/aineistot/Kemera/{{day}}_{{month}}_{{year}}/Maakunta/Kemera_{region}.gpkg",
            region=region_list,
        ),
    output:
        "<results>/kemera/{year}-{month}-{day}/kemera.gpkg",
    log:
        "<logs>/merge_kemera_data/{year}-{month}-{day}.log",
    container:
        "gdal-3.12.sif"
    shell:
        "gdal vector concat"
        " --source-layer-field-name 'source_dataset'"
        " --source-layer-field-content '{{DS_BASENAME}}'"
        " {input:q} {output:q}"
        " > {log:q} 2>&1"


rule merge_kemera_data_layers:
    input:
        rules.merge_kemera_data.output[0],
    output:
        "<results>/kemera/{year}-{month}-{day}/kemera/{declarationtype}_{geometry}.gpkg",
    log:
        "<logs>/merge_kemera_data_layers/{year}-{month}-{day}/{declarationtype}_{geometry}.log",
    wildcard_constraints:
        declarationtype="(?:application|completiondeclaration)",
        geometry="(?:stand|line|point)",
    container:
        "gdal-3.12.sif"
    params:
        sql=kemera_param_sql,
        layer=evaluate("{declarationtype} + '_' + {geometry}"),
        geometry=lookup(dpath="/{geometry}", within=kemera_geometry_type),
    shell:
        "gdal vector pipeline --quiet"
        " ! read {input:q}"
        " ! sql --output-layer {params.layer} --sql {params.sql:q}"
        " ! set-geom-type --geometry-type {params.geometry}"
        " ! write {output:q}"
        " > {log:q} 2>&1"
