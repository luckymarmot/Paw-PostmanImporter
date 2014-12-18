[![Build Status](https://travis-ci.org/luckymarmot/Paw-PostmanImporter.svg?branch=master)](https://travis-ci.org/luckymarmot/Paw-PostmanImporter)

# Postman Importer (Paw Extension)

A [Paw Extension](http://luckymarmot.com/paw/extensions/) to import [Postman Collections](https://chrome.google.com/webstore/detail/postman-rest-client/fdmmgilgnpjigdojojpjoooidkmcomcm) into Paw. You can also import Postman Environments with [Postman Environment Importer](https://github.com/luckymarmot/Paw-PostmanEnvironmentImporter).

## Installation

Easily install this Paw Extension: [Install Postman Importer](http://luckymarmot.com/paw/extensions/PostmanImporter)

## How to use?

* In Postman, hit the "Download all data" button
* Save the file
* In Paw, go to File menu, then Import...
* Pick the saved Postman file, and make sure the Format is "Postman Importer"

## Development

### Build & Install

```shell
npm install
cake build
cake install
```

### Watch

During development, watch for changes:

```shell
cake watch
```

## License

This Paw Extension is released under the [MIT License](LICENSE). Feel free to fork, and modify!

Copyright © 2014 Paw Inc.

## Contributors

See [Contributors](https://github.com/luckymarmot/Paw-PostmanImporter/graphs/contributors).
