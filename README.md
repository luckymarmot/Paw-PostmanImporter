[![Build Status](https://travis-ci.org/luckymarmot/Paw-PostmanImporter.svg?branch=master)](https://travis-ci.org/luckymarmot/Paw-PostmanImporter)

# Postman Importer (Paw Extension)

A [Paw Extension](http://luckymarmot.com/paw/extensions/) to import [Postman Files](https://chrome.google.com/webstore/detail/postman-rest-client/fdmmgilgnpjigdojojpjoooidkmcomcm) into Paw. It can import files with the following extensions:

- `.postman_dump`
- `.postman_environment`
- `.postman-collection`

## Installation

Easily install this Paw Extension: [Install Postman Importer](http://luckymarmot.com/paw/extensions/PostmanImporter)

## How to use?

* In Postman, hit the "Download all data" button
* Save the file
* In Paw, go to File menu, then Import...
* Pick the saved Postman file, and make sure the Format is "Postman Importer"

## Development

### Prerequisites

```shell
nvm install
nvm use
npm install
```

### Build & Install

```shell
make build
```

### Install

```shell
make install
```

## License

This Paw Extension is released under the [MIT License](LICENSE). Feel free to fork, and modify!

Copyright © 2014 Paw Inc.

## Contributors

See [Contributors](https://github.com/luckymarmot/Paw-PostmanImporter/graphs/contributors).
