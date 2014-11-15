var PostmanImporter = function() {
	
	this.importString = function(context, string) {
		
		// Parse JSON collection
		var postmanCollection = JSON.parse(string);
		
		// Check Postman data
		if (!postmanCollection || !postmanCollection["requests"]) {
			throw new Error("Invalid Postman data");
		}
		
		// Build Postman request dictionary (by id)
		var postmanRequestsById = new Object();
		for (var i in postmanCollection["requests"]) {
			var postmanRequest = postmanCollection["requests"][i];
			postmanRequestsById[postmanRequest["id"]] = postmanRequest;
		}
		
		// Function to create Paw requests
		var createPawRequest = function(postmanRequestId) {
			
			// Get Postman request
			var postmanRequest = postmanRequestsById[postmanRequestId]
			
			// Create Paw request
			var pawRequest = context.createRequest(postmanRequest["name"], postmanRequest["method"], postmanRequest["url"]);
			
			// Add Headers
			// Postman stores headers like HTTP headers, separated by \n
			var postmanHeaders = postmanRequest["headers"].split("\n");
			for (var i in postmanHeaders) {
				var headerLine = postmanHeaders[i];
				var match = headerLine.match(/^([^\s\:]*)\s*\:\s*(.*)$/);
				if (match) {
					pawRequest.setHeader(match[1], match[2]);
				}
			}
			
			// Set raw body
			if (postmanRequest["dataMode"] == "raw") {
				var contentType = pawRequest.getHeaderByName("Content-Type");
				var foundBody = false;
				
				// If the Content-Type contains "json" make it a JSON body
				if (contentType && contentType.indexOf("json") >= 0) {
					var jsonObject = JSON.parse(postmanRequest["rawModeData"]);
					if (jsonObject) {
						pawRequest.jsonBody = jsonObject;
						foundBody = true;
					}
				}
				
				if (!foundBody) {
					pawRequest.body = postmanRequest["rawModeData"];
				}
			}
			
			// Set Form URL-Encoded body
			else if (postmanRequest["dataMode"] == "urlencoded") {
				var postmanBodyData = postmanRequest["data"];
				var bodyObject = new Object();
				for (var i in postmanBodyData) {
					/* Note: it sounds like all data fields are "text" type
					 when in "urlencoded" data mode. */
					if (postmanBodyData[i]["type"] == "text") {
						bodyObject[postmanBodyData[i]["key"]] = postmanBodyData[i]["value"];
					}
				}
				pawRequest.urlEncodedBody = bodyObject;
			}
			
			// Set Multipart body
			else if (postmanRequest["dataMode"] == "params") {
				var postmanBodyData = postmanRequest["data"];
				var bodyObject = new Object();
				for (var i in postmanBodyData) {
					/* Note: due to Apple Sandbox limitations, we cannot import
					 "file" type items */
					if (postmanBodyData[i]["type"] == "text") {
						bodyObject[postmanBodyData[i]["key"]] = postmanBodyData[i]["value"];
					}
				}
				pawRequest.multipartBody = bodyObject;
			}
			
			console.log("Created Request: " + postmanRequest["name"]);
			
			return pawRequest;
		};
		
		// Create a Paw Group
		var pawRootGroup = context.createRequestGroup(postmanCollection["name"]);
		
		// Add Postman folders
		if (postmanCollection["folders"]) {
			for (var i in postmanCollection["folders"]) {
				var postmanFolder = postmanCollection["folders"][i];
				
				console.log(postmanFolder);
				
				// Create Paw group
				var pawGroup = context.createRequestGroup(postmanFolder["name"]);
				
				console.log("Created Group: " + postmanFolder["name"]);
				
				// Add group to root
				pawRootGroup.appendChild(pawGroup);
				
				// Iterate on requests in group
				if (postmanFolder["order"]) {
					for (var j in postmanFolder["order"]) {
						var postmanRequestId = postmanFolder["order"][j];
						
						// Create a Paw request
						var pawRequest = createPawRequest(postmanRequestId);
						
						// Add request to parent group
						pawGroup.appendChild(pawRequest);
					}
				}
			}
		}
		
		// Add Postman requests in root
		if (postmanCollection["order"]) {
			for (var i in postmanCollection["order"]) {
				var postmanRequestId = postmanCollection["order"][i];
				
				// Create a Paw request
				var pawRequest = createPawRequest(postmanRequestId);
				
				// Add request to root group
				pawRootGroup.appendChild(pawRequest);
			}
		}
		
		return true;
	};
}

PostmanImporter.identifier = "com.luckymarmot.PawExtensions.PostmanImporter";
PostmanImporter.title = "Postman Importer";

registerImporter(PostmanImporter);
