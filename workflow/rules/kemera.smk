rule merge_kemera_data:
    input:
        ancient(
            lambda w: expand(
                "resources/aineistot/Kemera/{day}_{month}_{year}/Maakunta/Kemera_{region}.gpkg",
                region=region_list,
                year=w.year,
                month=w.month,
                day=w.day,
            )
        ),
    output:
        "results/kemera/{year}-{month}-{day}/kemera.gpkg",
    shell:
        'for x in {input:q}; do ogr2ogr -append {output[0]:q} "${{x}}"; done'


def kemera_query_sql(wildcards):
    dt = wildcards.declarationtype
    geom = wildcards.geometry

    if geom == "stand":
        layers = [
            "06_16",
            "10_10",
            "10_30",
            "10_91",
            "11_30",
            "11_50",
            "11_90",
            "11_91",
            "13_50",
        ]

        if dt == "completiondeclaration":
            layers += ["13_30"]
    else:
        layers = ["11_60", "11_70"]

    layer_queries = []

    base_columns = ["fid AS layer_id", "geometry", "workcode"]

    if geom == "stand":
        base_columns += ["standnumber"]

    for x in layers:
        layer = f"{dt}_{geom}_{x}"
        columns = base_columns.copy()

        columns += [f"'{layer}' AS kemera_layer"]

        if geom == "stand":
            columns += ["NULL AS objectid"] if x in ["10_91"] else ["objectid"]

            if dt == "completiondeclaration":
                columns += (
                    ["NULL AS realstartdate", "NULL AS realenddate"]
                    if x in ["13_50"]
                    else ["realstartdate", "realenddate"]
                )
        elif dt == "completiondeclaration":
            columns += ["NULL AS realstartdate", "NULL AS realenddate"]

        if dt == "application":
            columns += (
                ["NULL AS estimatedstartdate", "NULL AS estimatedenddate"]
                if x in ["06_16", "10_10", "10_30", "10_91", "13_50"]
                else ["estimatedstartdate", "estimatedenddate"]
            )

        columns += (
            ["NULL AS projectenddate"]
            if x in ["13_30", "13_50"]
            else ["projectenddate"]
        )

        layer_queries += [f"SELECT {', '.join(columns)} FROM {layer}"]

    sql = " UNION ALL ".join(layer_queries)

    return sql


rule merge_kemera_data_layers:
    input:
        rules.merge_kemera_data.output[0],
    output:
        "results/kemera/{year}-{month}-{day}/kemera/{declarationtype}_{geometry}.gpkg",
    wildcard_constraints:
        declarationtype="(?:application|completiondeclaration)",
        geometry="(?:stand|line|point)",
    params:
        sql=kemera_query_sql,
        layer=lambda w: f"{w.declarationtype}_{w.geometry}",
        geometry=lambda w: {
            "stand": "MultiPolygon",
            "line": "MultiLineString",
            "point": "MultiPoint",
        }[w.geometry],
    shell:
        "ogr2ogr "
        " -unsetFid"
        " {output[0]:q}"
        " {input[0]:q}"
        " -sql {params.sql:q}"
        " -nln {params.layer}"
        " -nlt PROMOTE_TO_MULTI -nlt {params.geometry}"
