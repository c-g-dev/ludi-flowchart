package types;

import js.html.Element;

typedef CustomParamType = {
    var typeName:String;
    var renderControl:String->Dynamic->CustomParamControl; // containerID -> initialValue -> Control
}

interface CustomParamControl {
    function getValue():Dynamic;
    function getElement():Element;
}
