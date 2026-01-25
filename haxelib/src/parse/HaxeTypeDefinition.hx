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
    var type:String; // String representation of the type
    var optional:Bool;
    var value:String; // Default value if any, as string
}

typedef MethodInfo = {
    var args:Array<ArgInfo>;
    var ret:String; // Return type
}

typedef FieldInfo = {
    var name:String;
    var access:Array<Access>;
    var kind:String; // "var" or "function"
    var type:String; // Type for vars, null for functions (use methodInfo)
    var methodInfo:MethodInfo; // Null if it's a var
    var meta:Array<MetaInfo>;
    var doc:String; // Documentation comment
    var pos:Int;
}

typedef TypeInfo = {
    var kind:TypeKind;
    var name:String;
    var params:Array<String>; // Type parameters like <T>
    var path:String; // Full dot path including package
    var parent:String; // extends class
    var interfaces:Array<String>; // implements
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
