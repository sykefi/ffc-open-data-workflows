rule target_gridcell_download:
    input:
        lambda w: expand(
            rules.unpack_gridcell_region.output[0],
            region=region_list,
            year=w.year,
            month=w.month,
            day=w.day,
        ),
    output:
        "results/target/gridcell/download/{year}-{month}-{day}.lst",
    shell:
        "touch {output:q}"


rule target_stand_download:
    input:
        lambda w: expand(
            rules.unpack_stand_region.output[0],
            region=region_list,
            year=w.year,
            month=w.month,
            day=w.day,
        ),
    output:
        "results/target/stand/download/{year}-{month}-{day}.lst",
    shell:
        "touch {output:q}"


rule target_gridcell_variable_group:
    input:
        lambda w: expand(
            rules.patch_gridcell_raster.output[0],
            gridcell_field=gridcell_grouping[w.gridcell_group],
            year=w.year,
            month=w.month,
            day=w.day,
        ),
    output:
        "results/target/gridcell/{gridcell_group}/{year}-{month}-{day}.lst",
    wildcard_constraints:
        gridcell_group=regex_choice_list(gridcell_grouping),
    shell:
        "touch {output:q}"


rule target_gridcell_all:
    input:
        lambda w: expand(
            rules.patch_gridcell_raster.output[0],
            gridcell_group=gridcell_grouping,
            year=w.year,
            month=w.month,
            day=w.day,
        ),
    output:
        "results/target/gridcell/all/{year}-{month}-{day}.lst",
    shell:
        "touch {output:q}"
