package;

import FlowchartBuilder;
import js.Browser;
import model.NodeTemplate;
import types.CustomParamType;
import js.html.InputElement;
import js.html.Element;

class Main {
    static function main() {
        var commonSerialization = {
            attachToNodeTemplate: "{0}.attach({1}, {2});",
            attachToRootTemplate: "{0}.start();"
        };

        var templates:Array<NodeTemplate> = [
            {
                name: "Start",
                category: "Flow",
                params: [],
                cssStyles: {},
                serialization: {
                    initializationTemplate: "var {0} = new Start({1});",
                    attachToNodeTemplate: "{0}.attach({1}, {2});",
                    attachToRootTemplate: "{0}.start();"
                }
            },
            {
                name: "Show Text",
                category: "Events",
                params: [
                    Textarea("text", "Message Text", "Hello World"),
                    Dropdown("position", "Position", "Bottom", ["Top", "Middle", "Bottom"])
                ],
                cssStyles: {},
                serialization: {
                    initializationTemplate: "var {0} = new ShowText({1});",
                    attachToNodeTemplate: "{0}.attach({1}, {2});",
                    attachToRootTemplate: "{0}.start();"
                }
            },
            {
                name: "Wait",
                category: "Events",
                params: [
                    Number("duration", "Duration (seconds)", 1.0)
                ],
                cssStyles: {},
                serialization: {
                    initializationTemplate: "var {0} = new Wait({1});",
                    attachToNodeTemplate: "{0}.attach({1}, {2});",
                    attachToRootTemplate: "{0}.start();"
                }
            },
            {
                name: "Choice",
                category: "Logic",
                params: [
                    Array("options", "Options", [])
                ],
                cssStyles: {},
                serialization: {
                    initializationTemplate: "var {0} = new Choice({1});",
                    attachToNodeTemplate: "{0}.attach({1}, {2});",
                    attachToRootTemplate: "{0}.start();"
                }
            },
            {
                name: "Color Node",
                category: "Custom Example",
                params: [
                    Custom("color", "Background Color", {typeName: "Color"})
                ],
                cssStyles: {},
                serialization: {
                    initializationTemplate: "var {0} = new ColorNode({1});",
                    attachToNodeTemplate: "{0}.attach({1}, {2});",
                    attachToRootTemplate: "{0}.start();"
                }
            }
        ];

        var customTypes:Array<CustomParamType> = [
            {
                typeName: "Color",
                renderControl: function(containerId, initialValue) {
                    return new ColorPickerControl(initialValue);
                }
            }
        ];

        Browser.window.onload = function(_) {
            var builder = new FlowchartBuilder(templates, customTypes);
            builder.init();
        };
    }
}

class ColorPickerControl implements CustomParamControl {
    var input:InputElement;

    public function new(initialValue:Dynamic) {
        input = Browser.document.createInputElement();
        input.type = "color";
        input.value = (initialValue != null && initialValue != "") ? Std.string(initialValue) : "#ff0000";
        input.style.width = "100%";
        input.style.height = "40px";
        input.style.cursor = "pointer";
    }

    public function getValue():Dynamic {
        return input.value;
    }

    public function getElement():Element {
        return input;
    }
}
