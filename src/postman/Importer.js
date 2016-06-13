import BaseImporter from 'paw-base-importer'
import RequestContext, {
    Group,
    Parser
} from 'api-flow'

@registerImporter // eslint-disable-line
export default class PostmanImporter extends BaseImporter {
    static identifier = 'com.luckymarmot.PawExtensions.PostmanImporter';
    static title = 'Postman Importer';

    static fileExtensions = [];
    static inputs = [];

    constructor() {
        super()
        this.ENVIRONMENT_DOMAIN_NAME = 'Postman Environments'
    }

    canImport(context, items) {
        let sum = 0
        for (let item of items) {
            sum += ::this._canImportItem(context, item)
        }
        return items.length > 0 ? sum / items.length : 0
    }

    _canImportItem(context, item) {
        let postman
        try {
            postman = JSON.parse(item.content)
        }
        catch (jsonParseError) {
            return 0
        }
        if (postman) {
            let score = 0
            score += postman.collections ? 1 / 2 : 0
            score += postman.environments ? 1 / 2 : 0
            score += postman.id && postman.name && postman.timestamp ? 1 / 2 : 0
            score += postman.requests ? 1 / 2 : 0
            score += postman.values ? 1 / 2 : 0
            score = score < 1 ? score : 1
            return score
        }
        return 0
    }

    /*
      @params:
        - reqContexts
        - context
        - items
        - options
    */
    createRequestContext(reqContexts, context, item) {
        const parser = new Parser.Postman()
        try {
            let reqContext = parser.parse(item.content)
        }
        catch (e) {
            throw new Error(
                'Postman recently changed the format in which they ' +
                'store their data. We are currently working on a fix. In the ' +
                'meantime, API-Flow may help you convert your postman files ' +
                'to Swagger files. For more info, see issue #13 on Github:\n' +
                'https://github.com/luckymarmot/Paw-PostmanImporter/issues/13'
            )
        }

        let current = reqContexts[0] || {
            context: new RequestContext(),
            items: []
        }

        let currentReqContext = current.context

        currentReqContext = currentReqContext
            .mergeEnvironments(reqContext.get('environments'))

        if (
            currentReqContext.getIn([ 'group', 'name' ])
            ===
            'Postman'
        ) {
            if (reqContext.getIn([ 'group', 'children' ]).size > 0) {
                let name = reqContext.getIn([ 'group', 'name' ]) ||
                    ((item || {}).file || {}).name ||
                    (item || {}).url ||
                    null
                currentReqContext = currentReqContext.setIn(
                    [ 'group', 'children', name ],
                    reqContext.get('group')
                )
            }
        }
        else {
            let rootGroup = new Group({
                name: 'Postman'
            })

            if (reqContext.getIn([ 'group', 'children' ]).size > 0) {
                let name = reqContext.getIn([ 'group', 'name' ]) ||
                    ((item || {}).file || {}).name ||
                    (item || {}).url ||
                    null
                rootGroup = rootGroup.setIn(
                    [ 'children', name ],
                    reqContext.get('group')
                )
            }
            currentReqContext = currentReqContext.set('group', rootGroup)
        }

        current.context = currentReqContext
        current.items.push(item)

        return [ current ]
    }
}
