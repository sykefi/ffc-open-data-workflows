#!/bin/bash
#SBATCH --job-name=snakemake_slurm
#SBATCH --time=20:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=4000MB
#SBATCH --gres=nvme:40
#SBATCH --partition=small

TARGET=results/target/gridcell/all/2021-03-29.lst

SCRIPT_DIR=$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/Command=/{print $2}')
RUNNER_DIR="$(dirname "$(readlink -f "${SCRIPT_DIR}")")"
WORKDIR="/scratch/${SLURM_JOB_ACCOUNT}/workdir/finnish-forest-centre-data/"
SNAKEFILE="$(realpath ${RUNNER_DIR}/../workflow/Snakefile)"

mkdir -p "${WORKDIR}"

module load snakemake
snakemake --keep-going \
	--rerun-incomplete \
	--latency-wait 15 \
	--cores ${SLURM_CPUS_PER_TASK} \
	 -s "${SNAKEFILE}" \
	--directory ${WORKDIR} \
	--use-apptainer \
	--apptainer-args "--bind ${LOCAL_SCRATCH}:${LOCAL_SCRATCH}" \
	--use-envmodules \
	--default-resources tmpdir=\"${LOCAL_SCRATCH}\" \
	-- ${TARGET}
