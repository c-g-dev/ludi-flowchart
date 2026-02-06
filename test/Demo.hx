package;

import FlowchartBuilder;
import model.NodeTemplate;
import js.Browser;

class Demo {
    static function main() {
        Browser.window.onload = function(_) {
            new Demo().init();
        };
    }

    public function new() {}

    public function init() {
        var templates:Array<NodeTemplate> = [
            {
                name: "Start",
                category: "Events",
                params: [],
                cssStyles: { "background-color": "#4CAF50" },
                serialization: {
                    initializationTemplate: "// Start",
                    attachToNodeTemplate: "",
                    attachToRootTemplate: ""
                }
            },
            {
                name: "Log",
                category: "Actions",
                params: [
                    NodeParameter.String("message", "Message to log", "Hello World")
                ],
                cssStyles: { "background-color": "#2196F3" },
                serialization: {
                    initializationTemplate: "trace(\"${message}\");",
                    attachToNodeTemplate: "",
                    attachToRootTemplate: ""
                }
            }
        ];

        var builder = new FlowchartBuilder(templates);
        var container = Browser.document.getElementById("app");
        
        builder.loadUI(container);
    }
}
