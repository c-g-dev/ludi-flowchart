package ludi.flowchart.ui;

import js.Browser;

class FlowchartUILoader {
    public static function load(container:js.html.Element, onComplete:Void->Void) {
        var htmlContent:String = null;
        
        // Try to load from embedded resources first
        if (haxe.Resource.listNames().indexOf("flowchart_html") != -1) {
            htmlContent = haxe.Resource.getString("flowchart_html");
        }
        
        if (htmlContent != null) {
            // Extract body content to avoid nesting html/body tags
            var bodyMatch = ~/<body[^>]*>([\s\S]*)<\/body>/i;
            if (bodyMatch.match(htmlContent)) {
                container.innerHTML = bodyMatch.matched(1);
            } else {
                container.innerHTML = htmlContent;
            }
        }

        // Load CSS
        var cssFiles = ["flowchart_style_css", "style_css"];
        for (resourceName in cssFiles) {
            var content:String = null;
            if (haxe.Resource.listNames().indexOf(resourceName) != -1) {
                content = haxe.Resource.getString(resourceName);
            }

            if (content != null) {
                var style = Browser.document.createStyleElement();
                style.textContent = content;
                Browser.document.head.appendChild(style);
            }
        }
        
        // Inject FontAwesome (as present in flowchart.html)
        var link = Browser.document.createLinkElement();
        link.rel = "stylesheet";
        link.href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css";
        Browser.document.head.appendChild(link);

        if (onComplete != null) {
            onComplete();
        }
    }
}
