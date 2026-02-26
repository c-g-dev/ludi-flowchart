package ludi.flowchart.types;

import js.html.Element;

typedef CustomParamType = {
    var typeName:String;
    var renderControl:String->Dynamic->CustomParamControl; // containerID -> initialValue -> Control
    @:optional var serializeValue:Dynamic->String; // value -> generated Haxe code
}

interface CustomParamControl {
    function getValue():Dynamic;
    function getElement():Element;
}
