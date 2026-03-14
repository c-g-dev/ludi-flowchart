package ludi.flowchart.model;

class Note {
    public var id:String;
    public var text:String;
    public var x:Float;
    public var y:Float;
    public var width:Float;
    public var height:Float;

    public function new(id:String, text:String, x:Float, y:Float, width:Float = 200, height:Float = 150) {
        this.id = id;
        this.text = text;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }
}
