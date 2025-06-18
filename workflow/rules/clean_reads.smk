rule trim_reads:
    shadow: "shallow"
    threads: config["FASTP"]["THREADS"]
    conda: "../envs/clean_reads.yaml"
    params:
        outdir=CLEAN_READS,
        minlen=config["FASTP"]["MINLEN"],
        minquality=config["FASTP"]["QUALITY_THRESHOLD"],
        window_size=config["FASTP"]["WINDOW_SIZE"]
    input:
        read_1=RAW_READS/"{accession}_1.fastq.gz",
        read_2 = RAW_READS/"{accession}_2.fastq.gz"
    output:
        read_1=CLEAN_READS/"{accession}_1.trimmed.fastq.gz",
        read_2=CLEAN_READS/"{accession}_2.trimmed.fastq.gz"
    log:
        LOGDIR/"clean_reads"/"{accession}.log"
    shell:
        """
        exec >{log}
        exec 2>&1
        fastp -i {input.read_1} -I {input.read_2} \
            -o {output.read_1} -O {output.read_2} \
            --detect_adapter_for_pe \
            --thread {threads} \
            --average_qual {params.minquality} \
            --length_required {params.minlen} \
            --cut_front --cut_tail \
            --cut_window_size {params.window_size} \
            --cut_mean_quality {params.minquality}
             
        """

rule post_clean_qc:
    """
    Perform quality control on cleaned reads.
    """
    threads: 2
    conda: "../envs/qc.yaml"
    params:
        outdir=CLEAN_REPORTS
    input:
        read_1=CLEAN_READS/"{accession}_1.trimmed.fastq.gz",
        read_2=CLEAN_READS/"{accession}_2.trimmed.fastq.gz"
    output:
        report1=CLEAN_REPORTS/"{accession}_1.trimmed.fastq.html",
        report2=CLEAN_REPORTS/"{accession}_2.trimmed.fastq.html"
    log:
        LOGDIR/"post_clean_qc"/"{accession}.log"
    shell:
        """
        exec >{log}
        exec 2>&1
        fastqc {input.read_1} {input.read_2} --outdir {params.outdir} --threads {threads} 
        """

rule post_clean_multiqc:
    params:
        reports_dir=REPORTS,
        clean_reports_dir=CLEAN_REPORTS,
        report_name="clean_reads_multiqc_report.html"
    input:
        reports_1=expand(CLEAN_REPORTS/"{accession}_1.trimmed.fastq.html", accession=iter_accessions()),
        reports_2=expand(CLEAN_REPORTS/"{accession}_2.trimmed.fastq.html", accession=iter_accessions())
    output:
        multiqc_report=REPORTS/"clean_reads_multiqc_report.html"
    log:
        LOGDIR/"post_clean_multiqc"/"multiqc.log"
    shell:
        """
        exec >{log}
        exec 2>&1
        multiqc {params.clean_reports_dir} \
            --outdir {params.reports_dir} \
            --filename {params.report_name}
 
        """