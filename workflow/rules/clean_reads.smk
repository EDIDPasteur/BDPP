rule trim_reads:
    threads: config["TRIMMOMATIC"]["THREADS"]
    conda: "../envs/clean_reads.yaml"
    params:
        outdir=CLEAN_READS,
        adapter=config["TRIMMOMATIC"]["ADAPTERS_FILE"],
        minlen=config["TRIMMOMATIC"]["MIN_LENGTH"],
        qualitymin=config["TRIMMOMATIC"]["QUALITY_THRESHOLD"],
        leading=config["TRIMMOMATIC"]["LEADING"],
        trailing=config["TRIMMOMATIC"]["TRAILING"]
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
        trimmomatic PE -threads {threads} -phred33 \
            {input.read_1} {input.read_2} \
            {output.read_1} /dev/null \
            {output.read_2} /dev/null \
            ILLUMINACLIP:{params.adapter}:2:30:10 \
            LEADING:{params.leading} TRAILING:{params.trailing} \
            SLIDINGWINDOW:4:{params.qualitymin} \
            MINLEN:{params.minlen} 
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