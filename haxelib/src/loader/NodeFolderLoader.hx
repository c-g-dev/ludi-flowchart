package loader;

import model.NodeTemplate;
import sys.FileSystem;
import haxe.io.Path;

class NodeFolderLoader {
    var parser:INodeFileParser;
    var fileLoader:NodeFileLoader;

    public function new(parser:INodeFileParser) {
        this.parser = parser;
        this.fileLoader = new NodeFileLoader(parser);
    }

    public function loadAll(folder:String):Array<NodeTemplate> {
        var templates = new Array<NodeTemplate>();
        
        if (FileSystem.exists(folder) && FileSystem.isDirectory(folder)) {
            var files = FileSystem.readDirectory(folder);
            for (file in files) {
                var fullPath = Path.join([folder, file]);
                if (!FileSystem.isDirectory(fullPath)) {
                    var template = fileLoader.loadFile(fullPath);
                    templates.push(template);
                }
            }
        }
        
        return templates;
    }
}
