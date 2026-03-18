localrules:
    build_container,


rule build_container:
    input:
        definition=lambda w: workflow.source_path(
            f"../../../resources/container/{w.container}.def"
        ),
    output:
        container=protected("{container}.sif"),
    log:
        "<logs>/build_container/{container}.log",
    wildcard_constraints:
        container="(?:gdal-3.12|grass-8.5|base-env)",
    conda:
        "../../envs/apptainer.yaml"
    envmodules:
        "StdEnv",
    shell:
        "apptainer --silent build"
        " --fakeroot"
        " --bind={resources.tmpdir}:/tmp"
        " {output.container:q}"
        " {input.definition:q}"
        " > {log:q} 2>&1"
