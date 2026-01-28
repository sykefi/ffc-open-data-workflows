rule unpack_gridcell_region:
    input:
        gridcell_history_url,
    output:
        temp(
            "<resources>/aineistot/Historia/Hila/{day}_{month}_{year}/Maakunta/Hila_{region}.gpkg"
        ),
    shell:
        "unzip -p {input:q} > {output:q}"


rule extract_gridcell_param_xyz:
    input:
        rules.unpack_gridcell_region.output[0],
    output:
        temp("<results>/gridcell/{year}-{month}-{day}/{gridcell_field}/{region}.xyz"),
    wildcard_constraints:
        gridcell_field=regex_choice_list(gridcell_param_field),
    params:
        sql=gridcell_param_sql,
    container:
        "gdal-3.12.sif"
    envmodules:
        "geoconda",
    shell:
        "gdal vector pipeline"
        " ! read {input[0]:q}"
        " ! sql --sql {params.sql:q}"
        " ! write -f CSV --lco SEPARATOR=tab /vsistdout/"
        " > {output[0]:q}"


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
    container:
        "grass-8.5.sif"
    params:
        field_type=lookup(
            dpath="{gridcell_field}/type",
            within=gridcell_field_list,
        ),
    script:
        "../../scripts/gridcell/patch_raster.py"
