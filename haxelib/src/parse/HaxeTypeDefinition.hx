package parse;

enum TypeKind {
    TClass;
    TInterface;
    TEnum;
    TTypedef;
    TAbstract;
}

enum Access {
    APublic;
    APrivate;
    AStatic;
    AOverride;
    ADynamic;
    AInline;
    AMacro;
    AFinal;
    AExtern;
}

typedef MetaInfo = {
    var name:String;
    var params:Array<String>;
    var pos:Int;
}

typedef ArgInfo = {
    var name:String;
    var type:String; 
    var optional:Bool;
    var value:String; 
}

typedef MethodInfo = {
    var args:Array<ArgInfo>;
    var ret:String; 
}

typedef FieldInfo = {
    var name:String;
    var access:Array<Access>;
    var kind:String; 
    var type:String; 
    var methodInfo:MethodInfo; 
    var meta:Array<MetaInfo>;
    var doc:String; 
    var pos:Int;
}

typedef TypeInfo = {
    var kind:TypeKind;
    var name:String;
    var params:Array<String>; 
    var path:String; 
    var parent:String; 
    var interfaces:Array<String>; 
    var fields:Array<FieldInfo>;
    var meta:Array<MetaInfo>;
    var doc:String;
    var isPrivate:Bool;
    var pos:Int;
}

typedef HaxeTypeDefinition = {
    var packageName:String;
    var imports:Array<String>;
    var types:Array<TypeInfo>;
}
