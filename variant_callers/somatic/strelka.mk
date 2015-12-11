# Run strelka on tumour-normal matched pairs

include modules/Makefile.inc
include modules/variant_callers/gatk.inc
include modules/variant_callers/somatic/strelka.inc
include modules/variant_callers/somatic/somaticVariantCaller.inc
include modules/mut_sigs/mutSigReport.mk
##### DEFAULTS ######


LOGDIR = log/strelka.$(NOW)
PHONY += strelka_all strelka_vcfs strelka_tables

strelka_all : strelka_vcfs strelka_tables
	
VARIANT_TYPES := strelka_snps strelka_indels
strelka_vcfs : $(foreach type,$(VARIANT_TYPES),$(call SOMATIC_VCFS,$(type)))
strelka_tables : $(foreach type,$(VARIANT_TYPES),$(call SOMATIC_TABLES,$(type)))
$(eval $(call mutsig-report-name-vcfs,strelka_snps,$(call SOMATIC_VCFS,strelka_snps)))

define strelka-tumor-normal
strelka/$1_$2/Makefile : bam/$1.bam bam/$2.bam
	$$(INIT) rm -rf $$(@D) && $$(CONFIGURE_STRELKA) --tumor=$$< --normal=$$(<<) --ref=$$(REF_FASTA) --config=$$(STRELKA_CONFIG) --output-dir=$$(@D) &> $$(LOG)

#$$(INIT) qmake -inherit -q jrf.q -- -j 20 -C $$< > $$(LOG) && touch $$@
strelka/$1_$2/task.complete : strelka/$1_$2/Makefile
	$$(call LSCRIPT_NAMED_PARALLEL_MEM,$1_$2.strelka,12,1G,1.5G,"make -j 12 -C $$(<D)")

vcf/$1_$2.%.vcf : strelka/vcf/$1_$2.%.vcf
	$$(INIT) perl -ne 'if (/^#CHROM/) { s/NORMAL/$2/; s/TUMOR/$1/; } print;' $$< > $$@ && $$(RM) $$<

strelka/vcf/$1_$2.strelka_snps.vcf : strelka/$1_$2/task.complete
	$$(INIT) cp -f strelka/$1_$2/results/all.somatic.snvs.vcf $$@

strelka/vcf/$1_$2.strelka_indels.vcf : strelka/$1_$2/task.complete
	$$(INIT) cp -f strelka/$1_$2/results/all.somatic.indels.vcf $$@

endef
$(foreach pair,$(SAMPLE_PAIRS),$(eval $(call strelka-tumor-normal,$(tumor.$(pair)),$(normal.$(pair)))))

include modules/vcf_tools/vcftools.mk

.DELETE_ON_ERROR:
.SECONDARY:
.PHONY: $(PHONY)

