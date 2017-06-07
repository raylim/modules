include modules/Makefile.inc

LOGDIR ?= log/msisensor.$(NOW)

MSISENSOR ?= $(HOME)/share/usr/bin/msisensor
MSISENSOR_OPTS ?= -d $(REF_MSI) $(if $(TARGETS_FILE),-e $(TARGETS_FILE))

PHONY += msisensor

.DELETE_ON_ERROR:
.SECONDARY: 
.PHONY : $(PHONY)

msisensor: msisensor/msi.tsv

define msisensor-tumor-normal
msisensor/$1_$2.msi : bam/$1.bam bam/$2.bam bam/$1.bam.bai bam/$2.bam.bai
	$$(call LSCRIPT_CHECK_PARALLEL_MEM,8,1G,1.2G,"$$(MSISENSOR) msi $$(MSISENSOR_OPTS) -n $$(<<) -t $$< -b 8 -o $$@")
endef
$(foreach pair,$(SAMPLE_PAIRS),$(eval $(call msisensor-tumor-normal,$(tumor.$(pair)),$(normal.$(pair)))))

msisensor/msi.tsv : $(foreach pair,$(SAMPLE_PAIRS),msisensor/$(pair).msi)
	$(INIT) (head -1 $< | sed 's/^/sample\t/'; for x in $^; do sed "1d; s/^/$$(basename $$x)\t/" $$x; done | sed 's/_.*msi//' ) > $@

bam/%.ds.bam : metrics/hs_metrics.tsv bam/%.bam
	   $(call LSCRIPT_MEM,4G,6G,\
		   "ds=\`py 'round(500 / pandas.read_table(\"$<\", index_col=0).ix[\"$*\", \"MEAN_TARGET_COVERAGE\"], 2)'\`; \
		   if [ \$$(echo \"\$$ds >= 1\" | bc) -eq 1 ]; then ln -s \$$(readlink -f $(<<)) $@; else \
		   samtools view -hb -s \$$ds $(<<) > $@; fi")

include modules/bam_tools/processBam.mk
