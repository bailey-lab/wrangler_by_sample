# wrangler_by_sample

A program written to wrangle data on a sample by sample basis - each sample gets
its own independent job submission on a slurm cluster (e.g. longleaf or oscar).

Alternatively, for non-cluster systems, each sample can be analyzed
independently.

In both cases, If a run crashes, it doesn't have to be restarted from the
beginning.

## Installation:
Install conda (if you don't already have it) with:
[https://github.com/conda-forge/miniforge#mambaforge](https://github.com/conda-forge/miniforge#unix-like-platforms-mac-os--linux)

This link will install a version of conda called 'mamba' that also includes
conda.

Install snakemake in an environment called snakemake with:
```bash
mamba create -c conda-forge -c bioconda -n snakemake snakemake
```

or (if you didn't install mambaforge) with

Install snakemake in an environment called snakemake with:
```bash
conda create -c conda-forge -c bioconda -n snakemake snakemake
```

Make sure you have a profile that matches the computer you'd like to run this
on. Example profiles are provided here for slurm clusters and for non_slurm
standalone computers. You'll need to edit these profiles to be appropriate for
the way that your system is currently configured (e.g. don't set memory or CPU
requests that exceed your system's capacity). Copy this profile into a folder.
If you put the profile in ~/.config/snakemake/your_profile_name/config.yaml,
then you will be able to call it from the commandline with snakemake -s
your_script.smk --profile your_profile_name. In the usage instructions below, we
assume that you are using a slurm cluster, and that you put your file
in ~/.config/snakemake/slurm/config.yaml, but on a non-cluster, these
instructions will also work if you put your config file in
~/.config/snakemake/non_slurm/config.yaml and use --profile non_slurm

## Usage:
 - Download the contents of this git repo to a folder on your machine and cd
 into that folder (so that "ls" shows setup_run.smk and finish_run.smk).
 - Open the wrangler_by_sample.yaml file and fill in the variables using
instructions from the comments
 - Activate snakemake with:
```bash
conda activate snakemake
```
 - Run the first step with:
```bash
snakemake -s setup_run.smk --profile slurm
```
 - Run the second step with:
```bash
snakemake -s finish_run.smk --profile slurm
```
  - use --profile non_slurm if you are on a standalone computer (not a slurm
cluster).
