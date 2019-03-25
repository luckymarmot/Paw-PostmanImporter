POSTMAN_ENVIRONMENT_DOMAIN_NAME = 'Postman Environments'

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
        postmanHeaders = (postmanRequest["headers"] || '').split "\n"
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
        if string == null
            string = ''
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

    @getEnvironmentDomain = (context) ->
        env = context.getEnvironmentDomainByName(POSTMAN_ENVIRONMENT_DOMAIN_NAME)
        if typeof env is 'undefined'
            env = context.createEnvironmentDomain(POSTMAN_ENVIRONMENT_DOMAIN_NAME)
        return env

    @getEnvironment = (environmentDomain) ->
        env = environmentDomain.getEnvironmentByName('Default Environment')
        if typeof env is 'undefined'
            env = environmentDomain.createEnvironment('Default Environment')
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

    @canImport = (context, items) ->
        a = 0
        b = 0
        for item in items
            a += @_canImportItem(context, item)
            b += 1
        return if b > 0 then a/b else 0

    @_canImportItem = (context, item) ->
        # Parse JSON
        try
            obj = JSON.parse(item.content)
        catch error
            return 0
        # That's a Postman dump
        if obj and obj.collections? and obj.environments? and obj.globals? and obj.version?
            return 1
        # That's a Postman request or collection export
        if obj and (obj.collections? or obj.requests?) and obj.order? and obj.name? and obj.id?
            return 1
        # That's a Postman environment export
        if obj and obj.values? and obj.name? and obj.id?
            return 1
        return 0

    @importString = (context, str) ->
        return @import(context, [ { content: str } ])

    @import = (context, items) ->
        collections = []
        environments = []

        for item in items
            # Parse JSON
            try
                obj = JSON.parse(item.content)
            catch error
                throw new Error "Invalid Postman file (not a valid JSON)"

            # Dump file
            if obj.collections? and obj.environments?
                for collection in obj.collections
                    collections.push(collection)
                for environment in obj.environments
                    environments.push(environment)
            # Collection file
            if obj.collections? or obj.requests?
                collections.push(obj)
            # Environments file
            else if obj and obj.values? and obj.name?
                environments.push(obj)
            else
                throw new Error "Invalid Postman file (missing required keys)"

        # import environments, so binding can occur later on collection import
        for obj in environments
            @_importEnvironmentsFile(context, obj)

        # import collections after, hope that variables will be bound to
        # imported environment variables
        for obj in collections
            @_importCollectionFile(context, obj)

        return true

    @_importCollectionFile = (context, obj) ->
        # import a list of collections
        if obj.collections
            for postmanCollection in obj.collections
                @importCollection(context, postmanCollection)
        # import a single collection
        else
            @importCollection(context, obj)

        return true

    @_importEnvironmentsFile = (context, obj) ->

        # Get or create the environment domain
        pawEnvironmentDomainName = POSTMAN_ENVIRONMENT_DOMAIN_NAME
        pawEnvironmentDomain = context.getEnvironmentDomainByName(pawEnvironmentDomainName)
        if not pawEnvironmentDomain
            pawEnvironmentDomain = context.createEnvironmentDomain(pawEnvironmentDomainName)

        # Create a new environment
        pawEnvironment = pawEnvironmentDomain.createEnvironment(obj.name)

        variablesDict = {}
        for postmanValue in obj.values
            variablesDict[postmanValue.key] = postmanValue.value

        pawEnvironment.setVariablesValues(variablesDict)

        return true;

    return

PostmanImporter.identifier = "com.luckymarmot.PawExtensions.PostmanImporter"
PostmanImporter.title = "Postman Importer"

registerImporter PostmanImporter
