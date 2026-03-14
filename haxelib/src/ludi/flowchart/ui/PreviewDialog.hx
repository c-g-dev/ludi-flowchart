package ludi.flowchart.ui;

import js.Browser;
import js.html.DialogElement;
import js.html.Element;
import js.html.ButtonElement;
import js.html.PreElement;

class PreviewDialog {
    var dialog:DialogElement;
    var titleEl:Element;
    var contentEl:Element;
    
    public function new(dialogId:String) {
        dialog = cast Browser.document.getElementById(dialogId);
        titleEl = Browser.document.getElementById("preview-title");
        contentEl = Browser.document.getElementById("preview-content");
    }
    
    public function showOptions(callbacks:{
        onTemplates:Void->Void, 
        onFlowchart:Void->Void, 
        onCode:Void->Void
    }) {
        titleEl.innerText = "Select Preview";
        contentEl.innerHTML = "";
        
        var container = Browser.document.createDivElement();
        container.className = "preview-options";
        
        var btnTemplates = createButton("Templates", callbacks.onTemplates);
        var btnFlowchart = createButton("Flowchart", callbacks.onFlowchart);
        var btnCode = createButton("Code", callbacks.onCode);
        
        container.appendChild(btnTemplates);
        container.appendChild(btnFlowchart);
        container.appendChild(btnCode);
        
        contentEl.appendChild(container);
        
        if (!dialog.open) {
            dialog.showModal();
        }
    }
    
    public function showContent(title:String, content:String) {
        titleEl.innerText = title;
        contentEl.innerHTML = "";
        
        var pre:PreElement = Browser.document.createPreElement();
        pre.innerText = content;
        contentEl.appendChild(pre);
    }
    
    function createButton(text:String, onClick:Void->Void):ButtonElement {
        var btn = Browser.document.createButtonElement();
        btn.innerText = text;
        btn.onclick = function(e) {
            e.preventDefault();
            onClick();
        };
        return btn;
    }
}
