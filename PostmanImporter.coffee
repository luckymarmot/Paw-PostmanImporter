PostmanImporter = ->

    # Create Paw requests from a Postman Request (object)
    @createPawRequest = (context, postmanRequestsById, postmanRequestId) ->

        # Get Request
        postmanRequest = postmanRequestsById[postmanRequestId]

        if not postmanRequest
            console.log "Corrupted Postman file, no request found for ID: #{ postmanRequestId }"
            return null

        # Create Paw request
        pawRequest = context.createRequest postmanRequest["name"], postmanRequest["method"], postmanRequest["url"]

        # Add Headers
        # Postman stores headers like HTTP headers, separated by \n
        postmanHeaders = postmanRequest["headers"].split "\n"
        for i in postmanHeaders
            headerLine = postmanHeaders[i];
            match = headerLine.match /^([^\s\:]*)\s*\:\s*(.*)$/
            if match
                pawRequest.setHeader match[1], match[2]

        # Set raw body
        if postmanRequest["dataMode"] == "raw"
            contentType = pawRequest.getHeaderByName "Content-Type"
            foundBody = false;

            # If the Content-Type contains "json" make it a JSON body
            if contentType && contentType.indexOf("json") >= 0
                jsonObject = JSON.parse(postmanRequest["rawModeData"])
                if jsonObject
                    pawRequest.jsonBody = jsonObject
                    foundBody = true

            if not foundBody
                pawRequest.body = postmanRequest["rawModeData"]

        # Set Form URL-Encoded body
        else if postmanRequest["dataMode"] == "urlencoded"
            postmanBodyData = postmanRequest["data"]
            bodyObject = new Object()
            for i in postmanBodyData
                # Note: it sounds like all data fields are "text" type
                # when in "urlencoded" data mode.
                if postmanBodyData[i]["type"] == "text"
                    bodyObject[postmanBodyData[i]["key"]] = postmanBodyData[i]["value"]

            pawRequest.urlEncodedBody = bodyObject;

        # Set Multipart body
        else if postmanRequest["dataMode"] == "params"
            postmanBodyData = postmanRequest["data"]
            bodyObject = new Object()
            for i in postmanBodyData
                # Note: due to Apple Sandbox limitations, we cannot import
                # "file" type items
                if postmanBodyData[i]["type"] == "text"
                    bodyObject[postmanBodyData[i]["key"]] = postmanBodyData[i]["value"]

            pawRequest.multipartBody = bodyObject

        console.log "Created Request: #{ postmanRequest["name"] }"

        return pawRequest

    @createPawGroup = (context, postmanRequestsById, postmanFolder) ->

        # Create Paw group
        pawGroup = context.createRequestGroup postmanFolder["name"]

        # Iterate on requests in group
        if postmanFolder["order"]
            for postmanRequestId in postmanFolder["order"]

                # Create a Paw request
                pawRequest = @createPawRequest context, postmanRequestsById, postmanRequestId

                # Add request to parent group
                if pawRequest
                    pawGroup.appendChild pawRequest

        console.log "Created Group: #{ postmanFolder["name"] }"

        return pawGroup

    @importString = (context, string) ->

        # Parse JSON collection
        postmanCollection = JSON.parse string

        # Check Postman data
        if not postmanCollection || not postmanCollection["requests"]
            throw new Error "Invalid Postman data"

        # Build Postman request dictionary (by id)
        postmanRequestsById = new Object()
        for postmanRequest in postmanCollection["requests"]
            postmanRequestsById[postmanRequest["id"]] = postmanRequest

        # Create a Paw Group
        pawRootGroup = context.createRequestGroup postmanCollection["name"]

        # Add Postman folders
        if postmanCollection["folders"]
            for postmanFolder in postmanCollection["folders"]
                pawGroup = @createPawGroup context, postmanRequestsById, postmanFolder

                # Add group to root
                pawRootGroup.appendChild pawGroup

        # Add Postman requests in root
        if postmanCollection["order"]
            for postmanRequestId in postmanCollection["order"]
                # Create a Paw request
                pawRequest = @createPawRequest context, postmanRequestsById, postmanRequestId

                # Add request to root group
                pawRootGroup.appendChild pawRequest

        return true

    return

PostmanImporter.identifier = "com.luckymarmot.PawExtensions.PostmanImporter"
PostmanImporter.title = "Postman Importer"

registerImporter PostmanImporter
