
rule download_reads:
    """
    Download raw sequencing reads from NCBI SRA.
    """
    threads: 1
    shadow: "full"
    conda: "../envs/ena.yaml"
    params:
        outdir=RAW_READS
    output:
        fread_folder = temp(directory(RAW_READS/"{accession}")),
        read_1 = RAW_READS/"{accession}_1.fastq.gz",
        read_2 = RAW_READS/"{accession}_2.fastq.gz"
    log:
        LOGDIR/"download_reads"/"{accession}.log"
    shell:
        """
        exec >{log}
        exec 2>&1

        enaDataGet.py -f fastq -d {params.outdir} {wildcards.accession}
        mv {params.outdir}/{wildcards.accession}/* {params.outdir}
        """

rule pre_clean_qc:
    """
    Perform quality control on raw reads.
    """
    threads: 2
    conda: "../envs/qc.yaml"
    params:
        outdir=RAW_REPORTS
    input:
        read_1 = RAW_READS/"{accession}_1.fastq.gz",
        read_2 = RAW_READS/"{accession}_2.fastq.gz"
    output:
        report1 = RAW_REPORTS/"{accession}_1_fastqc.html",
        report2 = RAW_REPORTS/"{accession}_2_fastqc.html"
    log:
        LOGDIR/"pre_clean_qc"/"{accession}.log"
    shell:
        """
        exec >{log}
        exec 2>&1
        fastqc {input.read_1} {input.read_2} --outdir {params.outdir} --threads {threads} 

        """
    
rule pre_clean_multiqc:
    conda: "../envs/qc.yaml"
    params:
        reports_dir=REPORTS,
        raw_reports_dir=RAW_REPORTS,
        report_name="raw_reads_multiqc_report.html"
    input:
        reports_1 = expand(RAW_REPORTS/"{accession}_1_fastqc.html", accession=iter_accessions()),
        reports_2 = expand(RAW_REPORTS/"{accession}_2_fastqc.html", accession=iter_accessions())
    output:
        multiqc_report = REPORTS/"raw_reads_multiqc_report.html"
    log:
        LOGDIR/"pre_clean_multiqc"/"multiqc.log"
    shell:
        """
        exec >{log}
        exec 2>&1
        multiqc {params.raw_reports_dir} -o {params.reports_dir} -n {params.report_name} --force
        """
