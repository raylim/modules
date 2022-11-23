include modules/Makefile.inc

LOGDIR ?= log/sv_signature.$(NOW)

MIN_SIZE = 1
MAX_SIZE = 10000000000000000
FRAGILE_SITES = /data/reis-filho/lib/resource_files/viola/annotation/fragile_site.b37.bed
REPLICATION_TIMING = /data/reis-filho/lib/resource_files/viola/annotation/replication_timing.b37.bedgraph
SV_DEFINITIONS = /data/reis-filho/lib/resource_files/viola/definitions/sv_class_default.txt
CLUSTER_SV = $(VIOLA_ENV)/opt/ClusterSV/R
CHROM_SIZES = $(VIOLA_ENV)/opt/ClusterSV/references/hg19.chrom_sizes
CENTROMERE_TELOMERE = $(VIOLA_ENV)/opt/ClusterSV/references/hg19_centromere_and_telomere_coords.txt

signature_sv :  $(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).merged.bed) \
		$(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).merged.bedpe) \
		$(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).merged_exposures.txt) \
		$(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).merged.sv_clusters_and_footprints.tsv) \
		$(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).merged.sv_clusters_and_footprints.bedpe) \
		$(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).merged.sv_clusters_and_footprints.txt) \
		$(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).merged.sv_clusters_and_footprints_exposures.txt) \
		sv_signature/summary.txt
		
define signature-sv
sv_signature/$1_$2/$1_$2.merged.bed : vcf/$1_$2.merged_sv.vcf
	$$(call RUN,-c -n 1 -s 4G -m 8G -v $(SURVIVOR_ENV),"set -o pipefail && \
							    SURVIVOR vcftobed \
							    $$(<) \
							    $(MIN_SIZE) \
							    $(MAX_SIZE) \
							    $$(@)")
							    
sv_signature/$1_$2/$1_$2.merged.bedpe : sv_signature/$1_$2/$1_$2.merged.bed
	$$(call RUN,-c -n 1 -s 4G -m 8G,"set -o pipefail && \
					 echo \"chrom1	start1	end1	chrom2	start2	end2	sv_id	pe_support	strand1	strand2	svclass\" > \
					 $$(@) && \
					 cat $$(<) >> $$(@)")
					 
sv_signature/$1_$2/$1_$2.merged_exposures.txt : sv_signature/$1_$2/$1_$2.merged.bedpe
	$$(call RUN,-c -n 4 -s 2G -m 4G -v $(SIGNATURE_TOOLS_ENV),"set -o pipefail && \
								  $(RSCRIPT) $(SCRIPTS_DIR)/sv_signature.R \
								  --option 1 \
								  --sample_name $1_$2 \
								  --input_file $$(<) \
								  --output_file sv_signature/$1_$2/$1_$2.merged")

sv_signature/$1_$2/$1_$2.merged.sv_clusters_and_footprints.tsv : sv_signature/$1_$2/$1_$2.merged.bedpe
	$$(call RUN,-c -n 4 -s 2G -m 4G -v $(VIOLA_ENV),"set -o pipefail && \
							 $(RSCRIPT) $(CLUSTER_SV)/run_cluster_sv.R \
							 -bedpe $$(<) \
							 -chr $(CHROM_SIZES) \
							 -cen_telo $(CENTROMERE_TELOMERE) \
							 -out sv_signature/$1_$2/$1_$2.merged \
							 -n 4 \
							 > sv_signature/$1_$2/$1_$2.merged.log")
							 
sv_signature/$1_$2/$1_$2.merged.sv_clusters_and_footprints.bedpe : sv_signature/$1_$2/$1_$2.merged.bedpe sv_signature/$1_$2/$1_$2.merged.sv_clusters_and_footprints.tsv
	$$(call RUN,-c -n 1 -s 4G -m 8G -v $(SIGNATURE_TOOLS_ENV),"set -o pipefail && \
								   $(RSCRIPT) $(SCRIPTS_DIR)/sv_signature.R \
								   --option 2 \
								   --sample_name $1_$2 \
								   --output_file $$(@)")

sv_signature/$1_$2/$1_$2.merged.sv_clusters_and_footprints.txt : sv_signature/$1_$2/$1_$2.merged.sv_clusters_and_footprints.bedpe
	$$(call RUN,-c -n 1 -s 4G -m 8G -v $(VIOLA_ENV),"set -o pipefail && \
							 python $(SCRIPTS_DIR)/sv_signature.py \
							 --bedpe_infile $$(<) \
							 --fragile_bed $(FRAGILE_SITES) \
							 --timing_bedgraph $(REPLICATION_TIMING) \
							 --sv_definitions $(SV_DEFINITIONS) \
							 --text_outfile $$(@)")
							 
sv_signature/$1_$2/$1_$2.merged.sv_clusters_and_footprints_exposures.txt : sv_signature/$1_$2/$1_$2.merged.sv_clusters_and_footprints.txt
	$$(call RUN,-c -n 4 -s 2G -m 4G -v $(SIGNATURE_TOOLS_ENV),"set -o pipefail && \
								  $(RSCRIPT) $(SCRIPTS_DIR)/sv_signature.R \
								  --option 3 \
								  --sample_name $1_$2 \
								  --input_file $$(<) \
								  --output_file sv_signature/$1_$2/$1_$2.merged.sv_clusters_and_footprints")

endef
$(foreach pair,$(SAMPLE_PAIRS),\
		$(eval $(call signature-sv,$(tumor.$(pair)),$(normal.$(pair)))))
		
sv_signature/summary.txt : $(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).merged.sv_clusters_and_footprints_exposures.txt) $(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).merged_exposures.txt)
	$(call RUN, -c -n 1 -s 8G -m 12G -v $(SIGNATURE_TOOLS_ENV),"set -o pipefail && \
					  			    $(RSCRIPT) $(SCRIPTS_DIR)/sv_signature.R --option 4 --sample_name '$(SAMPLE_PAIRS)' --output_file $(@)")


..DUMMY := $(shell mkdir -p version; \
	     $(SURVIVOR_ENV)/bin/SURVIVOR --version &> version/sv_signature.txt;)
.DELETE_ON_ERROR:
.SECONDARY:
.PHONY: signature_sv
