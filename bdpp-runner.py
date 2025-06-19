#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Jordi Sevilla Fortuny
# Script to launch the snakemake workflow BDPP

import os
import sys
from argparse import ArgumentParser
from sys import argv
from shutil import which

# Parse command line arguments
def parse_args():
    parser = ArgumentParser(description="Run the BDPP snakemake workflow.")
    parser.add_argument(
        "-c", "--cores", type=int, default=4, help="Number of cores to use for the workflow"
    )
    parser.add_argument(
        "-a", "--accessions",
        type=str,
        required=True
        help="File containing the accessions to process (one per line)"
    )

    parser.add_argument(
        "-o", "--outdir",
        type=str,
        default="bdpp_output", 
        help="Output directory for the results"
    )
    parser.add_argument(
        "-p", "--prefix",
        type=str,
        default="bdpp_job",
        help="Prefix for the output files"
    )
    parser.add_argument(
        "-r", "--reference",
        type=str,
        required=True,
        help="Accession of the reference genome to be used for the mapping step. This should be a valid accession from the NCBI database. (NC_011035.1 for example)"
    )


    return parser.parse_args()

def main():
    args = parse_args()
    
    # Check if snakemake is installed
    if which("snakemake") is None:
        print("Error: Snakemake is not installed or not found in PATH.")
        sys.exit(1)

    # Check if the accessions file exists
    if not os.path.isfile(args.accessions):
        print(f"Error: The accessions file '{args.accessions}' does not exist.")
        sys.exit(1)
    
    # Ges script directory
    script_dir = os.path.dirname(os.path.abspath(argv[0]))

    # Construct the snakemake command
    cmd = f"cd {script_dir} && " + " ".join([
        "snakemake",
        "--cores", str(args.cores),
        "--config",
        f"accessions={os.path.abspath(args.accessions)}",
        f"outdir={os.path.abspath(args.outdir)}",
        f"prefix={args.prefix}",
        f"reference={args.reference}",
        "--use-conda"
    ])

    # Execute the command
    os.system(cmd)