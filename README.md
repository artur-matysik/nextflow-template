# Nextflow template

Generic template for Nextflow pipelines.

## Background

This Nextflow pipeline can be used as a template for quick building and execution of simple *ad-hoc* pipelines. It is based on `nf-core` and features modular and simplistic design, that can be easily modified and adopted for custom needs. 


## Quick run

### Prerequisites 

- Nextflow (recommended 22.03 or higher)
- Docker
- Git

Clone repo to the local directory (e.g. `~/pipelines`): 

```bash
cd ~/pipelines
git clone git@github.com:artur-matysik/nextflow-template.git
```

### Run the test

```bash
# Set pipeline location
$PIPELINE_URL="~/pipelines/nf-template"

# Set samplesheet location
$INPUT="~/pipelines/nf-template/test_input/samplesheet.csv"

# Go to execution location (modify). 
# Avoid running NF in the pipeline folder.
mkdir -p ~/exec
cd ~/exec

# Run the pipeline
nextflow run $PIPELINE_URL --input $INPUT -resume
```

- Test pipeline:
    - FASTQC (simple short-reads QC)
    - FASTP (reads filtering)
    - FASTQC (post filtering)
    - MULTIQC (results aggregation)
- Input is a samplesheet linking to mock minigut samples (provided by NF-Core)


## Info

- Simplified version of NF-core template pipeline for ad-hoc pipelines
- Uses [`samplesheet.csv`](test_input/samplesheet.csv) as an input
- Validation with [`nf-validation`](https://github.com/nextflow-io/nf-validation)
- Docker only
- Schema build with `nf-core tools (2.13.1)`
- Uses `nf-core` modules subworkflows (simplified)

### Profiles

- Not using profiles now


### Docker

- Docker is used by default, no need to call docker profile. 
- Docker config in `conf/docker.config` (included in `nextflow.config`)
- Define container in process definition (rather than `docker.config`), to allow easy re-use of the custom modules.
- If module is using custom Docker image, store Dockerfile in module folder `modules/custom/<module_name>/Dockerfile`.
- Use ECR biocontainers if available
- If process is using containers stored in private ECR, must login first for local execution, e.g.:

    ```bash
    # substitute <aws_account_number> and <aws_region>
    aws ecr get-login-password --region <aws_region> | docker login --username AWS --password-stdin <aws_account_number>.dkr.ecr.<aws_region>.amazonaws.com
    ```

### AWS Batch

- AWS Batch config in `conf/awsbatch.config`.
- Modify `process.queue` and `aws.region` ad needed. 
- Pass config e.g.: `nextflow run ... -c $PIPELINE_URL/conf/awsbatch.config`.
