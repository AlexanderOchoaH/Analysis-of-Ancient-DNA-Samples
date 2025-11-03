# Analysis of Ancient DNA Samples

### 1. Pipeline for Genus Abundance Estimation from Ancient DNA PE Reads.

Step 1: Used AdapterRemoval v2.3.2 (Schubert et al. 2014; [https://github.com/MikkelSchubert/adapterremoval](url)) for the trimming and collapsing of AVITI PE150 reads.

`AdapterRemoval --file1 R1.fastq.gz --file2 R2.fastq.gz --mm 3 --minlength 25 --collapse --trimns --trimqualities --qualitymax 50 --basename trimmed_reads
`

Step 2: Used Kraken v2.1.3 (Wood et al. 2019; [https://github.com/DerrickWood/kraken2/releases](url)) for assigning taxonomic levels to both collapsed and uncollapsed PE reads separately.

`kraken2 --threads 24 --db /Kraken2_DB/PlusPFP_20210128/ --output trimmed_reads.collapsed.output.txt --report trimmed_reads.collapsed.report.txt trimmed_reads.collapsed
`

`kraken2 --threads 24 --db /Kraken2_DB/PlusPFP_20210128/ --output trimmed_reads.paired.output.txt --report trimmed_reads.paired.report.txt --paired trimmed_reads.pair1.truncated trimmed_reads.pair2.truncated
`

Step 3: Used Bracken v2.9 (Lu et al. 2017; [https://github.com/jenniferlu717/Bracken/releases](url)) to reassign Kraken2 results to genera from each of the collapsed and uncollapsed PE reads.

`bracken -d /Kraken2_DB/PlusPFP_20210128/ -i trimmed_reads.collapsed.report.txt -o trimmed_reads.collapsed.report.txt.bracken -r 150 -l G -t 10`

`bracken -d /Kraken2_DB/PlusPFP_20210128/ -i trimmed_reads.paired.report.txt -o trimmed_reads.paired.report.txt.bracken -r 150 -l G -t 10`

Step 4: Used an in-house script (developed by Patrick F. Reilly; [TDB](url)) to summarize Bracken results from both collapsed and uncollapsed reads.

`awk -f Bracken_parsing.awk trimmed_reads.collapsed.report.txt.bracken trimmed_reads.paired.report.txt.bracken > trimmed_reads.SUMMARY.report.txt.bracken
`

### 2. Pipeline for the Mapping and Filtering of Ancient DNA PE Reads.

Step 1: Used a YAML file (paleomix.yml) as input and PALEOMIX v1.3.8 (Schubert et al. 2014; [https://github.com/MikkelSchubert/paleomix/releases](url)) for mapping the AVITI PE150 reads to multiple (competitive mapping) or single (non-competitive mapping) references.

`paleomix bam_pipeline run paleomix.yml --jar-root=${EBROOTPICARD}`

Step 2: Used SAMtools v1.21 (Li et al. 2009; [https://github.com/samtools/samtools/releases](url)) to remove reads with mapping scores <30 and then those with mismatch rates ≥0.02 from the resulting BAM file.

`samtools view -b -q 30 reads.bam > reads.mq30.bam`

`samtools view -bh -e '[NM]/length(seq) < 0.02' reads.mq30.bam > reads.mq30.lowMismatch.bam`

Step 3: Used ANGSD v0.941 (Korneliussen et al. 2014; [https://github.com/ANGSD/angsd](url)) to create a consensus sequence based on effective depth.

`angsd -i reads.mq30.lowMismatch.bam -minQ 30 -uniqueOnly 1 -setMinDepth 1 -setMaxDepth -1 -doFasta 3 -doCounts 1 -ref reference.fasta -out reads.mq30.lowMismatch`
