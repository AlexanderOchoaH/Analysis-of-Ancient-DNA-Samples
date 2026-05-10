# Analysis of Ancient DNA Samples

### 1. Pipeline for Genus Abundance Estimation from Ancient DNA PE Reads

Step 1: Used AdapterRemoval v2.3.2 (Schubert et al. 2016; [https://github.com/MikkelSchubert/adapterremoval](url)) for the trimming and collapsing of AVITI PE150 reads.

`AdapterRemoval --file1 R1.fastq.gz --file2 R2.fastq.gz --mm 3 --minlength 25 --collapse --trimns --trimqualities --qualitymax 50 --basename trimmed_reads
`

Step 2: Concatenate "collapsed" and "collapsed.truncated" files.

`cat trimmed_reads.collapsed trimmed_reads.collapsed.truncated > trimmed_reads.collapsed.concat
`

Step 3: Used Kraken v2.1.3 (Wood et al. 2019; [https://github.com/DerrickWood/kraken2/releases](url)) for assigning taxonomic levels to both collapsed and uncollapsed PE reads separately.

`kraken2 --threads 24 --db /Kraken2_DB/PlusPFP_20210128/ --output trimmed_reads.collapsed.concat.output.txt --report trimmed_reads.collapsed.concat.report.txt trimmed_reads.collapsed.concat
`

`kraken2 --threads 24 --db /Kraken2_DB/PlusPFP_20210128/ --output trimmed_reads.paired.output.txt --report trimmed_reads.paired.report.txt --paired trimmed_reads.pair1.truncated trimmed_reads.pair2.truncated
`

Step 4: Used Bracken v2.9 (Lu et al. 2017; [https://github.com/jenniferlu717/Bracken/releases](url)) to reassign Kraken2 results to genera from each of the collapsed and uncollapsed PE reads.

`bracken -d /Kraken2_DB/PlusPFP_20210128/ -i trimmed_reads.collapsed.concat.report.txt -o trimmed_reads.collapsed.concat.report.txt.bracken -r 150 -l G -t 10
`

`bracken -d /Kraken2_DB/PlusPFP_20210128/ -i trimmed_reads.paired.report.txt -o trimmed_reads.paired.report.txt.bracken -r 150 -l G -t 10
`


Step 5: Used an in-house script (developed by Patrick F. Reilly; patrick.f.reilly@yale.edu) to summarize Bracken results from both collapsed and uncollapsed reads.

`awk -f Bracken_parsing.awk trimmed_reads.collapsed.concat.report.txt.bracken trimmed_reads.paired.report.txt.bracken > trimmed_reads.SUMMARY.report.txt.bracken
`

### 2. Pipeline for the Mapping and Filtering of Ancient DNA PE Reads

Step 1: Used a YAML file (paleomix.yml) as input and PALEOMIX v1.3.8 (Schubert et al. 2014; [https://github.com/MikkelSchubert/paleomix/releases](url)) for mapping the AVITI PE150 reads to multiple (competitive mapping) or single (non-competitive mapping) references. Line 81 of the YAML file (paleomix.yml) must be changed to "yes" for the removal of PCR duplicates.

`paleomix bam_pipeline run paleomix.yml --jar-root=${EBROOTPICARD}
`

Step 2: Used SAMtools v1.21 (Li et al. 2009; [https://github.com/samtools/samtools/releases](url)) to remove reads with mapping scores <30 and then those with mismatch rates ≥0.02 from the resulting BAM file.

`samtools view -b -q 30 Target_reads.Mapping.bam > Target_reads.Mapping.mq30.bam
`

`samtools view -bh -e '[NM]/length(seq) < 0.02' Target_reads.Mapping.mq30.bam > Target_reads.Mapping.mq30.lowMismatch.bam
`

Step 3: Used ANGSD v0.941 (Korneliussen et al. 2014; [https://github.com/ANGSD/angsd](url)) to create a consensus sequence based on effective depth.

`angsd -i Target_reads.Mapping.mq30.lowMismatch.bam -minQ 30 -uniqueOnly 1 -setMinDepth 1 -setMaxDepth -1 -doFasta 3 -doCounts 1 -ref reference.fasta -out Target_reads.Mapping.mq30.lowMismatch
`

### 3. Detection of Potential Heteroplasmies in Haploid Genomes

Step 1: Used BCFtools v1.21 (Danecek et al. 2021; [(https://github.com/samtools/bcftools/releases)](url)) to call variants in the filtered BAM files.

`bcftools mpileup -f reference.fasta --annotate AD,DP -Ou --bam-list bamlist.txt | bcftools call --skip-variants indels -m --group-samples - -Ov --format-fields gq -o genotypes.vcf
`

Step 2: Used VCFtools v0.1.16 (Danecek et al. 2021; [https://github.com/vcftools/vcftools](url)) to extract polymorphic sites and then mask low-quality/low-depth genotypes at these sites.

`vcftools --vcf genotypes.vcf --min-alleles 2 --minDP 4 --minGQ 18 --recode --out genotypesFiltered
`

Step 3: The resulting genotypesFiltered.recode.vcf file was manually inspected for "heterozygous" genotypes with multiple counts of reference and alternate alleles (Allelic Depth, or AD field).

### References

Danecek, P., Auton, A., Abecasis, G., Albers, C.A., Banks, E., DePristo, M.A., Handsaker, R.E., Lunter, G., Marth, G.T., Sherry, S.T., et al. (2011). The variant call format and VCFtools. Bioinformatics 27, 2156–2158. (doi:10.1093/bioinformatics/btr330)

Danecek, P., Bonfield, J.K., Liddle, J., Marshall, J., Ohan, V., Pollard, M.O., Whitwham, A., Keane, T., McCarthy, S.A., Davies, R.M., et al. (2021). Twelve years of SAMtools and BCFtools. GigaScience 10, giab008. (doi:10.1093/gigascience/giab008)

Korneliussen, T.S., Albrechtsen, A., and Nielsen, R. (2014). ANGSD: Analysis of Next Generation Sequencing Data. (2014). BMC Bioinformatics 15, 356. (doi:10.1186/s12859-014-0356-4)

Li, H., Handsaker, B., Wysoker, A., Fennell, T., Ruan, J., Homer, N., Marth, G., Abecasis, G., Durbin, R., and 1000 Genome Project Data Processing Subgroup. (2009). The Sequence Alignment/Map format and SAMtools. Bioinformatics 25, 2078–2079. (doi:10.1093/bioinformatics/btp352)

Lu, J., Breitwieser, F.P., Thielen, P., and Salzberg, S.L. (2017). Bracken: estimating species abundance in metagenomics data. PeerJ Comput. Sci. 3, e104. (doi:10.7717/peerj-cs.104)

Schubert, M., Ermini, L., Der Sarkissian, C., Jónsson, H., Ginolhac, A., Schaefer, R., Martin, M.D., Fernández, R., Kircher, M., McCue, M., et al. (2014). Characterization of ancient and modern genomes by SNP detection and phylogenomic and metagenomic analysis using PALEOMIX. Nat. Protoc. 9, 1056–1082. (doi:10.1038/nprot.2014.063)

Schubert, M., Lindgreen, S., and Orlando, L. (2016). AdapterRemoval v2: rapid adapter trimming, identification, and read merging. BMC Res. Notes 9, 88. (doi:10.1186/s13104-016-1900-2)

Wood, D.E., Lu, J., and Langmead, B. (2019). Improved metagenomic analysis with Kraken 2. Genome Biol. 20, 257. (doi:10.1186/s13059-019-1891-0)
