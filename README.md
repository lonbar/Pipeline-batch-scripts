The jobscripts to run LINC assume that the following variables are set (in e.g. ~/.bashrc):
* `LINC_DATA_DIR`, which is assumed to be the directory that contains your measurement sets,
* `LINC_INSTALL_DIR`, which is assumed to be a directory that contains a LINC installation/repository,
* `LINC_WORKING_DIR`, for intermediate outputs of the pipeline.

They can be adapted for other CWL workflows by adjusting the `$WORKFLOW_DIR` variable.

CWL workflows require a JSON or YAML file that, at the minimum, contains your measurement sets.
The following scripts create a basic JSON or YAML file respectively:
* `generate_json.sh`,
* `generate_yaml.sh`.

You can simply run these via e.g.
```<script> ${LINC_DATA_DIR}/<observation-dir>,```
where `<observation-dir>` is the path to an observation relative to `LINC_DATA_DIR`.

By default, CWL will attempt to pull Docker images from the Docker archive if a workflow requires it, and can automatically convert these images to Singularity images.
The scripts that runs CWL with this option are
* `run_linc.qsub` for Torque.
* `run_linc-cwltool.sh` for SLURM.

You may want to adjust some settings for your use case.
Note that for Torque, script variables have to specified as
```qsub -F "<observation id> <workflow> run_linc.qsub,```
where in the case of LINC `<workflow>` is either `HBA_calibrator` or `HBA_target`, while `<observation id>` is the ID of the observation (e.g. L123456).

If you instead want to run cwltool within a Singularity container, use the following scripts instead:
* `run_linc_contained.qsub` for Torque,
* `run_linc-cwltool_contained.sh` for SLURM.

Again, you may need to tweak the directory binds.
