package ludi.flowchart.model;

class FlowchartNode {
    public var id:String;
    public var x:Float;
    public var y:Float;
    public var template:NodeTemplate;
    public var data:Map<String, Dynamic>;

    public function new(id:String, template:NodeTemplate, x:Float, y:Float) {
        this.id = id;
        this.template = template;
        this.x = x;
        this.y = y;
        this.data = new Map();
        
        // Initialize default values
        for (param in template.params) {
            switch(param) {
                case String(name, _, def): data.set(name, def);
                case Number(name, _, def): data.set(name, def);
                case Boolean(name, _, def): data.set(name, def);
                case Array(name, _, def): data.set(name, def);
                case Dropdown(name, _, def, _): data.set(name, def);
                case Textarea(name, _, def): data.set(name, def);
                case File(name, _, def): data.set(name, def);
                case Custom(name, _, _): data.set(name, null);
            }
        }
    }
}
