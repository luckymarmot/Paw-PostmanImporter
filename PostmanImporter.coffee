PostmanImporter = ->

    # Create Paw requests from a Postman Request (object)
    @createPawRequest = (context, postmanRequestsById, postmanRequestId) ->

        # Get Request
        postmanRequest = postmanRequestsById[postmanRequestId]

        if not postmanRequest
            console.log "Corrupted Postman file, no request found for ID: #{ postmanRequestId }"
            return null

        # Create Paw request
        pawRequest = context.createRequest postmanRequest["name"], postmanRequest["method"], @expandEnvironmentVariables(context, postmanRequest["url"])

        # Add Headers
        # Postman stores headers like HTTP headers, separated by \n
        postmanHeaders = postmanRequest["headers"].split "\n"
        for headerLine in postmanHeaders
            match = headerLine.match /^([^\s\:]*)\s*\:\s*(.*)$/
            if match
                pawRequest.setHeader @expandEnvironmentVariables(context, match[1]), @expandEnvironmentVariables(context, match[2])

        # Set raw body
        if postmanRequest["dataMode"] == "raw"
            contentType = pawRequest.getHeaderByName "Content-Type"
            rawRequestBody = postmanRequest["rawModeData"]
            foundBody = false;

            # If the Content-Type contains "json" make it a JSON body
            if contentType and contentType.indexOf("json") >= 0 and rawRequestBody and rawRequestBody.length > 0
                # try to parse JSON body input
                try
                    jsonObject = JSON.parse rawRequestBody
                catch error
                    console.log "Cannot parse Request JSON: #{ postmanRequest["name"] } (ID: #{ postmanRequestId })"
                # set the JSON body
                if jsonObject
                    pawRequest.body = @expandEnvironmentVariables context, rawRequestBody
                    foundBody = true

            if not foundBody
                if typeof rawRequestBody isnt 'undefined'
                    pawRequest.body = @expandEnvironmentVariables context, rawRequestBody

        # Set Form URL-Encoded body
        else if postmanRequest["dataMode"] == "urlencoded" and postmanRequest["data"] != null
            postmanBodyData = postmanRequest["data"]
            bodyObject = new Object()
            for bodyItem in postmanBodyData
                # Note: it sounds like all data fields are "text" type
                # when in "urlencoded" data mode.
                if bodyItem["type"] == "text"
                    bodyObject[bodyItem["key"]] = @expandEnvironmentVariables context, bodyItem["value"]

            pawRequest.urlEncodedBody = bodyObject;

        # Set Multipart body
        else if postmanRequest["dataMode"] == "params" and postmanRequest["data"] != null
            postmanBodyData = postmanRequest["data"]
            bodyObject = new Object()
            for bodyItem in postmanBodyData
                # Note: due to Apple Sandbox limitations, we cannot import
                # "file" type items
                if bodyItem["type"] == "text"
                    bodyObject[bodyItem["key"]] = @expandEnvironmentVariables context, bodyItem["value"]

            pawRequest.multipartBody = bodyObject

        return pawRequest

    @expandEnvironmentVariables = (context, string) ->
        rx = /\{\{([^\n\}]+)\}\}/g;
        items = string.split(rx)
        if items.length < 2
            return string
        for i in [1...items.length] by 2
            envVariable = @getEnvironmentVariable context, items[i]
            varID = envVariable.id
            dynamicValue = new DynamicValue "com.luckymarmot.EnvironmentVariableDynamicValue", {environmentVariable: varID}
            items[i] = dynamicValue
        return new DynamicString items...

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

        return pawGroup

    @importCollection = (context, postmanCollection) ->

        # Check Postman data
        if not postmanCollection || not postmanCollection["requests"]
            throw new Error "Invalid Postman file (missing data)"

        # Build Postman request dictionary (by id)
        postmanRequestsById = new Object()
        for postmanRequest in postmanCollection["requests"]
            postmanRequestsById[postmanRequest["id"]] = postmanRequest

        # Create a Paw Group
        pawRootGroup = context.createRequestGroup postmanCollection["name"]

        # If we have either "folders" or "order"
        if postmanCollection["folders"]? || postmanCollection["order"]?

            # Add Postman folders
            if postmanCollection["folders"]?
                for postmanFolder in postmanCollection["folders"]
                    pawGroup = @createPawGroup context, postmanRequestsById, postmanFolder

                    # Add group to root
                    pawRootGroup.appendChild pawGroup

            # Add Postman requests in root
            if postmanCollection["order"]?
                for postmanRequestId in postmanCollection["order"]
                    # Create a Paw request
                    pawRequest = @createPawRequest context, postmanRequestsById, postmanRequestId

                    # Add request to root group
                    pawRootGroup.appendChild pawRequest

        # If the collection does not have "folders" or "order"
        # add all requests in root
        else
            for postmanRequestId, postmanRequest of postmanRequestsById
                # Create a Paw request
                pawRequest = @createPawRequest context, postmanRequestsById, postmanRequestId

                # Add request to root group
                pawRootGroup.appendChild pawRequest


    @importString = (context, string) ->

        # Parse JSON collection
        try
            postmanTree = JSON.parse string
        catch error
            throw new Error "Invalid Postman file (not a valid JSON)"

        if not postmanTree
            throw new Error "Invalid Postman file (missing root data)"

        # import a list of collections
        if postmanTree["collections"]
            for postmanCollection in postmanTree["collections"]
                @importCollection context, postmanCollection
        # import a single collection
        else
            @importCollection context, postmanTree

        return true

    @getEnvironmentDomain = (context) ->
        env = context.getEnvironmentDomainByName('Imported (Postman)')
        if typeof env is 'undefined'
            env = context.createEnvironmentDomain('Imported (Postman)')
        return env

    @getEnvironment = (environmentDomain) ->
        env = environmentDomain.getEnvironmentByName('ImportedEnv')
        if typeof env is 'undefined'
            env = environmentDomain.createEnvironment('ImportedEnv')
        return env

    @getEnvironmentVariable = (context, name) ->
        envD = @getEnvironmentDomain context
        variable = envD.getVariableByName(name)
        if typeof variable is 'undefined'
            env = @getEnvironment(envD)
            varD = {}
            varD[name] = ''
            env.setVariablesValues(varD)
            variable = envD.getVariableByName(name)
        return variable

    return

PostmanImporter.identifier = "com.luckymarmot.PawExtensions.PostmanImporter"
PostmanImporter.title = "Postman Importer"

registerImporter PostmanImporter
