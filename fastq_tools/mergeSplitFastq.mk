# merge split fastqs for workflows like defuse

include modules/Makefile.inc

LOGDIR ?= log/merge_split_fastq.$(NOW)

.SECONDARY:
.DELETE_ON_ERROR: 
.PHONY : fastq

fastq: $(foreach sample,$(SAMPLES),fastq/$(sample).1.fastq.gz.md5 fastq/$(sample).2.fastq.gz.md5)

define merged-fastq
fastq/$1.%.fastq.gz.md5 : $$(foreach split,$2,fastq/$$(split).%.fastq.gz.md5)
	$$(call LSCRIPT,"$$(CHECK_MD5) zcat $$(^M) | gzip > $$(@M) && $$(MD5)")
endef
$(foreach sample,$(SPLIT_SAMPLES),$(eval $(call merged-fastq,$(sample),$(split_lookup.$(sample)))))

%.fastq.gz.md5 : %.fastq.gz
	$(call LSCRIPT,"$(MD5)")
