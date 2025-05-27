localrules:
    build_container,


rule build_container:
    input:
        workflow.source_path("../../resources/container.def"),
    output:
        "container.sif",
    shell:
        "singularity build {output[0]:q} {input[0]:q}"
