#!/usr/bin/env python3
# Jordi Sevilla Fortuny
# This script is designed to be run as part of a Snakemake workflow.
# It reads assembly FASTA files, calculates statistics, and writes them to an output file.
# The expected input and output files are defined in the Snakemake workflow.
# The script uses the Biopython library to handle FASTA files and perform sequence analysis.

from Bio import SeqIO
import logging

# Define assembly class
class Assembly:
    def __init__(self, name, fasta_file):
        self.name = name
        self.fasta = list(SeqIO.parse(fasta_file, "fasta"))
        self.genome_size = sum(len(record.seq) for record in self.fasta)
        self.n_contigs = len(self.fasta)


    def calculate_n50(self):
        sorted_lengths = sorted((len(record.seq) for record in self.fasta), reverse=True)
        cumulative_length = 0
        for length in sorted_lengths:
            cumulative_length += length
            if cumulative_length >= self.genome_size / 2:
                n50 = length
                break
        return n50
    
    def get_n_ambiguous_bases(self):
        full_genome = ''.join(str(record.seq) for record in self.fasta).upper()
        nonambiguous_bases = sum(full_genome.count(base) for base in "ACGT")
        return len(full_genome) - nonambiguous_bases
    

    def get_stats(self):
        n50 = self.calculate_n50()
        n_ambiguous_bases = self.get_n_ambiguous_bases()
        return {
            "name": self.name,
            "genome_size": self.genome_size,
            "n_contigs": self.n_contigs,
            "n50": n50,
            "n_ambiguous_bases": n_ambiguous_bases
        }
    

def main():
    logging.basicConfig(filename=snakemake.log[0], level=logging.INFO)

    # Read input files
    files = snakemake.input.assembly_files
    assemblies = [Assembly(name= file.split("/")[-1].replace("_assembly.fasta",""), fasta_file=file) for file in files]
    stats = [assembly.get_stats() for assembly in assemblies]
    # Write output
    with open(snakemake.output.stats, "w") as f:
        f.write("name\tgenome_size\tn_contigs\tn50\tn_ambiguous_bases\n")
        for stat in stats:
            f.write(f"{stat['name']}\t{stat['genome_size']}\t{stat['n_contigs']}\t{stat['n50']}\t{stat['n_ambiguous_bases']}\n")

    logging.info("Assembly statistics calculated successfully.")


if __name__ == "__main__":
    main()


