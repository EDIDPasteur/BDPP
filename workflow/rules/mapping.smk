rule fetch_reference_genome:
    threads: 1
    conda: "../envs/mapping.yaml"
    params:
        accession = config["REFERENCE"]
    output:
        genome = ALIGNMENTS/"reference_genome.fasta"
    log:
        LOGDIR/"fetch_reference_genome.log"
    shell:
        "esearch -db nucleotide -query {params.accession} | efetch -format fasta > {output.genome} 2> {log}"
    
rule snippy:
    threads: config["SNIPPY"]["THREADS"]
    conda: "../envs/mapping.yaml"
    params:
        min_depth = config["SNIPPY"]["MIN_DEPTH"],
        support_fraction = config["SNIPPY"]["FRAC_SUPP"],
        min_qual = config["SNIPPY"]["MIN_QUALITY"],
        mapping_qual = config["SNIPPY"]["MAP_QUALITY"],
        mapping_dir = SNIPPY
    input:
        reference = ALIGNMENTS/"reference_genome.fasta",
        read1 = CLEAN_READS/"{accession}_1.trimmed.fastq.gz",
        read2 = CLEAN_READS/"{accession}_2.trimmed.fastq.gz"
    output:
        outdir = directory(SNIPPY/"{accession}")
    log:
        LOGDIR/"snippy"/"{accession}.log"
    shell:
        """
        exec >{log}
        exec 2>&1
        snippy --cpus {threads} --outdir {output.outdir} \
            --reference {input.reference} \
            --R1 {input.read1} --R2 {input.read2} \
            --outdir {output.outdir} \
            --mincov {params.min_depth} \
            --minfrac {params.support_fraction} \
            --minqual {params.min_qual} \
            --mapqual {params.mapping_qual} 
        """
    
rule snippy_core:
    threads: config["SNIPPY"]["THREADS"]
    conda: "../envs/mapping.yaml"
    params:
        mapping_dir = ALIGNMENTS,
        prefix = f"{ALIGNMENTS}/{config["PREFIX"]}_mapping"
    input:
        reference = ALIGNMENTS/"reference_genome.fasta",
        snippy_dirs = expand(SNIPPY/"{accession}", accession=iter_accessions())
    output:
        core_alignment = ALIGNMENTS/f"{config["PREFIX"]}_mapping.full.aln"
    log:
        LOGDIR/"snippy_core"/"snippy_core.log"
    shell:
        """
        exec >{log}
        exec 2>&1
        snippy-core --ref {input.reference} \
            --prefix {params.prefix} \
            {input.snippy_dirs}
        """
