rule unpack_gridcell_region:
    input:
        gridcell_history_url,
    output:
        temp(
            "<resources>/aineistot/Historia/Hila/{day}_{month}_{year}/Maakunta/Hila_{region}.gpkg"
        ),
    log:
        "<logs>/unpack_gridcell_region/{year}-{month}-{day}/{region}.log",
    envmodules:
        "StdEnv",
    container:
        "base-env.sif"
    shell:
        "unzip -p {input:q} > {output:q} 2> {log:q}"


rule extract_gridcell_param_xyz:
    input:
        rules.unpack_gridcell_region.output[0],
    output:
        temp("<results>/gridcell/{year}-{month}-{day}/{gridcell_field}/{region}.xyz"),
    log:
        "<logs>/extract_gridcell_param_xyz/{year}-{month}-{day}/{gridcell_field}/{region}.log",
    wildcard_constraints:
        gridcell_field=regex_choice_list(gridcell_param_field),
    container:
        "gdal-3.12.sif"
    params:
        sql=gridcell_param_sql,
    shell:
        "gdal vector pipeline"
        " ! read {input:q}"
        " ! sql --sql {params.sql:q}"
        " ! write -f CSV --lco SEPARATOR=tab /vsistdout/"
        " > {output:q}"
        " 2> {log:q}"


use rule extract_gridcell_param_xyz as extract_gridcell_date_xyz with:
    wildcard_constraints:
        gridcell_field=regex_choice_list(gridcell_date_field),
    params:
        sql=gridcell_date_sql,


use rule extract_gridcell_param_xyz as extract_gridcell_developmentclass_xyz with:
    wildcard_constraints:
        gridcell_field="developmentclass",
    params:
        sql=gridcell_developmentclass_sql,


rule rasterize_gridcell_xyz:
    input:
        xyz=rules.extract_gridcell_param_xyz.output[0],
    output:
        temp(rules.extract_gridcell_param_xyz.output[0].replace(".xyz", ".tif")),
    log:
        "<logs>/rasterize_gridcell_xyz/{year}-{month}-{day}/{gridcell_field}/{region}.log",
    container:
        "grass-8.5.sif"
    params:
        field_type=lookup(
            dpath="{gridcell_field}/type",
            within=gridcell_field_list,
        ),
        resolution=16,
    script:
        "../../scripts/gridcell/rasterize_xyz.py"


rule patch_gridcell_raster:
    input:
        lambda w: collect(
            rules.rasterize_gridcell_xyz.output[0],
            gridcell_field=w.gridcell_field,
            year=w.year,
            month=w.month,
            day=w.day,
            region=region_list,
        ),
    output:
        "<results>/gridcell/{year}-{month}-{day}/{gridcell_field}.tif",
    log:
        "<logs>/patch_gridcell_raster/{year}-{month}-{day}/{gridcell_field}.log",
    container:
        "grass-8.5.sif"
    params:
        field_type=lookup(
            dpath="{gridcell_field}/type",
            within=gridcell_field_list,
        ),
    script:
        "../../scripts/gridcell/patch_raster.py"
