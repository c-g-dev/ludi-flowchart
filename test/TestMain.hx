package;

import loader.NodeFolderLoader;
import loader.impl.HaxeNodeParser;
import sys.FileSystem;
import model.NodeTemplate;

class TestMain {
    static function main() {
        trace("Starting tests...");
        
        var parser = new HaxeNodeParser("attach");
        var loader = new NodeFolderLoader(parser);
        
        var nodesPath = "test/nodes";
        if (!FileSystem.exists(nodesPath)) {
             if (!FileSystem.exists(nodesPath)) {
                 throw "Nodes folder not found at " + FileSystem.absolutePath(nodesPath);
             }
        }
        
        var templates = loader.loadAll(nodesPath);
        trace("Loaded " + templates.length + " templates.");
        
        var simple = findTemplate(templates, "SimpleNode");
        assert(simple != null, "SimpleNode not found");
        assert(simple.category == "basic", "SimpleNode category should be 'basic', got " + simple.category);
        assert(simple.params.length == 0, "SimpleNode should have 0 params");

        var complex = findTemplate(templates, "ComplexNode");
        assert(complex != null, "ComplexNode not found");
        assert(complex.category == "advanced", "ComplexNode category should be 'advanced'");
        assert(complex.params.length == 3, "ComplexNode should have 3 params");
        
        checkParam(complex.params[0], "name", "String");
        checkParam(complex.params[1], "count", "Number", 10.0);
        checkParam(complex.params[2], "isActive", "Boolean", true);

        trace("All tests passed!");
    }
    
    static function findTemplate(templates:Array<NodeTemplate>, name:String):NodeTemplate {
        for (t in templates) {
            if (t.name == name) return t;
        }
        return null;
    }
    
    static function checkParam(p:NodeParameter, expectedName:String, expectedType:String, ?expectedVal:Dynamic) {
        var name:String = "";
        var val:Dynamic = null;
        var type:String = "";
        
        switch(p) {
            case String(n, _, v): name = n; val = v; type = "String";
            case Number(n, _, v): name = n; val = v; type = "Number";
            case Boolean(n, _, v): name = n; val = v; type = "Boolean";
            case Array(n, _, v): name = n; val = v; type = "Array";
            default: type = "Unknown";
        }
        
        assert(name == expectedName, "Param name " + name + " != " + expectedName);
        assert(type == expectedType, "Param type " + type + " != " + expectedType);
        if (expectedVal != null) {
            assert(val == expectedVal, "Param value " + val + " != " + expectedVal);
        }
    }
    
    static function assert(cond:Bool, msg:String) {
        if (!cond) {
            trace("FAIL: " + msg);
            throw "Assertion failed: " + msg;
        }
    }
}
