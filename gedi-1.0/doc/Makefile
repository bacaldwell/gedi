REPORT=gedi_documentation

all: $(REPORT).pdf

clean:
	rm -f *~ *.dvi *.log *.aux *.toc
	rm -f $(REPORT).ps 

%.dvi: %.tex
	latex $<
	latex $<
%.ps: %.dvi
	dvips -P pdf -G0 -o $@ $<
%.pdf: %.ps
	ps2pdf $<
