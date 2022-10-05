include modules/Makefile.inc
include modules/genome_inc/b37.inc

LOGDIR ?= log/annotate_smry_maf.$(NOW)

annotate_smry_maf : vcf2maf/mutation_summary.vcf \
		    vcf2maf/mutation_summary.maf
		   
VCF2MAF_ENV = $(HOME)/share/usr/env/vcf2maf-1.6.17
VCF2MAF = vcf2maf.pl
		   
vcf2maf/mutation_summary.vcf : summary/tsv/mutation_summary.tsv
	$(call RUN, -c -n 1 -s 8G -m 12G,"set -o pipefail && \
					  $(RSCRIPT) $(SCRIPTS_DIR)/annotateSummaryVcf.R --option 1 --input $(<) --output $(@)")
							
vcf2maf/mutation_summary.maf : vcf2maf/mutation_summary.vcf
	$(call RUN, -c -n 12 -s 2G -m 3G -v $(VCF2MAF_ENV) -w 72:00:00,"set -o pipefail && \
									$(VCF2MAF) \
									--input-vcf $(<) \
									--output-maf $(@) \
									--tmp-dir $(TMPDIR) \
									--tumor-id NA \
									--normal-id NA \
									--vep-path $(VCF2MAF_ENV)/bin \
									--vep-data $(HOME)/share/lib/resource_files/VEP/GRCh37/ \
									--vep-forks 12 \
									--ref-fasta $(HOME)/share/lib/resource_files/VEP/GRCh37/homo_sapiens/99_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz \
									--filter-vcf $(HOME)/share/lib/resource_files/VEP/GRCh37/homo_sapiens/99_GRCh37/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz \
									--species homo_sapiens \
									--ncbi-build GRCh37 \
									--maf-center MSKCC && \
									$(RM) $(TMPDIR)/$(*).vep.vcf")
							
vcf2maf/mutation_summary.txt : vcf2maf/mutation_summary.maf
	$(call RUN, -c -n 1 -s 8G -m 12G,"set -o pipefail && \
					  $(RSCRIPT) $(SCRIPTS_DIR)/annotateSummaryVcf.R --option 2 --input $$(<) --output $$(@)")
							  
..DUMMY := $(shell mkdir -p version; \
	     source $(VCF2MAF_ENV)/bin/activate $(VCF2MAF_ENV) && $(VCF2MAF) --man >> version/annotate_smry_maf.txt)
.DELETE_ON_ERROR:
.SECONDARY: 
.PHONY: annotate_smry_maf
