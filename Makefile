#################################################################################
#                OCamlrss                                                       #
#                                                                               #
#    Copyright (C) 2004-2012 Institut National de Recherche en Informatique     #
#    et en Automatique. All rights reserved.                                    #
#                                                                               #
#    This program is free software; you can redistribute it and/or modify       #
#    it under the terms of the GNU Library General Public License version       #
#    2.1 as published by the Free Software Foundation.                          #
#                                                                               #
#    This program is distributed in the hope that it will be useful,            #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#    GNU Library General Public License for more details.                       #
#                                                                               #
#    You should have received a copy of the GNU Library General Public          #
#    License along with this program; if not, write to the Free Software        #
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   #
#    02111-1307  USA                                                            #
#                                                                               #
#    Contact: Maxence.Guesdon@inria.fr                                          #
#                                                                               #
#                                                                               #
#################################################################################

#
PACKAGES=xmlm

OF_FLAGS=-package $(PACKAGES) -annot
OCAMLFIND=ocamlfind
OCAMLC=$(OCAMLFIND) ocamlc $(OF_FLAGS)
OCAMLOPT=$(OCAMLFIND) ocamlopt $(OF_FLAGS)
OCAMLDOC=$(OCAMLFIND) ocamldoc $(OF_FLAGS)

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

