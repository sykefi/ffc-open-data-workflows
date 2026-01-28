# Workflows for processing Finnish Forest Centre open data

## Finnish Forest Centre open data

## Workflow tools

The workflows are structured using [Snakemake](https://snakemake.github.io/).

Currently the geoprocessing utilizes modern [GDAL](https://gdal.org/) (>= 3.11) and [GRASS GIS](https://grass.osgeo.org/) (>= 8.5) driven via Python scripts.

Additional utilities used in the workflows include [csvkit](https://csvkit.readthedocs.io/) and [miller](https://miller.readthedocs.io/).

### Running using snakedeploy

### Running on CSC-clusters

For processing on a suitable HPC-cluster there are [apptainer](https://apptainer.org/) (singularity) container directives that will provide a suitable environment for executing the workflows. These should be executed before running the actual workflow.

The `examples/` contains a template SLURM batch job script that can be used to run the workflow on [Puhti](https://docs.csc.fi/computing/systems-puhti/).
The `sbatch` has to provide the project used via hte `--account` flag and the script log output targets can be changed with the `--output` and `--error` flags.

The target of the workflow can be edited by setting the `TARGET` variable inside the script. Also `account`, `output`, and `error` can be specified inside the script using `#SBATCH` directives.

The runner-script relies on being located under the `examples/` directory to find the `Snakefile`. While the script handles being called via a symlink, creating a copy in an alternative location will require setting the `SNAKEFILE` variable using different logic such as hardcoding the path to the `Snakefile`.

## Notes

The timestamps of the original `.gpkg` files are lost during unpacking.
These can be recovered if needed when the original input zipfiles are kept by using the `--keep-storage-local-copies` flag in the calls to `snakemake`.

## Topics

### Gridcell layer rasterization

The gridcell data provided by the Finnish Forest Centre are distributed as vector tiles in Geopackages.
This workflow allows automating the creation of Finland-wide rasters from the vector files.
Processing of the full data set at once for one time point can require over 1 Tb of free disk space.

The layer names are listed under `resources/gridcell.tsv` and are documented by the Finnish Forest Centre.


### Stand data

Workflow for combining stand data from regions and working with overlapping and duplicate stand polygons.


### Kemera data


### Forest use declarations


## Snakemake workflow structure

The main Snakefile `workflow/Snakefile` only collects the rules which are written in files under `workflow/rules/`.

### Common rules and code

`common/container.smk`
: Rule to generate apptainer containers.

`common/functions.smk`
: Provides functions used by the rules.

`common/wildcards.smk`
: Provides wildcard definitions and list of regions.

`common/storage.smk`
: Provides input functions for rules for data provided by the Finnish Forest Centre.

### Dataset specific rules and definitions

`metadata/{gridcell}.smk`
: Provides definitions and metadata for the data processing rules.

`data/{gridcell}.smk`
: Rules to acquire and process Finnish Forest Centre data.
