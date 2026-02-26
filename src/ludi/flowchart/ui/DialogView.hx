package ludi.flowchart.ui;

import js.Browser;
import js.html.DialogElement;
import js.html.Element;
import js.html.InputElement;
import js.html.SelectElement;
import js.html.TextAreaElement;
import js.html.ButtonElement;
import js.html.OptionElement;
import js.html.Event;
import ludi.flowchart.model.FlowchartNode;
import ludi.flowchart.model.NodeTemplate;
import ludi.flowchart.model.Note;
import ludi.flowchart.types.CustomParamType;

class DialogView {
    var dialog:DialogElement;
    var formContainer:Element;
    var btnConfirm:ButtonElement;
    var currentNode:FlowchartNode;
    var currentNote:Note;
    
    var customTypes:Array<CustomParamType>;
    var activeControls:Map<String, CustomParamControl>;

    public dynamic function onSave(node:FlowchartNode):Void {}
    public dynamic function onSaveNote(note:Note):Void {}

    public function new(dialogId:String, ?customTypes:Array<CustomParamType>) {
        dialog = cast Browser.document.getElementById(dialogId);
        formContainer = Browser.document.getElementById("editor-fields");
        btnConfirm = cast Browser.document.getElementById("btn-confirm");
        this.customTypes = customTypes != null ? customTypes : [];
        this.activeControls = new Map();

        btnConfirm.addEventListener("click", onConfirm);
    }

    public function open(node:FlowchartNode) {
        currentNode = node;
        currentNote = null;
        formContainer.innerHTML = "";
        activeControls = new Map(); // Clear old controls
        
        // Title (Read-only from template)
        var titleDiv = Browser.document.createDivElement();
        titleDiv.className = "form-group";
        titleDiv.innerHTML = '<label>Type</label><input type="text" value="${node.template.name}" disabled>';
        formContainer.appendChild(titleDiv);

        // Parameters
        for (param in node.template.params) {
            switch(param) {
                case String(name, desc, _):
                    var val = node.data.exists(name) ? node.data.get(name) : "";
                    createField(desc, name, val, "text");
                case Number(name, desc, _):
                    var val = node.data.exists(name) ? node.data.get(name) : 0;
                    createField(desc, name, val, "number");
                case Boolean(name, desc, _):
                    var val = node.data.exists(name) ? node.data.get(name) : false;
                    createField(desc, name, val, "checkbox");
                case Array(name, desc, _):
                    // Simple JSON string edit for now
                    var val = node.data.exists(name) ? haxe.Json.stringify(node.data.get(name)) : "[]";
                    createField(desc, name, val, "text"); 
                case Dropdown(name, desc, _, options):
                    var val = node.data.exists(name) ? node.data.get(name) : options[0];
                    createSelect(desc, name, val, options);
                case Textarea(name, desc, _):
                    var val = node.data.exists(name) ? node.data.get(name) : "";
                    createField(desc, name, val, "textarea");
                case File(name, desc, _):
                    var val = node.data.exists(name) ? node.data.get(name) : "";
                    createField(desc, name, val, "text"); // File path string for now
                case Custom(name, desc, custom):
                    var val = node.data.exists(name) ? node.data.get(name) : null;
                    createCustomField(desc, name, val, custom.typeName);
            }
        }

        dialog.showModal();
    }

    public function openNote(note:Note) {
        currentNote = note;
        currentNode = null;
        formContainer.innerHTML = "";

        // Note Content
        createField("Note Text", "note_text", note.text, "textarea");

        dialog.showModal();
    }

    function createCustomField(labelStr:String, name:String, value:Dynamic, typeName:String) {
        var div = Browser.document.createDivElement();
        div.className = "form-group";

        var label = Browser.document.createLabelElement();
        label.innerText = labelStr;
        div.appendChild(label);

        // Find Custom Type
        var foundType = null;
        for (ct in customTypes) {
            if (ct.typeName == typeName) {
                foundType = ct;
                break;
            }
        }

        if (foundType != null) {
            var controlContainer = Browser.document.createDivElement();
            controlContainer.id = "custom_ctrl_" + name;
            div.appendChild(controlContainer);
            
            var control = foundType.renderControl(controlContainer.id, value);
            if (control != null) {
                 activeControls.set(name, control);
                 // Some controls might append themselves, others might need manual appending if renderControl returns element but doesn't attach.
                 // Assuming renderControl handles attachment or we use getElement()
                 var el = control.getElement();
                 if (el != null && el.parentElement == null) {
                     controlContainer.appendChild(el);
                 }
            }
        } else {
             // Fallback
             div.innerHTML += " <span>(Custom Type '" + typeName + "' not found)</span>";
        }

        formContainer.appendChild(div);
    }

