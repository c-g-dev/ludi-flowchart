package ludi.flowchart.ui;

import js.Browser;
import js.html.DialogElement;
import js.html.Element;
import js.html.InputElement;
import js.html.ButtonElement;
import js.html.Event;

class OptionsDialog {
    var dialog:DialogElement;
    var formContainer:Element;
    var btnConfirm:ButtonElement;
    
    public dynamic function onSave(defaultConnectionTag:String):Void {}

    public function new(dialogId:String) {
        dialog = cast Browser.document.getElementById(dialogId);
        formContainer = Browser.document.getElementById("options-fields");
        btnConfirm = cast Browser.document.getElementById("btn-options-confirm");

        if (btnConfirm != null) {
            btnConfirm.addEventListener("click", onConfirm);
        }
    }

    public function open(currentDefaultTag:String) {
        formContainer.innerHTML = "";
        
        // Default Connection Tag
        createField("Default Connection Tag", "default_connection_tag", currentDefaultTag, "text");

        dialog.showModal();
    }

    function createField(labelStr:String, name:String, value:Dynamic, type:String) {
        var div = Browser.document.createDivElement();
        div.className = "form-group";

        var label = Browser.document.createLabelElement();
        label.innerText = labelStr;
        div.appendChild(label);

        var input:InputElement = Browser.document.createInputElement();
        input.name = name;
        input.value = Std.string(value);
        input.type = type;
        div.appendChild(input);

        formContainer.appendChild(div);
    }

    function onConfirm(e:Event) {
        e.preventDefault(); // Prevent form submission if strictly needed, though dialog form usually handles it.
        
        var inputs = formContainer.querySelectorAll("input");
        var newTag = "";
        
        for (i in 0...inputs.length) {
            var el:InputElement = cast inputs[i];
            if (el.name == "default_connection_tag") {
                newTag = el.value;
            }
        }

        dialog.close();
        onSave(newTag);
    }
}
