include modules/Makefile.inc
include modules/genome_inc/b37.inc

LOGDIR ?= log/cnvaccess.$(NOW)
PHONY += cnvkit cnvaccess/cnn cnvaccess/cnn/tumor cnvaccess/cnn/normal cnvaccess/reference cnvaccess/cnr cnvkit/plot cnvkit/plot/log2 cnvkit/plot/segmented cnvkit/plot/bychr cnvaccess/plot/segmented cnvaccess/called cnvaccess/summary

CNV_ACCESS_WORKFLOW += cnvaccess_coverage
CNV_ACCESS_WORKFLOW += cnvaccess_reference
CNV_ACCESS_WORKFLOW += cnvaccess_fix
CNV_ACCESS_WORKFLOW += cnvaccess_plot

cnv_access_workflow : $(CNV_ACCESS_WORKFLOW)

include modules/test/copy_number/cnvaccesscoverage.mk
include modules/test/copy_number/cnvaccessreference.mk
include modules/test/copy_number/cnvaccessfix.mk
include modules/test/copy_number/cnvaccessplot.mk
#include modules/copy_number/cnvkitsegment.mk
#include modules/copy_number/cnvkitsummary.mk

.DELETE_ON_ERROR:
.SECONDARY:
.PHONY: $(PHONY)
