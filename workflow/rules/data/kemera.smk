rule timestamp_kemera_region:
    input:
        kemera_url,
    output:
        protected(
            "<resources>/aineistot/Kemera/{day:02d}_{month:02d}_{year}/Maakunta/Kemera_{{region}}.zip".format(
                day=date.today().day, month=date.today().month, year=date.today().year
            )
        ),
    envmodules:
        "StdEnv",
    container:
        "base-env.sif"
    shell:
        "cp -p {input:q} {output:q}"


rule unpack_kemera_region:
    input:
        ancient(rules.timestamp_kemera_region.output[0]),
    output:
        temp(rules.timestamp_kemera_region.output[0].replace(".zip", ".gpkg")),
    envmodules:
        "StdEnv",
    container:
        "base-env.sif"
    shell:
        "unzip -p {input:q} > {output:q}"


rule merge_kemera_data:
    input:
        collect(
            "<resources>/aineistot/Kemera/{{day}}_{{month}}_{{year}}/Maakunta/Kemera_{region}.gpkg",
            region=region_list,
        ),
    output:
        "<results>/kemera/{year}-{month}-{day}/kemera.gpkg",
    container:
        "gdal-3.12.sif"
    shell:
        "gdal vector concat"
        " --source-layer-field-name 'source_dataset'"
        " --source-layer-field-content '{{DS_BASENAME}}'"
        " {input:q} {output:q}"


rule merge_kemera_data_layers:
    input:
        rules.merge_kemera_data.output[0],
    output:
        "<results>/kemera/{year}-{month}-{day}/kemera/{declarationtype}_{geometry}.gpkg",
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
