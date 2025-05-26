from os.path import dirname
from pandas import read_table


def regex_choice_list(choices):
    return f"(?:{'|'.join([str(x) for x in set(choices)])})"


with open(workflow.source_path("../../resources/region.lst"), encoding="utf-8") as f:
    region_list = f.read().splitlines()


gridcell_field_list = read_table(
    workflow.source_path("../../resources/gridcell.tsv"), dtype=str
).set_index("field")


wildcard_constraints:
    region=regex_choice_list(region_list),
    gridcell_field=regex_choice_list(gridcell_field_list.index),
    day=r"\d{2}",
    month=r"\d{2}",
    year=r"\d{4}",


SMK_DATA_ROOT_URL = "https://avoin.metsakeskus.fi/aineistot"
