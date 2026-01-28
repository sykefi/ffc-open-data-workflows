with open(workflow.source_path("../../../resources/region.lst"), encoding="utf-8") as f:
    region_list = f.read().splitlines()


wildcard_constraints:
    region=regex_choice_list(region_list),
    day=r"\d{2}",
    month=r"\d{2}",
    year=r"\d{4}",
