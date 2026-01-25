package loader.impl;

import loader.INodeFileParser;
import loader.ParsedNodeInfo;
import parse.HaxeTypedefParse;
import parse.HaxeTypeDefinition;
import model.NodeTemplate.NodeParameter;
import sys.io.File;

class HaxeNodeParser implements INodeFileParser {
    var attachMethodName:String;
    var customTypes:Array<String>;

    public function new(attachMethodName:String, ?customTypes:Array<String>) {
        this.attachMethodName = attachMethodName;
        this.customTypes = customTypes != null ? customTypes : [];
    }

    public function parse(file:String):ParsedNodeInfo {
        var content = sys.io.File.getContent(file);
        var def = HaxeTypedefParse.parse(content);
        var parsed = new ParsedNodeInfo();

        // 2) Category from bottommost package level
        var parts = def.packageName.split(".");
        parsed.nodeCategory = parts.length > 0 ? parts[parts.length - 1] : "";
        
        // Find the class definition
        var classType:TypeInfo = null;
        for (type in def.types) {
            if (type.kind == TClass) {
                classType = type;
                break;
            }
        }

        if (classType != null) {
            parsed.className = classType.name;
            parsed.attachMethodName = this.attachMethodName;

            // Find constructor
            var constructor:FieldInfo = null;
            for (field in classType.fields) {
                if (field.name == "new") {
                    constructor = field;
                    break;
                }
            }

            if (constructor != null && constructor.methodInfo != null) {
                for (arg in constructor.methodInfo.args) {
                    var param:NodeParameter;
                    var type = arg.type;
                    if (type == null) type = "String"; // Fallback

                    // Simple type mapping logic
                    // Cleaning up type string slightly if needed (e.g. spaces)
                    type = StringTools.trim(type);

                    // Check if it matches a custom type
                    if (customTypes.indexOf(type) != -1) {
                         param = NodeParameter.Custom(arg.name, arg.name, {typeName: type});
                    } else if (type == "String") {
                        var defVal = arg.value != null ? cleanStringValue(arg.value) : "";
                        param = NodeParameter.String(arg.name, arg.name, defVal);
                    } else if (type == "Int" || type == "Float") {
                        var defVal = arg.value != null ? Std.parseFloat(arg.value) : 0.0;
                        if (Math.isNaN(defVal)) defVal = 0.0;
                        param = NodeParameter.Number(arg.name, arg.name, defVal);
                    } else if (type == "Bool") {
                        var defVal = arg.value == "true";
                        param = NodeParameter.Boolean(arg.name, arg.name, defVal);
                    } else if (StringTools.startsWith(type, "Array")) {
                        param = NodeParameter.Array(arg.name, arg.name, []);
                    } else {
                         // Unmatchable types use String
                         var defVal = arg.value != null ? arg.value : "";
                         param = NodeParameter.String(arg.name, arg.name, defVal);
                    }
                    
                    parsed.params.push(param);
                }
            }
        }

        return parsed;
    }

    function cleanStringValue(val:String):String {
        if (StringTools.startsWith(val, '"') && StringTools.endsWith(val, '"')) {
            return val.substring(1, val.length - 1);
        }
        if (StringTools.startsWith(val, "'") && StringTools.endsWith(val, "'")) {
            return val.substring(1, val.length - 1);
        }
        return val;
    }
}
