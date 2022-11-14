#!/bin/bash -eu
#
# Script to run the LINC pipeline on observation data.
#

# Use the following SLURM parameters when this script is run as SLURM job.
#SBATCH --cpus-per-task=20

#SBATCH -N 1                  # number of nodes
#SBATCH -c 4                  # number of cores; coupled to 8000 MB memory per core
#SBATCH -t 72:00:00           # maximum run time in [HH:MM:SS] or [MM:SS] or [minutes]
#SBATCH -p cosma              # partition (queue); job can run up to 3 days
#SBATCH --output=slurm-%A.out
#SBATCH -A durham
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=4096

# Error function
error()
{
  echo -e "ERROR: $@" >&2
  exit 1
}

# Check input arguments
[ $# -eq 2 ] || error "\
Usage: ${0} <observation-id> <work-flow>
    where <observation-id> is the ID of a given observation,
    and <work-flow> is the name of the workflow.
    Measurement Sets for the given Observation ID are searched for in the
    directory '${LINC_DATA_DIR}'.
    The currently supported workflows are: HBA_calibrator, and HBA_target."

OBSID=${1}
INPUT_DIR=${LINC_DATA_DIR}/${OBSID}
OUTPUT_DIR=${LINC_WORKING_DIR}/${OBSID}
TEMP_DIR=${TMPDIR:-/tmp}/${USER}/${OBSID}

WORKFLOW=${2}
WORKFLOW_DIR=${LINC_INSTALL_DIR}/workflows
CWLFILE="${WORKFLOW_DIR}/${WORKFLOW}.cwl"

# Check if there's a user-defined JSON-file in ${OUTPUT_DIR}. 
# If not, use the default JSON-file in ${LINC_DATA_DIR}.
JSONFILE=${OUTPUT_DIR}.json
[ -f ${JSONFILE} ] || JSONFILE=${INPUT_DIR}.json

# Tar-ball that will contain all the log files produced by the pipeline
LOGFILES=${OUTPUT_DIR}/logfiles.tar.gz

# Increase open file limit to hardware limit
ulimit -n $(ulimit -Hn)

# Print all SLURM variables
echo -e "
================  SLURM variables  ================
$(for s in ${!SLURM@}; do echo "${s}=${!s}"; done)
===================================================
"

# Show current shell ulimits
echo -e "
============  Current resource limits  ============
$(ulimit -a)
===================================================
"

# Tell user what variables will be used:
echo -e "
The LINC pipeline will run, using the following settings:
  Input directory          : ${INPUT_DIR}
  Input specification file : ${JSONFILE}
  Workflow definition file : ${CWLFILE}
  Output directory         : ${OUTPUT_DIR}
  Temporary directory      : ${TEMP_DIR}
  Tar-ball of all log files: ${LOGFILES} 
"

# Check if directories and files actually exist. If not, bail out.
[ -d ${INPUT_DIR} ] || error "Directory '${INPUT_DIR}' does not exist"
[ -f ${CWLFILE} ] || error "Workflow file '${CWLFILE}' does not exist"
[ -f ${JSONFILE} ] || error "Input specification file '${JSONFILE}' does not exist"

# Command that will be used to run the CWL workflow
# CWLtool will pull in an convert a Docker image with which to run LINC
COMMAND="cwltool \
  --singularity \
  --debug \
  --parallel \
  --timestamps \
  --outdir ${OUTPUT_DIR} \
  --tmpdir-prefix ${TEMP_DIR} \
  ${CWLFILE} \
  ${JSONFILE}"

echo "${COMMAND}"

# Execute command
if ${COMMAND}
then
  echo -e "\nSUCCESS: Pipeline finished successfully\n"
  exit 0
else
  STATUS=${?}
  if [ -d ${TEMP_DIR} ]
  then
    # Create sorted list of contents of ${TEMP_DIR}
    find ${TEMP_DIR} | sort > ${TEMP_DIR}/contents.log
    # Save all log files for later inspection.
    find ${TEMP_DIR} -name "*.log" -print0 | \
      tar czf ${LOGFILES} --null -T -
  fi
  echo -e "\n**FAILURE**: Pipeline failed with exit status: ${STATUS}\n"
  exit ${STATUS}
fi
