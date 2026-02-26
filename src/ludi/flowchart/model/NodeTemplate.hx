package ludi.flowchart.model;

typedef NodeTemplate = {
    name:String,
    category:String,
    params:Array<NodeParameter>,
    cssStyles:Dynamic,
    serialization:NodeSerializationTemplate
}

typedef NodeSerializationTemplate = {
    initializationTemplate:String,
    attachToNodeTemplate:String,
    attachToRootTemplate:String
}

enum NodeParameter {
    String(name:String, description:String, defaultValue:String);
    Number(name:String, description:String, defaultValue:Float);
    Boolean(name:String, description:String, defaultValue:Bool);
    Array(name:String, description:String, defaultValue:Array<Dynamic>);
    Dropdown(name:String, description:String, defaultValue:String, options:Array<String>);
    Textarea(name:String, description:String, defaultValue:String);
    File(name:String, description:String, defaultValue:String);
    Custom(name:String, description:String, custom:CustomNodeParameter);
}

typedef CustomNodeParameter = {
    typeName:String
}
