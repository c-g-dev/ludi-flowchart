package ludi.flowchart.loader;

import ludi.flowchart.model.NodeTemplate;
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
        scanDirectory(folder, templates);
        return templates;
    }

    function scanDirectory(folder:String, templates:Array<NodeTemplate>) {
        if (!FileSystem.exists(folder) || !FileSystem.isDirectory(folder)) return;

        var files = FileSystem.readDirectory(folder);
        for (file in files) {
            var fullPath = Path.join([folder, file]);
            if (FileSystem.isDirectory(fullPath)) {
                scanDirectory(fullPath, templates);
            } else {
                    var template = fileLoader.loadFile(fullPath);
                    
                    var parentDirName = Path.withoutDirectory(folder);
                    if (parentDirName != "" && parentDirName != ".") {
                         template.category = parentDirName;
                    }
                    
                    templates.push(template);
            }
        }
    }
}
