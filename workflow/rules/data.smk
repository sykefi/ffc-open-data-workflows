storage:
    provider="http"


localrules:
    download_grid_region,
    unpack_grid_region,
    extract_grid_param_xyz,
    extract_grid_date_xyz,
    extract_developmentclass_xyz,
    rasterize_xyz,


rule download_grid_region:
    input:
        lambda w: ancient(
            storage.http(
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


rule extract_grid_param_xyz:
    input:
        rules.unpack_grid_region.output[0],
    output:
        temp("results/gridcell/{year}-{month}-{day}/{gridcell_field}/{region}.xyz"),
    group:
        "gridparam"
    wildcard_constraints:
        gridcell_field=regex_choice_list(
            [
                x
                for x in gridcell_field_list.index
                if not x
                in [
                    "developmentclass",
                    "growthplacedate",
                    "treedatadate",
                    "creationtime",
                    "updatetime",
                ]
            ]
        ),
    params:
        sql=lambda w: (
            "SELECT"
            " ST_X(ST_Centroid(geometry)) AS x,"
            " ST_Y(ST_Centroid(geometry)) AS y,"
            f" {w.gridcell_field} AS z"
            " FROM gridcell"
            f" WHERE {w.gridcell_field} IS NOT NULL"
            + (
                f" AND {w.gridcell_field} >= {gridcell_field_list.loc[w.gridcell_field, 'lower_limit']}"
                f" AND {w.gridcell_field} <= {gridcell_field_list.loc[w.gridcell_field, 'upper_limit']}"
                if gridcell_field_list.loc[w.gridcell_field, "type"] == "category"
                else f" AND {w.gridcell_field} >= {gridcell_field_list.loc[w.gridcell_field, 'lower_limit']}"
            )
        ),
    envmodules:
        "geoconda",
    shell:
        "ogr2ogr"
        " -f CSV"
        " -lco SEPARATOR=tab"
        " /vsistdout/"
        " {input[0]:q}"
        " -sql {params.sql:q} >"
        " {output[0]:q}"


rule extract_grid_date_xyz:
    input:
        rules.unpack_grid_region.output[0],
    output:
        temp("results/gridcell/{year}-{month}-{day}/{gridcell_field}/{region}.xyz"),
    group:
        "gridparam"
    wildcard_constraints:
        gridcell_field=regex_choice_list(
            ["growthplacedate", "treedatadate", "creationtime", "updatetime"]
        ),
    params:
        sql=lambda w: (
            "SELECT"
            " ST_X(ST_Centroid(geometry)) AS x,"
            " ST_Y(ST_Centroid(geometry)) AS y,"
            f" CAST(strftime('%Y', {w.gridcell_field}) AS integer) AS z"
            " FROM gridcell"
            f" WHERE strftime('%Y', {w.gridcell_field}) IS NOT NULL"
        ),
    envmodules:
        "geoconda",
    shell:
        "ogr2ogr"
        " -f CSV"
        " -lco SEPARATOR=tab"
        " /vsistdout/"
        " {input[0]:q}"
        " -sql {params.sql:q} >"
        " {output[0]:q}"


rule extract_developmentclass_xyz:
    input:
        rules.unpack_grid_region.output[0],
    output:
        temp("results/gridcell/{year}-{month}-{day}/developmentclass/{region}.xyz"),
    group:
        "gridparam"
    params:
        sql=lambda w: (
            "SELECT"
            " ST_X(ST_Centroid(geometry)) AS x,"
            " ST_Y(ST_Centroid(geometry)) AS y,"
            " CASE developmentclass "
            " WHEN 'A0' THEN 1"
            " WHEN 'S0' THEN 2"
            " WHEN 'T1' THEN 3"
            " WHEN 'T2' THEN 4"
            " WHEN 'Y1' THEN 5"
            " WHEN 'ER' THEN 6"
            " WHEN '02' THEN 7"
            " WHEN '03' THEN 8"
            " WHEN '04' THEN 9"
            " WHEN '05' THEN 10"
            " END AS z, "
            " developmentclass AS label"
            " FROM gridcell"
            " WHERE developmentclass IS NOT NULL"
            " AND developmentclass IN ('A0', 'S0', 'T1', 'T2', 'Y1', 'ER', '02', '03', '04', '05')"
        ),
    envmodules:
        "geoconda",
    shell:
        "ogr2ogr"
        " -f CSV"
        " -lco SEPARATOR=tab"
        " /vsistdout/"
        " {input[0]:q}"
        " -sql {params.sql:q} >"
        " {output[0]:q}"


rule rasterize_xyz:
    input:
        rules.extract_grid_param_xyz.output[0],
    output:
        temp(rules.extract_grid_param_xyz.output[0].replace(".xyz", ".tif")),
    group:
        "gridparam"
    params:
        field_type=lambda w: gridcell_field_list.loc[w.gridcell_field, "type"],
        resolution=16,
    envmodules:
        "grassgis",
        "r-env",
    script:
        "../scripts/rasterize_xyz.R"
