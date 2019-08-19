snakemake -p --printshellcmds --cluster "qsub -V -q shahlab.q -l h_vmem=32G,mem_free=32G,mem_token=32G" -j 32
