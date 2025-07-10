rule assembly:
    threads: config["SHOVILL"]["THREADS"]
    shadow: "shallow"
    conda: "../envs/assembly.yaml"
    params:
        assemblies_dir = ASSEMBLIES
    input:
        read1 = CLEAN_READS/"{accession}_1.trimmed.fastq.gz",
        read2 = CLEAN_READS/"{accession}_2.trimmed.fastq.gz"
    output:
        folder = temp(directory(ASSEMBLIES/"{accession}")),
        assembly = ASSEMBLIES/"{accession}_assembly.fasta"
    log:
        LOGDIR/"assembly"/"{accession}.log"
    shell:
        """
        exec >{log}
        exec 2>&1
         shovill --outdir {params.assemblies_dir}/{wildcards.accession} \
            --R1 {input.read1} --R2 {input.read2} --force

        mv {params.assemblies_dir}/{wildcards.accession}/contigs.fa {output.assembly}

        exit 0

        """

rule assembly_report:
    threads: 1
    conda: "../envs/assembly.yaml"
    input:
        assembly_files = expand(ASSEMBLIES/"{accession}_assembly.fasta", accession=iter_accessions())
    output:
        stats = REPORTS/"assembly_report.txt"
    log:
        LOGDIR/"assembly_report.log"
    script:
        "../scripts/assembly_stats.py"
    