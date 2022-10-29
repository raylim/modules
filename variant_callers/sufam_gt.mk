include modules/Makefile.inc

LOGDIR ?= log/sufam_gt.$(NOW)

SUFAM_ENV = $(HOME)/share/usr/anaconda-envs/sufam-dev
SUFAM_OPTS = --mpileup-parameters='-A -q 15 -Q 15 -d 15000'

sufam_gt : $(foreach set,$(SAMPLE_SETS),sufam/$(set).vcf)
	   $(foreach sample,$(SAMPLES),sufam/$(sample).txt)

define tsv-2-vcf
sufam/$1.vcf : summary/tsv/all.tsv
	$$(call RUN,-c -n 1 -s 4G -m 8G,"set -o pipefail && \
					 $(RSCRIPT) $(SCRIPTS_DIR)/sufam_gt.R \
					 --option 1 \
					 --sample_set $1 \
					 --normal_samples '$(NORMAL_SAMPLES)' \
					 --input_file $$(<) \
					 --output_file $$(@)")

endef
$(foreach set,$(SAMPLE_SETS),\
		$(eval $(call tsv-2-vcf,$(set))))

define sufam-genotype
sufam/$1.txt : $$(foreach sample,$2,$$(word 1, $$(set.$$(sample))))
	$$(call RUN,-c -n 1 -s 4G -m 8G,"set -o pipefail && \
					 $(RSCRIPT) $(SCRIPTS_DIR)/sufam_gt.R \
					 --option 1 \
					 --sample_set $1 \
					 --normal_samples '$(NORMAL_SAMPLES)' \
					 --input_file $$(<) \
					 --output_file $$(@)")

endef
$(foreach sample,$(SAMPLES),\
		$(eval $(call sufam-genotype,$(sample),$(set.$(sample)))))



.DELETE_ON_ERROR:
.SECONDARY:
.PHONY:
