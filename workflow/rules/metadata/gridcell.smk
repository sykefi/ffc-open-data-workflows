gridcell_field_list = (
    read_table(workflow.source_path("../../../resources/gridcell.tsv"), dtype=str)
    .set_index("field")
    .to_dict("index")
)

gridcell_date_field = [k for k, v in gridcell_field_list.items() if v["type"] == "date"]

gridcell_param_field = [
    x
    for x in gridcell_field_list
    if not x
    in gridcell_date_field
    + [
        "developmentclass",
    ]
]


wildcard_constraints:
    gridcell_field=regex_choice_list(gridcell_field_list),


def gridcell_param_sql(wildcards):
    sql = (
        "SELECT"
        " ST_X(ST_Centroid(geometry)) AS x,"
        " ST_Y(ST_Centroid(geometry)) AS y,"
        f" {wildcards.gridcell_field} AS z"
        " FROM gridcell"
        f" WHERE {wildcards.gridcell_field} IS NOT NULL"
        + (
            f" AND {wildcards.gridcell_field} >= {gridcell_field_list[wildcards.gridcell_field]['lower_limit']}"
            f" AND {wildcards.gridcell_field} <= {gridcell_field_list[wildcards.gridcell_field]['upper_limit']}"
            if gridcell_field_list[wildcards.gridcell_field]["type"] == "category"
            else f" AND {wildcards.gridcell_field} >= {gridcell_field_list[wildcards.gridcell_field]['lower_limit']}"
        )
    )

    return sql


def gridcell_date_sql(wildcards):
    sql = (
        "SELECT"
        " ST_X(ST_Centroid(geometry)) AS x,"
        " ST_Y(ST_Centroid(geometry)) AS y,"
        f" CAST(strftime('%Y', {wildcards.gridcell_field}) AS integer) AS z"
        " FROM gridcell"
        f" WHERE strftime('%Y', {wildcards.gridcell_field}) IS NOT NULL"
    )

    return sql


def gridcell_developmentclass_sql(wildcards):
    sql = (
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
    )

    return sql
