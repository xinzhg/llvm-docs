##===- docs/Makefile ---------------------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LEVEL      := ..
DIRS       :=

ifdef BUILD_FOR_WEBSITE
PROJ_OBJ_DIR = .
DOXYGEN = doxygen

$(PROJ_OBJ_DIR)/doxygen.cfg: doxygen.cfg.in
	cat $< | sed \
	  -e 's/@DOT@/dot/g' \
	  -e 's/@PACKAGE_VERSION@/mainline/' \
	  -e 's/@abs_top_builddir@/../g' \
	  -e 's/@abs_top_srcdir@/../g' \
	  -e 's/@enable_external_search@/NO/g' \
	  -e 's/@enable_searchengine@/NO/g' \
	  -e 's/@enable_server_based_search@/NO/g' \
	  -e 's/@extra_search_mappings@//g' \
	  -e 's/@llvm_doxygen_generate_qhp@//g' \
	  -e 's/@llvm_doxygen_qch_filename@//g' \
	  -e 's/@llvm_doxygen_qhelpgenerator_path@//g' \
	  -e 's/@llvm_doxygen_qhp_cust_filter_attrs@//g' \
	  -e 's/@llvm_doxygen_qhp_cust_filter_name@//g' \
	  -e 's/@llvm_doxygen_qhp_namespace@//g' \
	  -e 's/@searchengine_url@//g' \
	  > $@
endif

include $(LEVEL)/Makefile.common

HTML       := $(wildcard $(PROJ_SRC_DIR)/*.html) \
              $(wildcard $(PROJ_SRC_DIR)/*.css)
DOXYFILES  := doxygen.cfg.in doxygen.intro

.PHONY: install-html install-doxygen doxygen install-ocamldoc ocamldoc generated

install_targets := install-html
ifeq ($(ENABLE_DOXYGEN),1)
install_targets += install-doxygen
endif
ifdef OCAMLFIND
ifneq (,$(filter ocaml,$(BINDINGS_TO_BUILD)))
install_targets += install-ocamldoc
endif
endif
install-local:: $(install_targets)

generated_targets := doxygen
ifdef OCAMLFIND
generated_targets += ocamldoc
endif

# Live documentation is generated for the web site using this target:
# 'make generated BUILD_FOR_WEBSITE=1'
generated:: $(generated_targets)

install-html: $(PROJ_OBJ_DIR)/html.tar.gz
	$(Echo) Installing HTML documentation
	$(Verb) $(MKDIR) $(DESTDIR)$(PROJ_docsdir)/html
	$(Verb) $(DataInstall) $(HTML) $(DESTDIR)$(PROJ_docsdir)/html
	$(Verb) $(DataInstall) $(PROJ_OBJ_DIR)/html.tar.gz $(DESTDIR)$(PROJ_docsdir)

$(PROJ_OBJ_DIR)/html.tar.gz: $(HTML)
	$(Echo) Packaging HTML documentation
	$(Verb) $(RM) -rf $@ $(PROJ_OBJ_DIR)/html.tar
	$(Verb) cd $(PROJ_SRC_DIR) && \
	  $(TAR) cf $(PROJ_OBJ_DIR)/html.tar *.html
	$(Verb) $(GZIPBIN) $(PROJ_OBJ_DIR)/html.tar

install-doxygen: doxygen
	$(Echo) Installing doxygen documentation
	$(Verb) $(DataInstall) $(PROJ_OBJ_DIR)/doxygen.tar.gz $(DESTDIR)$(PROJ_docsdir)
	$(Verb) cd $(PROJ_OBJ_DIR)/doxygen/html && \
	  for DIR in $$($(FIND) . -type d); do \
	    DESTSUB="$(DESTDIR)$(PROJ_docsdir)/html/doxygen/$$(echo $$DIR | cut -c 3-)"; \
	    $(MKDIR) $$DESTSUB && \
	    $(FIND) $$DIR -maxdepth 1 -type f -exec $(DataInstall) {} $$DESTSUB \; ; \
	    if [ $$? != 0 ]; then exit 1; fi \
	  done

doxygen: regendoc $(PROJ_OBJ_DIR)/doxygen.tar.gz

regendoc:
	$(Echo) Building doxygen documentation
	$(Verb) $(RM) -rf $(PROJ_OBJ_DIR)/doxygen
	$(Verb) $(DOXYGEN) $(PROJ_OBJ_DIR)/doxygen.cfg

$(PROJ_OBJ_DIR)/doxygen.tar.gz: $(DOXYFILES) $(PROJ_OBJ_DIR)/doxygen.cfg
	$(Echo) Packaging doxygen documentation
	$(Verb) $(RM) -rf $@ $(PROJ_OBJ_DIR)/doxygen.tar
	$(Verb) $(TAR) cf $(PROJ_OBJ_DIR)/doxygen.tar doxygen
	$(Verb) $(GZIPBIN) $(PROJ_OBJ_DIR)/doxygen.tar
	$(Verb) $(CP) $(PROJ_OBJ_DIR)/doxygen.tar.gz $(PROJ_OBJ_DIR)/doxygen/html/

userloc: $(LLVM_SRC_ROOT)/docs/userloc.html

$(LLVM_SRC_ROOT)/docs/userloc.html:
	$(Echo) Making User LOC Table
	$(Verb) cd $(LLVM_SRC_ROOT) ; ./utils/userloc.pl -details -recurse \
	  -html lib include tools runtime utils examples autoconf test > docs/userloc.html

install-ocamldoc: ocamldoc
	$(Echo) Installing ocamldoc documentation
	$(Verb) $(MKDIR) $(DESTDIR)$(PROJ_docsdir)/ocamldoc/html
	$(Verb) $(DataInstall) $(PROJ_OBJ_DIR)/ocamldoc.tar.gz $(DESTDIR)$(PROJ_docsdir)
	$(Verb) cd $(PROJ_OBJ_DIR)/ocamldoc && \
	  $(FIND) . -type f -exec \
	    $(DataInstall) {} $(DESTDIR)$(PROJ_docsdir)/ocamldoc/html \;

ocamldoc: regen-ocamldoc
	$(Echo) Packaging ocamldoc documentation
	$(Verb) $(RM) -rf $(PROJ_OBJ_DIR)/ocamldoc.tar*
	$(Verb) $(TAR) cf $(PROJ_OBJ_DIR)/ocamldoc.tar ocamldoc
	$(Verb) $(GZIPBIN) $(PROJ_OBJ_DIR)/ocamldoc.tar
	$(Verb) $(CP) $(PROJ_OBJ_DIR)/ocamldoc.tar.gz $(PROJ_OBJ_DIR)/ocamldoc/html/

regen-ocamldoc:
	$(Echo) Building ocamldoc documentation
	$(Verb) $(RM) -rf $(PROJ_OBJ_DIR)/ocamldoc
	$(Verb) $(MAKE) -C $(LEVEL)/bindings/ocaml ocamldoc
	$(Verb) $(MKDIR) $(PROJ_OBJ_DIR)/ocamldoc/html
	$(Verb) \
		$(OCAMLFIND) ocamldoc -d $(PROJ_OBJ_DIR)/ocamldoc/html -sort -colorize-code -html \
		`$(FIND) $(LEVEL)/bindings/ocaml -name "*.odoc" \
		         -path "*/$(BuildMode)/*.odoc" -exec echo -load '{}' ';'`

uninstall-local::
	$(Echo) Uninstalling Documentation
	$(Verb) $(RM) -rf $(DESTDIR)$(PROJ_docsdir)
