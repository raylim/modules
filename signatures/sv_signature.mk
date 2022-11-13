include modules/Makefile.inc

LOGDIR ?= log/sv_signature.$(NOW)

MIN_SIZE = 1
MAX_SIZE = 10000000000000000

signature_sv :  $(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).manta.bed) \
		$(foreach pair,$(SAMPLE_PAIRS),sv_signature/$(pair)/$(pair).manta.bedpe)
	   
define signature-sv
sv_signature/$1_$2/$1_$2.manta.bed : vcf/$1_$2.manta_sv.vcf
	$$(call RUN,-c -n 1 -s 4G -m 8G -v $(SURVIVOR_ENV),"set -o pipefail && \
							    SURVIVOR vcftobed \
							    $$(<) \
							    $(MIN_SIZE) \
							    $(MAX_SIZE) \
							    $$(@)")
							    
sv_signature/$1_$2/$1_$2.manta.bedpe : sv_signature/$1_$2/$1_$2.manta.bed
	$$(call RUN,-c -n 1 -s 4G -m 8G,"set -o pipefail && \
					 echo 'chrom1\tstart1\tend1\tchrom2\tstart2\tend2\tsv_id\tpe_support\tstrand1\tstrand2\tsvclass\n' > \
					 $$(@) && \
					 cat $$(<) >> $$(@)")

endef
$(foreach pair,$(SAMPLE_PAIRS),\
		$(eval $(call signature-sv,$(tumor.$(pair)),$(normal.$(pair)))))
	
.DELETE_ON_ERROR:
.SECONDARY:
.PHONY: signature_sv
