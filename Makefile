all: clean archive

clean:
	rm -r dist

archive:
	mkdir -p dist/GGTyres
	cp GGTyres.lua dist/GGTyres/
	cp icon.png dist/GGTyres/
	cp manifest.ini dist/GGTyres/
	cp LICENSE dist/GGTyres/
	cp -r gg dist/GGTyres/
	cd dist && zip -r GGTyres.zip GGTyres
