package ludi.flowchart;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

class FlowchartInit {
    public static function init() {
        var pos = Context.resolvePath("ludi/flowchart/FlowchartInit.hx");
        var srcDir = Path.directory(pos);
        var libRoot = srcDir;
        for (_ in 0...3) libRoot = Path.directory(libRoot); // flowchart->ludi->src->libRoot
        var binDir = Path.join([libRoot, "bin"]);

        add(binDir, "flowchart.html", "flowchart_html");
        add(binDir, "flowchart_style.css", "flowchart_style_css");
        add(binDir, "style.css", "style_css");
    }

    static function add(dir:String, fileName:String, resourceName:String) {
        var path = Path.join([dir, fileName]);
        if (FileSystem.exists(path)) {
            Context.addResource(resourceName, File.getBytes(path));
        } else {
            Context.fatalError("ludi-flowchart: Resource file not found: " + path, Context.currentPos());
        }
    }
}
#end
