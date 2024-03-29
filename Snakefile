rule all:
    input:
        "output/aggregated/chr21.txt",
        "output/aggregated/chr22.txt",

PYTHON2='/ssd/sda1/dalai/anaconda3/envs/python2/bin/python'
REFERENCE='/shahlab/pipelines/reference/GRCh37-lite.fa'
LOGDIR='/ssd/sda1/dalai/snakemake-realignment/logs'

# the checkpoint that shall trigger re-evaluation of the DAG
checkpoint readgroups:
    input:
        "data/{sample}.bam"
    output:
        directory("output/readgroups/{sample}")
    shell:
        "mkdir output/readgroups/{wildcards.sample}; "
        "scripts/extract_readgroup.sh {input} | xargs -I % touch output/readgroups/{wildcards.sample}/%.txt"

# an intermediate rule
rule create_readgroup:
    input:
        sample_bam="data/{sample}.bam",
        readgroup_file="output/readgroups/{sample}/{i}.txt",
    output:
        "output/fastq/{sample}/{i}.fastq",
    params:
        readgroup="{i}",
    log:
        '{logdir}/{{sample}}/{{i}}.log'.format(
            logdir=LOGDIR
        )
    shell:
        '''
        {PYTHON2} scripts/bamtofastq.py {input.sample_bam} -r {params.readgroup} > {output} 2> {log}
        '''

rule create_bams:
    input:
        "output/fastq/{sample}/{i}.fastq",
    output:
        "output/bam/{sample}/{i}.bam",
    params:
        readgroup="{i}",
    shell:
        '''
        # bwa mem -p -M -R {params.readgroup} {REFERENCE} {input} -t 5 | samtools view -bSh - > {output}
        bwa mem -p -M {REFERENCE} {input} -t 30 | samtools view -bSh - > {output}
        '''

def aggregate_input(wildcards):
    checkpoint_output = checkpoints.readgroups.get(**wildcards).output[0]
    return expand("output/bam/{sample}/{i}.bam",
           sample=wildcards.sample,
           i=glob_wildcards(os.path.join(checkpoint_output, "{i}.txt")).i)

# an aggregation over all produced clusters
rule aggregate:
    input:
        aggregate_input
    output:
        "output/aggregated/{sample}.txt"
    shell:
        "ls -1 {input} > {output}"
