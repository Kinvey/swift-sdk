####### Makefile for docs

DOCS= iOS-Getting-Started.html iOS-Developers-Guide.html

#THEME=-a theme=volnitsky
#THEME=-a theme=flask
THEME=

#ASCII= /usr/local/bin/asciidoc -b html5 -a icons -a pygments=  -a linkcss=yes -a stylesdir=css -a scriptsdir=js

## Not the end result, quick for initial integration
ASCII= /usr/local/bin/asciidoc -b html5 -a icons -a pygments= -a toc

%.html: %.txt
	@echo Converting $< to HTML $@
	PATH=${PATH}:/usr/local/bin ${ASCII} ${THEME} $<

%.html: %.asc
	@echo Converting $< to HTML $@
	PATH=${PATH}:/usr/local/bin ${ASCII} ${THEME} $<

	
target: ${DOCS} Makefile
	@echo "Making all docs.."
