# Workflows for processing Finnish Forest Centre open data

## Finnish Forest Centre open data

## Workflow tools

The workflows are structured using [Snakemake](https://snakemake.github.io/).

For processing on a suitable HPC-cluster there is an [apptainer](https://apptainer.org/) (singularity) container directive that would provide a suitable environment for executing the workflows. Currently the geoprocessing utilizes [GRASS GIS](https://grass.osgeo.org/) driven via R-scripts.

Additional utilities used in the workflows include [csvkit](https://csvkit.readthedocs.io/), [GDAL tools](https://gdal.org/en/stable/programs/index.html), and [miller](https://miller.readthedocs.io/).

### Running on CSC-clusters

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
Processing of the full data set at once for one time point requires almost 1 Tb of free disk space.

A meta target for generating most layers associated with one archived version of the gridcell data is: `results/target/gridcell/all/{year}-{month}-{day}.lst` which will generate corresponding raster files under `results/gridcell/{year}-{month}-{day}/{gridcell_field}.tif` where `{gridcell_field}` is the name of a layer included in the data and `{year}`, `{month}`, `{day}` correspond to a data release date by the Finnish Forest Centre.

The layer names are listed under `resources/gridcell.tsv` and are documented by the Finnish Forest Centre.

### Stand data

Workflow for combining stand data from regions and working with overlapping and duplicate stand polygons.


### Kemera data


### Forest use declarations


## Snakemake workflow structure

The main Snakefile `workflow/Snakefile` only collects the rules which are written in files under `workflow/rules/`.

`definitions.smk`
: This file contains helper functions and construct the lists of variables in the data and the region divisions.

`container.smk`
: This file contains a rule to build the apptainer container for running the workflow rules depending on GRASS GIS and R on a HPC cluster.

`data.smk`
: This file contains rules to download the Finnish Forest Centre open data used by the workflows.

`gridcell.smk`
: This file contains the rules for processing the gridcell vector files and converting them to rasters.

`stand.smk`
: This file contains rules for summarizing duplicate stands and for merging stand data for the whole of Finland.

`target.smk`
: This file contains meta rules for downloading a full data set and for performing conversion operations for a full data set using rules defined in the preceding files.
