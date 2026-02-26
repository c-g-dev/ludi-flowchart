package ludi.flowchart.ui;

import js.Browser;
import js.html.DivElement;

class Toast {
    static var container:DivElement;

    public static function show(message:String) {
        if (container == null) {
            container = Browser.document.createDivElement();
            container.style.position = "fixed";
            container.style.bottom = "20px";
            container.style.left = "50%";
            container.style.transform = "translateX(-50%)";
            container.style.zIndex = "2000";
            container.style.pointerEvents = "none"; // Let clicks pass through
            Browser.document.body.appendChild(container);
        }

        var toast = Browser.document.createDivElement();
        toast.innerText = message;
        toast.style.backgroundColor = "#333";
        toast.style.color = "#fff";
        toast.style.padding = "10px 20px";
        toast.style.marginBottom = "10px";
        toast.style.borderRadius = "4px";
        toast.style.boxShadow = "0 2px 5px rgba(0,0,0,0.3)";
        toast.style.opacity = "0";
        toast.style.transition = "opacity 0.3s ease";
        toast.style.fontFamily = "Arial, sans-serif";
        
        container.appendChild(toast);
        
        // Fade in
        Browser.window.requestAnimationFrame(function(_) {
            toast.style.opacity = "1";
        });
        
        // Fade out and remove
        haxe.Timer.delay(function() {
            toast.style.opacity = "0";
            haxe.Timer.delay(function() {
                if (toast.parentElement == container) {
                    container.removeChild(toast);
                }
            }, 300);
        }, 3000);
    }
}
