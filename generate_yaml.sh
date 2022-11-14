#!/bin/bash -eu
#
# Script to generate input YAML-file for the LINC pipeline.
#
# Usage: generate_yaml.sh <observation-dir> <output-dir>
#
#     where <observation-dir> is a directory containing all Measurement Sets
#     for a given observation and <output-dir> is the directory to store the
#     resulting YAML file.
#
# The following environment variable can be overridden from the command line:
#     - SKYMODEL_DIR:    directory containing skymodel files
#     - SKYMODEL_A_TEAM: name of the A-team sky model file, which must be in
#                        the ${SKYMODEL_DIR} directory.

# Environment variables that may be overridden by the user
SKYMODEL_DIR="${SKYMODEL_DIR:-${LINC_INSTALL_DIR}/skymodels}"
SKYMODEL_A_TEAM="${SKYMODEL_A_TEAM:-Ateam_LBA_CC.skymodel}"

# Error function
error()
{
  echo "$@" >&2
  exit 1
}

# Check input arguments
[ $# -eq 2 ] || error "Usage: ${0} <dir-name> <output-dir>"
DIR=$(realpath ${1})
[ -d ${DIR} ] || error "Directory '${DIR}' does not exist"
YAML="${2}/$(basename ${DIR}).yaml"

# Check if skymodels exist
[ -d ${SKYMODEL_DIR} ] \
    || error "Skymodel directory '${SKYMODEL_DIR}' does not exist"
[ -f ${SKYMODEL_DIR}/${SKYMODEL_A_TEAM} ] \
    || error "Skymodel file '${SKYMODEL_DIR}/${SKYMODEL_A_TEAM}' not found"

# Fetch list of MS files, determine length and index of last element
declare FILES=($(ls -1d ${DIR}/*.MS 2>/dev/null))
len=${#FILES[@]}
last=$(expr ${len} - 1)
[ ${len} -gt 0 ] || error "Directory '${DIR}' contains no MS-files"

# Open output file
exec 3> ${YAML}

# Write file contents
cat >&3 <<EOF
msin:
$(for((i=0; i<${len}; i++))
  do
    echo "    - class: \"Directory\""
    echo "      path : \"${FILES[$i]}\""
  done
)
do_demix: false
do_smooth: false
A-Team_skymodel: 
    class: "File"
    path: "${SKYMODEL_DIR}/${SKYMODEL_A_TEAM}"
calibrator_path_skymodel:
    class: "Directory"
    path: "${SKYMODEL_DIR}/"
EOF

# Close output file
exec 3>&-

echo "Wrote output to '${YAML}'"
