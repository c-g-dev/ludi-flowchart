# Flowchart Compiler

A flowcharting application designed to compile flowcharts into runtime code. It is intended to sit on top of an existing codebase and allow visual programming of its entities while being largely agnostic to the content of the repo.


- Step 1) Point to a folder of classes in some repo (or any kind of file)
- Step 2) Implement **`INodeFileParser`** to parse those files (or use the built in **`HaxeNodeParser`**)
- Step 3) Launch the GUI. Each file is now automatically a node in the flowchart builder.
- Step 4) Save flowcharts as JSON and compile them back to their original source code.


## Node Templates & Loading

You instantiate the application with a set of node templates. To facilitate this, the system provides mechanisms to load existing source code as templates:

- **`NodeFolderLoader`** and **`INodeFileParser`**: Implement these to point the application to folders containing your source code classes.
- The application parses these files to create node templates, allowing you to visually manipulate structures that compile back to those same original classes.

## Connections and Logic

- **Directional Connections**: All connections have a defined `to` and `from`.
- **Actions**: Connections represent actions that a node applies to its downstream children.
- **Hierarchy**: Any node that is not the target of a connection is automatically considered a child of the root.

## Code Examples

### Loading Nodes from Source

You can use `NodeFolderLoader` combined with a parser (like `HaxeNodeParser`) to automatically generate templates from your source files.

```haxe
import loader.NodeFolderLoader;
import loader.impl.HaxeNodeParser;

// Initialize the parser and loader
var parser = new HaxeNodeParser("attach"); // "attach" is the method name used for connections
var loader = new NodeFolderLoader(parser);

// Load all nodes from a directory
var templates = loader.loadAll("src/nodes");

trace("Loaded " + templates.length + " templates.");
```

### Example Node Class

The loader parses classes like the one below. Constructor arguments become node parameters, and the class location determinesEach file is now automatically a node in the flowchart builder.
4)  its category.

```haxe
package nodes.advanced; // Becomes category: "advanced"

class ComplexNode {
    // Constructor arguments become editable parameters in the node
    public function new(name:String, count:Int = 10, isActive:Bool = true) {
        // ... implementation
    }
}
```

### Instantiating the Builder

Once you have your templates (either loaded or manually defined), you can start the flowchart application.

```haxe
import FlowchartBuilder;

var builder = new FlowchartBuilder(templates);
builder.init();
```
