identifier=com.luckymarmot.PawExtensions.PostmanImporter
extensions_dir=$(HOME)/Library/Containers/com.luckymarmot.Paw/Data/Library/Application Support/com.luckymarmot.Paw/Extensions/

build:
	yarn build
	cp README.md LICENSE ./build/$(identifier)/

clean:
	rm -Rf ./build/

transfer:
	mkdir -p "$(extensions_dir)$(identifier)/"
	cp -r ./build/$(identifier)/* "$(extensions_dir)$(identifier)/"

install: clean build transfer

test:
	npm test

archive: build
	cd ./build/; zip -r PostmanImporter.zip "$(identifier)/"
