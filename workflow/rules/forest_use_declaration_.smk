rule merge_forest_use_declaration_data:
    input:
        ancient(
            lambda w: expand(
                "resources/aineistot/Metsankayttoilmoitukset/{day}_{month}_{year}/Maakunta/MKI_{region}.gpkg",
                region=region_list,
                year=w.year,
                month=w.month,
                day=w.day,
            )
        ),
    output:
        "results/forest_use_declaration/{year}-{month}-{day}/forest_use_declaration.gpkg",
    shell:
        'for x in {input:q}; do ogr2ogr -skipfailures -append {output[0]:q} "${{x}}"; done'
