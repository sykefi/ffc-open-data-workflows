rule stand_region_id:
    input:
        rules.unpack_stand_region.output[0],
    output:
        temp("results/stand/{year}-{month}-{day}/id/{region}.tsv"),
    params:
        sql=lambda w: f"SELECT standid, '{w.region}' AS region FROM stand",
    shell:
        "ogr2ogr -f CSV -lco SEPARATOR=tab /vsistdout/ {input[0]:q} -sql {params.sql:q} > {output[0]:q}"


rule merge_stand_id:
    input:
        lambda w: expand(
            rules.stand_region_id.output[0],
            region=region_list,
            year=w.year,
            month=w.month,
            day=w.day,
        ),
    output:
        "results/stand/{year}-{month}-{day}/id.tsv",
    shell:
        "csvstack -t {input:q} | mlr --icsv --otsv cat > {output[0]:q}"


rule merge_stand_data:
    input:
        lambda w: expand(
            rules.unpack_stand_region.output[0],
            region=region_list,
            year=w.year,
            month=w.month,
            day=w.day,
        ),
    output:
        "results/stand/{year}-{month}-{day}/stand.gpkg",
    shell:
        'for x in {input:q}; do echo "${{x}}"; ogr2ogr -skipfailures -append {output[0]:q} "${{x}}"; done'
