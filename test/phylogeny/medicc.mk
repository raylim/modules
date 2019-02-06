include modules/Makefile.inc

LOGDIR ?= log/medicc.$(NOW)
PHONY += medicc medicc/mad medicc/mpcf medicc/medicc

medicc : $(foreach set,$(SAMPLE_SETS),medicc/mad/$(set).RData) $(foreach set,$(SAMPLE_SETS),medicc/mpcf/$(set).RData) $(foreach set,$(SAMPLE_SETS),medicc/medicc/$(set)/desc.txt)

define combine-samples
medicc/mad/%.RData : $(wildcard $(foreach pair,$(SAMPLE_PAIRS),facets/cncf/$(pair).Rdata))
	$$(call RUN,-c -s 8G -m 12G -v $(ASCAT_ENV),"$(RSCRIPT) modules/test/phylogeny/combinesamples.R --sample_set $$* --normal_samples '$(NORMAL_SAMPLES)'")

endef
$(foreach set,$(SAMPLE_SETS),\
		$(eval $(call combine-samples,$(set))))

define ascat-mpcf
medicc/mpcf/%.RData : medicc/mad/%.RData
	$$(call RUN,-c -s 8G -m 12G -v $(ASCAT_ENV),"if [ ! -d medicc/ascat ]; then mkdir medicc/ascat; fi && \
												 $(RSCRIPT) modules/test/phylogeny/segmentsamples.R --sample_set $$* --normal_samples '$(NORMAL_SAMPLES)' --gamma '$${mpcf_gamma}' --nlog2 '$${mpcf_nlog2}' --nbaf '$${mpcf_nbaf}'")
endef
$(foreach set,$(SAMPLE_SETS),\
		$(eval $(call ascat-mpcf,$(set))))

define medicc-init
medicc/medicc/%/desc.txt : medicc/mpcf/%.RData
	$$(call RUN,-c -s 8G -m 12G -v $(ASCAT_ENV),"$(RSCRIPT) modules/test/phylogeny/initmedicc.R --sample_set $$*")

endef
$(foreach set,$(SAMPLE_SETS),\
		$(eval $(call medicc-init,$(set))))

#define
# initial run of MEDICC
# 
#endef
#$(foreach set,$(SAMPLE_SETS),\
#		$(eval $(call combine-samples-pdx,$(set))))

#define
# bootstrapped runs of MEDICC
# 
#endef
#$(foreach set,$(SAMPLE_SETS),\
#		$(eval $(call combine-samples-pdx,$(set))))
		
		
.DELETE_ON_ERROR:
.SECONDARY:
.PHONY: $(PHONY)
