include modules/Makefile.inc
include modules/variant_callers/gatk.inc

LOGDIR = log/cluster_samples.$(NOW)

VPATH ?= bam
ifeq ($(EXOME),true)
DBSNP_SUBSET ?= $(HOME)/share/reference/dbsnp_137_exome.bed
else
DBSNP_SUBSET = $(HOME)/share/reference/dbsnp_tseq_intersect.bed
endif

CLUSTER_VCF = $(RSCRIPT) modules/contamination/clusterSampleVcf.R

snp_cluster : $(foreach sample,$(SAMPLES),snp_vcf/$(sample).snps.vcf) \
	      snp_vcf/snps.vcf \
	      snp_vcf/snps_ft.vcf \
	      snp_vcf/snps_filtered.clust.png

snp_vcf/%.snps.vcf : bam/%.bam 
	$(call RUN,-n 4 -s 2.5G -m 3G,"set -o pipefail && \
				       $(call GATK_MEM,8G) \
				       -T UnifiedGenotyper \
				       -nt 4 \
				       -R $(REF_FASTA) \
				       --dbsnp $(DBSNP) \
				       $(foreach bam,$(filter %.bam,$^),-I $(bam) ) \
				       -L $(DBSNP_SUBSET) \
				       -o $@ \
				       --output_mode EMIT_ALL_SITES")


snp_vcf/snps.vcf : $(foreach sample,$(SAMPLES),snp_vcf/$(sample).snps.vcf)
	$(call RUN,-s 16G -m 20G,"set -o pipefail && \
				  $(call GATK_MEM,14G) -T CombineVariants \
				  $(foreach vcf,$^,--variant $(vcf) ) \
				  -o $@ \
				  --genotypemergeoption UNSORTED \
				  -R $(REF_FASTA)")

snp_vcf/snps_ft.vcf : snp_vcf/snps.vcf
	$(INIT) grep '^#' $< > $@ && grep -e '0/1' -e '1/1' $< >> $@

snp_vcf/%.clust.png : snp_vcf/%.vcf
	$(INIT) $(CLUSTER_VCF) --outPrefix snp_vcf/$* $<
	
..DUMMY := $(shell mkdir -p version; \
             echo "GATK" > version/cluster_samples.txt;)
.SECONDARY:
.DELETE_ON_ERROR:
.PHONY : snp_cluster

include modules/vcf_tools/vcftools.mk