    function createField(labelStr:String, name:String, value:Dynamic, type:String) {
        var div = Browser.document.createDivElement();
        div.className = "form-group";

        var label = Browser.document.createLabelElement();
        label.innerText = labelStr;
        div.appendChild(label);

        if (type == "textarea") {
            var input:TextAreaElement = Browser.document.createTextAreaElement();
            input.name = name;
            input.value = Std.string(value);
            input.style.width = "100%";
            input.style.minHeight = "150px"; // Taller for notes
            div.appendChild(input);
        } else if (type == "checkbox") {
            var input:InputElement = Browser.document.createInputElement();
            input.name = name;
            input.type = "checkbox";
            input.checked = (value == true);
            div.appendChild(input);
        } else {
            var input:InputElement = Browser.document.createInputElement();
            input.name = name;
            input.value = Std.string(value);
            input.type = type;
            div.appendChild(input);
        }

        formContainer.appendChild(div);
    }

    function createSelect(labelStr:String, name:String, value:Dynamic, options:Array<String>) {
        var div = Browser.document.createDivElement();
        div.className = "form-group";

        var label = Browser.document.createLabelElement();
        label.innerText = labelStr;
        div.appendChild(label);

        var select:SelectElement = Browser.document.createSelectElement();
        select.name = name;
        
        for (opt in options) {
            var option:OptionElement = Browser.document.createOptionElement();
            option.value = opt;
            option.text = opt;
            if (opt == Std.string(value)) {
                option.selected = true;
            }
            select.appendChild(option);
        }
        div.appendChild(select);
        formContainer.appendChild(div);
    }

    function onConfirm(e:Event) {
        e.preventDefault();
        
        if (currentNote != null) {
            // Save Note
            var inputs = formContainer.querySelectorAll("textarea");
            if (inputs.length > 0) {
                 var el:TextAreaElement = cast inputs[0];
                 currentNote.text = el.value;
                 onSaveNote(currentNote);
            }
            dialog.close();
            return;
        }

        if (currentNode == null) return;

        // Read values from standard inputs
        var inputs = formContainer.querySelectorAll("input, textarea, select");
        for (i in 0...inputs.length) {
            var el:Dynamic = inputs[i];
            var name = el.name;
            
            // Skip if it's inside a custom control container? 
            // We'll handle custom controls separately, but standard logic might pick up inputs inside custom controls if we are not careful.
            // Ideally custom controls manage their own inputs.
            // However, our standard inputs are direct children of form-group (or inside it), while custom control inputs are deep inside.
            // Let's rely on finding param definition.

            var val:Dynamic = el.value;
            
            if (el.type == "checkbox") {
                val = el.checked;
            } else if (el.type == "number") {
                val = Std.parseFloat(val);
            }
            
            // Find param definition
            for (param in currentNode.template.params) {
                var pName = switch(param) {
                    case String(n,_,_): n; case Number(n,_,_): n; case Boolean(n,_,_): n;
                    case Array(n,_,_): n; case Dropdown(n,_,_,_): n; case Textarea(n,_,_): n;
                    case File(n,_,_): n; case Custom(n,_,_): n;
                };
                
                if (pName == name) {
                    // Only process standard types here
                    switch(param) {
                        case Custom(_,_,_):
                            // Do nothing here, handled below via activeControls
                            continue;
                        case Array(_,_,_):
                             try {
                                 val = haxe.Json.parse(val);
                             } catch(e:Dynamic) {
                             }
                             currentNode.data.set(name, val);
                        default:
                             currentNode.data.set(name, val);
                    }
                    break;
                }
            }
        }

        // Read values from Custom Controls
        for (name in activeControls.keys()) {
            var control = activeControls.get(name);
            var val = control.getValue();
            currentNode.data.set(name, val);
        }

        dialog.close();
        onSave(currentNode);
    }
}
