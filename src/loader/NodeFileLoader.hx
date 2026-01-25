package loader;

import model.NodeTemplate;

class NodeFileLoader {
    var parser:INodeFileParser;

    public function new(parser:INodeFileParser) {
        this.parser = parser;
    }

    public function loadFile(file:String):NodeTemplate {
        var parsed = parser.parse(file);
        return convertParsedToTemplate(parsed);
    }

    public function convertParsedToTemplate(parsed:ParsedNodeInfo):NodeTemplate {
        var params = [];
        for (param in parsed.params) {
            params.push(param);
        }

        var attachTemplate = "{0}.next = {1};";
        if (parsed.attachMethodName != null && parsed.attachMethodName.length > 0) {
            attachTemplate = "{0}." + parsed.attachMethodName + "({1});";
        }

        return {
            name: parsed.className,
            category: parsed.nodeCategory,
            params: params,
            cssStyles: {},
            serialization: {
                initializationTemplate: "var {0} = new " + parsed.className + "({1});",
                attachToNodeTemplate: attachTemplate,
                attachToRootTemplate: "{0}.start();"
            }
        };
    }
}
