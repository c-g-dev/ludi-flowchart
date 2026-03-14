package ludi.flowchart.ui;

import js.Browser;
import js.html.DivElement;
import js.html.MouseEvent;

typedef MenuItem = {
    var label:String;
    var action:Void->Void;
}

class ContextMenu {
    var element:DivElement;
    var visible:Bool = false;

    public function new() {
        element = Browser.document.createDivElement();
        element.style.position = "absolute";
        element.style.backgroundColor = "#2d2d2d";
        element.style.border = "1px solid #454545";
        element.style.padding = "5px 0";
        element.style.minWidth = "150px";
        element.style.zIndex = "1000";
        element.style.display = "none";
        element.style.boxShadow = "0 2px 5px rgba(0,0,0,0.5)";
        
        Browser.document.body.appendChild(element);
        
        // Hide on any click outside
        Browser.document.addEventListener("click", function(e) {
            hide();
        });
        
        // Prevent default context menu
        Browser.document.addEventListener("contextmenu", function(e:MouseEvent) {
            // Only if target is not our canvas (handled there)
            if (e.target != Browser.document.getElementById("flowchart-canvas")) {
                // e.preventDefault(); 
            }
        });
    }

    public function show(x:Float, y:Float, items:Array<MenuItem>) {
        element.innerHTML = "";
        
        for (item in items) {
            var itemEl = Browser.document.createDivElement();
            itemEl.innerText = item.label;
            itemEl.style.padding = "8px 15px";
            itemEl.style.cursor = "pointer";
            itemEl.style.color = "#ecf0f1";
            itemEl.style.fontFamily = "Arial, sans-serif";
            itemEl.style.fontSize = "14px";
            
            itemEl.onmouseover = function(e) {
                itemEl.style.backgroundColor = "#3498db";
            };
            itemEl.onmouseout = function(e) {
                itemEl.style.backgroundColor = "transparent";
            };
            
            itemEl.onclick = function(e) {
                e.stopPropagation();
                hide();
                item.action();
            };
            
            element.appendChild(itemEl);
        }
        
        element.style.left = '${x}px';
        element.style.top = '${y}px';
        element.style.display = "block";
        visible = true;
    }

    public function hide() {
        if (visible) {
            element.style.display = "none";
            visible = false;
        }
    }
}
