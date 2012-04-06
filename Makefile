#
PACKAGES=xmlm,unix

OF_FLAGS=-package $(PACKAGES)
OCAMLFIND=ocamlfind
OCAML_COMPFLAGS= -annot
OCAMLC=$(OCAMLFIND) ocamlc $(OF_FLAGS) $(OCAML_COMPFLAGS)
OCAMLOPT=$(OCAMLFIND) ocamlopt $(OF_FLAGS) $(OCAML_COMFLAGS)
OCAMLDOC=$(OCAMLFIND) ocamldoc $(OF_FLAGS)
OCAMLDEP=ocamldep

all: byte opt
byte: rss.cma
opt: rss.cmxa

CMOFILES= \
	rss_date.cmo \
	rss_types.cmo \
	rss_io.cmo \
	rss.cmo

CMXFILES=$(CMOFILES:.cmo=.cmx)
CMIFILES=$(CMOFILES:.cmo=.cmi)

rss.cma: $(CMIFILES) $(CMOFILES)
	$(OCAMLC) -o $@ -a $(CMOFILES)

rss.cmxa: $(CMIFILES) $(CMXFILES)
	$(OCAMLOPT) -o $@ -a $(CMXFILES)

.PHONY: doc depend

doc:
	mkdir -p html
	$(OCAMLDOC) -d html -html rss.mli

.depend depend:
	$(OCAMLDEP) rss*.ml rss*.mli > .depend

rsstest: rss.cmxa rsstest.ml
	$(OCAMLOPT) -linkpkg -o $@ $^

test: rsstest
	@./rsstest test.rss > t.rss
	@./rsstest t.rss > t2.rss
	@((diff t.rss t2.rss && echo OK) || echo "t.rss and t2.rss differ")

# installation :
################
install: byte opt
	$(OCAMLFIND) install rss META LICENSE rss.cmi rss.cma rss.cmxa rss.a

uninstall:
	ocamlfind remove rss

# Cleaning :
############
clean:
	rm -f *.cm* *.a *.annot *.o

# headers :
###########
HEADFILES=Makefile *.ml *.mli
.PHONY: headers noheaders
headers:
	headache -h header -c .headache_config $(HEADFILES)

noheaders:
	headache -r -c .headache_config $(HEADFILES)

# generic rules :
#################
.SUFFIXES: .mli .ml .cmi .cmo .cmx .mll .mly .sch .html .mail

%.cmi:%.mli
	$(OCAMLC) -c $<

%.cmo:%.ml
	$(OCAMLC) -c $<

%.cmi %.cmo:%.ml
	$(OCAMLC) -c $<

%.cmx %.o:%.ml
	$(OCAMLOPT) -c $<

include .depend

