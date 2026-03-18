rule unpack_stand_region:
    input:
        stand_url,
    output:
        temp(
            "<resources>/aineistot/Historia/Metsavarakuviot/{day}_{month}_{year}/Maakunta/MV_{region}.gpkg"
        ),
    log:
        "<logs>/unpack_stand_region/{year}-{month}-{day}/{region}.log",
    envmodules:
        "StdEnv",
    container:
        "base-env.sif"
    shell:
        "unzip -p {input:q} > {output:q} 2> {log:q}"


rule stand_data:
    input:
        rules.unpack_stand_region.output[0],
    output:
        temp("<results>/stand/{year}-{month}-{day}/stand/{stand_layer}/{region}.gpkg"),
    log:
        "<logs>/stand_data/{year}-{month}-{day}/{stand_layer}/{region}.log",
    container:
        "gdal-3.12.sif"
    params:
        layer=lambda w: w.stand_layer,
        sql=lambda w: f"SELECT * FROM {w.stand_layer}",
    shell:
        "gdal vector pipeline --quiet"
        " ! read {input:q}"
        " ! sql -l {params.layer} --sql {params.sql:q}"
        " ! write {output:q}"
        " > {log:q} 2>&1"


rule merge_stand_layer_data:
    input:
        collect(
            "<results>/stand/{{year}}-{{month}}-{{day}}/stand/{{stand_layer}}/{region}.gpkg",
            region=region_list,
        ),
    output:
        "<results>/stand/{year}-{month}-{day}/stand/{stand_layer}.gpkg",
    log:
        "<logs>/merge_stand_layer_data/{year}-{month}-{day}/{stand_layer}.log",
    container:
        "gdal-3.12.sif"
    params:
        layer=lambda w: w.stand_layer,
        sql=stand_param_sql,
    shell:
        "gdal vector pipeline --quiet"
        " ! concat --source-layer-field-name source_dataset --source-layer-field-content {{DS_BASENAME}} {input:q}"
        " ! sql --dialect SQLITE -l {params.layer} --sql {params.sql:q}"
        " ! select --exclude --fields row_number"
        " ! write {output:q}"
        " > {log:q} 2>&1"


rule merge_stand_data:
    input:
        collect(
            "<results>/stand/{{year}}-{{month}}-{{day}}/stand/{stand_layer}.gpkg",
            stand_layer=stand_layer_list,
        ),
    output:
        "<results>/stand/{year}-{month}-{day}/stand.gpkg",
    log:
        "<logs>/merge_stand_layer_data/{year}-{month}-{day}.log",
    container:
        "gdal-3.12.sif"
    shell:
        "gdal vector concat --quiet --mode stack {input:q} {output:q} > {log:q} 2>&1"
