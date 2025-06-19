rule assembly:
    threads: config["SPADES"]["THREADS"]
    shadow: "shallow"
    conda: "../envs/assembly.yaml"
    params:
        memory = config["SPADES"]["MEMORY"],
        kmers = config["SPADES"]["KMER_LENGTHS"],
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
        mkdir -p {params.assemblies_dir}/{wildcards.accession}
        spades.py --threads {threads} --memory {params.memory} \
            -k {params.kmers} \
            -1 {input.read1} -2 {input.read2} \
            -o {params.assemblies_dir}/{wildcards.accession} \
            --only-assembler

        mv {params.assemblies_dir}/{wildcards.accession}/contigs.fasta {output.assembly}

        exit 0

        """