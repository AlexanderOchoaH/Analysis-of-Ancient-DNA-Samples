#!/bin/awk -f
#
BEGIN{
   FS="\t";
   OFS=FS;
   #Print header line:
   print "SampleID", "TaxName", "TaxLevel", "TaxID", "KrakenReadPairs", "KrakenAbundance", "BrackenEstReadPairs", "BrackenAbundance";
   #Set the array iteration order:
   PROCINFO["sorted_in"]="@val_num_desc";
}
FNR==1{
   #Parse the sample ID and the merged vs. unmerged status from FILENAME:
   fn=FILENAME;
   sub(".*/", "", fn);
   n_fnparts=split(fn, fnparts, ".");
   #Output the per-taxon read pair counts for the previous sample:
   #No need to check for zero in denom, as k2rp should be empty if total is 0
   if (FNR<NR && id != fnparts[1]) {
      for (rpkey in k2rp) {
         split(rpkey, keyparts, SUBSEP);
         print id, keyparts[1], keyparts[2], keyparts[3], k2rp[rpkey], k2rp[rpkey]/totalk2rp, brp[rpkey], brp[rpkey]/totalbrp;
      };
      #Reset the per-taxon read pair counts after outputting:
      delete k2rp;
      delete brp;
      #Reset the total read pair counts:
      totalk2rp=0;
      totalbrp=0;
   };
   id=fnparts[1];
   merged=fnparts[2];
   #Unmerged read pairs are effectively double-counted relative to merged:
   if (merged == "paired") {
      rpcoef=0.5;
   } else {
      rpcoef=1.0;
   };
   #Grab the column names so we can refer to the columns that way:
   delete cols;
   for (i=1; i<=NF; i++) {
      cols[$i]=i;
   };
}
FNR>1{
   #Keep track of the read totals so we can use it as denom for abundances:
   totalk2rp+=$cols["kraken_assigned_reads"]*rpcoef;
   totalbrp+=$cols["new_est_reads"]*rpcoef;
   #Store the per-taxon counts, accounting for merged vs. unmerged:
   rpkey=$cols["name"] SUBSEP $cols["taxonomy_lvl"] SUBSEP $cols["taxonomy_id"];
   k2rp[rpkey]+=$cols["kraken_assigned_reads"]*rpcoef;
   brp[rpkey]+=$cols["new_est_reads"]*rpcoef;
}
END{
   #Output the read pair counts and abundances for each taxon:
   #No need to check for zero in denom, as k2rp should be empty if total is 0
   for (rpkey in k2rp) {
      split(rpkey, keyparts, SUBSEP);
      print id, keyparts[1], keyparts[2], keyparts[3], k2rp[rpkey], k2rp[rpkey]/totalk2rp, brp[rpkey], brp[rpkey]/totalbrp;
   };
}
