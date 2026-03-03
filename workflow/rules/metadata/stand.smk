stand_layer_list = [
    "stand",
    "restriction",
    "treestratum",
    "treestandsummary",
    "operation",
    "assortment",
    "specification",
    "specialfeature",
    "datasource",
    "treestand",
]


wildcard_constraints:
    stand_layer=regex_choice_list(stand_layer_list),


def stand_param_sql(wildcards):
    layer = wildcards.stand_layer

    match layer:
        case "datasource":
            id_column = "code"
        case _:
            id_column = f"{layer}id"

    sql = f"SELECT * FROM (SELECT *, row_number() OVER (PARTITION BY {id_column}) AS row_number FROM {layer}) WHERE row_number = 1"

    return sql
