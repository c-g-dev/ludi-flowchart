package parse;

import parse.HaxeTypeDefinition;

enum Token {
    TId(s:String);
    TString(s:String);
    TInt(s:String);
    TFloat(s:String);
    TSymbol(s:String); 
    TEof;
}

class HaxeTypedefParse {
    var src:String;o
    var pos:Int;
    var len:Int;
    var tokens:Array<Token>;
    var tokenIdx:Int;

    public function new(src:String) {
        this.src = src;
        this.len = src.length;
        this.pos = 0;
        this.tokens = [];
        this.tokenIdx = 0;
    }

    public static function parse(content:String):HaxeTypeDefinition {
        var parser = new HaxeTypedefParse(content);
        parser.tokenize();
        return parser.parseFile();
    }

    
    
    

    function tokenize() {
        while (pos < len) {
            var c = src.charCodeAt(pos);
            
            if (isSpace(c)) {
                pos++;
                continue;
            }

            
            if (c == '/'.code) {
                var next = src.charCodeAt(pos + 1);
                if (next == '/'.code) {
                    
                    var start = pos;
                    pos += 2;
                    while (pos < len && src.charCodeAt(pos) != '\n'.code && src.charCodeAt(pos) != '\r'.code) {
                        pos++;
                    }
                    
                    
                    continue;
                } else if (next == '*'.code) {
                    
                    var start = pos;
                    pos += 2;
                    var isDoc = (src.charCodeAt(pos) == '*'.code);
                    var closed = false;
                    while (pos < len - 1) {
                        if (src.charCodeAt(pos) == '*'.code && src.charCodeAt(pos + 1) == '/'.code) {
                            pos += 2;
                            closed = true;
                            break;
                        }
                        pos++;
                    }
                    if (!closed) throw "Unclosed comment at " + start;
                    
                    if (isDoc) {
                        
                        
                        
                        
                    }
                    continue;
                }
            }

            
            if (c == '"'.code || c == '\''.code) {
                tokens.push(readString(c));
                continue;
            }

            
            if (isDigit(c) || (c == '.'.code && isDigit(src.charCodeAt(pos+1)))) {
                tokens.push(readNumber());
                continue;
            }

            
            if (isIdentStart(c)) {
                tokens.push(TId(readIdent()));
                continue;
            }

            
            
            var char = src.charAt(pos);
            var next = (pos + 1 < len) ? src.charAt(pos + 1) : "";
            var two = char + next;
            var three = (pos + 2 < len) ? two + src.charAt(pos + 2) : "";

            if (three == "..." || three == ">>>") { 
                 tokens.push(TSymbol(three));
                 pos += 3;
                 continue;
            }

            if (two == "->" || two == "==" || two == "!=" || two == "<=" || two == ">=" || 
                two == "++" || two == "--" || two == "+=" || two == "-=" || two == "*=" || 
                two == "/=" || two == "%=" || two == "&&" || two == "||" || two == "<<" || 
                two == ">>" || two == "?." || two == "=>") {
                tokens.push(TSymbol(two));
                pos += 2;
                continue;
            }
            
            
            if (";,(){}[]:.=<>?!+-*/%&|^~@".indexOf(char) != -1) {
                tokens.push(TSymbol(char));
                pos++;
                continue;
            }

            throw "Unexpected character '" + char + "' at " + pos;
        }
        tokens.push(TEof);
    }

    function readString(quote:Int):Token {
        var start = pos;
        pos++; 
        var buf = new StringBuf();
        while (pos < len) {
            var c = src.charCodeAt(pos);
            if (c == quote) {
                pos++;
                return TString(buf.toString());
            }
            if (c == '\\'.code) {
                pos++;
                if (pos >= len) throw "Unclosed string at " + start;
                var esc = src.charCodeAt(pos);
                pos++;
                
                buf.addChar(esc); 
                continue;
            }
            buf.addChar(c);
            pos++;
        }
        throw "Unclosed string starting at " + start;
    }

    function readNumber():Token {
        var start = pos;
        var dotFound = false;
        while (pos < len) {
            var c = src.charCodeAt(pos);
            if (isDigit(c)) {
                pos++;
            } else if (c == '.'.code) {
                if (dotFound) break; 
                
                if (pos + 1 < len && isDigit(src.charCodeAt(pos+1))) {
                     dotFound = true;
                     pos++;
                } else {
                    break; 
                }
            } else if (c == 'e'.code || c == 'E'.code) {
                pos++;
                if (pos < len && (src.charCodeAt(pos) == '-'.code || src.charCodeAt(pos) == '+'.code)) pos++;
                while (pos < len && isDigit(src.charCodeAt(pos))) pos++;
                return TFloat(src.substring(start, pos));
            } else if (c == 'x'.code && pos == start + 1 && src.charCodeAt(start) == '0'.code) {
                 pos++;
                 while (pos < len && isHex(src.charCodeAt(pos))) pos++;
                 return TInt(src.substring(start, pos));
            } else {
                break;
            }
        }
        var s = src.substring(start, pos);
        return dotFound ? TFloat(s) : TInt(s);
    }

    function readIdent():String {
        var start = pos;
        while (pos < len) {
            var c = src.charCodeAt(pos);
            if (isIdentPart(c)) {
                pos++;
            } else {
                break;
            }
        }
        return src.substring(start, pos);
    }

    inline function isSpace(c:Int):Bool return (c == 32 || c == 9 || c == 10 || c == 13);
    inline function isDigit(c:Int):Bool return (c >= 48 && c <= 57);
    inline function isHex(c:Int):Bool return isDigit(c) || (c >= 97 && c <= 102) || (c >= 65 && c <= 70);
    inline function isIdentStart(c:Int):Bool return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == '_'.code;
    inline function isIdentPart(c:Int):Bool return isIdentStart(c) || isDigit(c);


    
    
    

    function peek():Token {
        return tokens[tokenIdx];
    }

    function next():Token {
        var t = tokens[tokenIdx];
        if (tokenIdx < tokens.length - 1) tokenIdx++;
        return t;
    }

    function match(s:String):Bool {
        var t = peek();
        switch (t) {
            case TId(id): return id == s;
            case TSymbol(sym): return sym == s;
            default: return false;
        }
    }

    function consume(s:String):Void {
        if (match(s)) {
            next();
        } else {
            throw "Expected '" + s + "' but found " + Std.string(peek());
        }
    }

    function consumeId():String {
        var t = next();
        switch (t) {
            case TId(s): return s;
            default: throw "Expected identifier but found " + Std.string(t);
        }
    }

    

    function parseFile():HaxeTypeDefinition {
        var imports:Array<String> = [];
        var types:Array<TypeInfo> = [];
        var packageName = "";

        while (true) {
            var t = peek();
            switch (t) {
                case TEof:
                    break;
                case TId("package"):
                    next();
                    packageName = parsePath();
                    consume(";");
                case TId("import"):
                    next();
                    imports.push(parsePath());
                    consume(";");
                    
                case TId("using"):
                    next();
                    
                    
                    parsePath();
                    consume(";");
                case TId("class") | TId("interface") | TId("enum") | TId("typedef") | TId("abstract") | TId("final") | TId("extern") | TId("private") | TSymbol("@"):
                    types.push(parseType());
                default:
                     
                     throw "Unexpected token at top level: " + Std.string(t);
            }
        }

        return {
            packageName: packageName,
            imports: imports,
            types: types
        };
    }

    function parsePath():String {
        var parts = [consumeId()];
        while (match(".")) {
            next(); 
            
            if (match("*")) {
                 next(); 
                 parts.push("*");
                 break;
            }
            parts.push(consumeId());
        }
        return parts.join(".");
    }

    function parseType():TypeInfo {
        var meta = parseMeta();
        var doc = ""; 
        var isPrivate = false;
        var access = [];

        
        while (true) {
            if (match("private")) {
                next();
                isPrivate = true;
            } else if (match("extern")) {
                next();
                
            } else if (match("final")) {
                next();
            } else {
                break;
            }
        }

        var kind:TypeKind;
        if (match("class")) { next(); kind = TClass; }
        else if (match("interface")) { next(); kind = TInterface; }
        else if (match("enum")) { next(); kind = TEnum; }
        else if (match("typedef")) { next(); kind = TTypedef; }
        else if (match("abstract")) { next(); kind = TAbstract; }
        else throw "Expected type declaration but found " + Std.string(peek());

        var name = consumeId();
        var params = parseTypeParams();
        
        var parent:String = null;
        var interfaces:Array<String> = [];

        
        while (true) {
            if (match("extends")) {
                next();
                parent = parseComplexType();
            } else if (match("implements")) {
                next();
                interfaces.push(parseComplexType());
            } else if (match("from") || match("to")) {
                 
                 next();
                 parseComplexType(); 
            } else {
                break;
            }
        }

        var fields:Array<FieldInfo> = [];

        if (kind == TTypedef) {
             consume("=");
             
             if (match("{")) {
                  
                  fields = parseFields(false);
             } else {
                 
                 var alias = parseComplexType();
                 
                 
             }
             if (match(";")) consume(";");
        } else {
            fields = parseFields(true);
        }

        return {
            kind: kind,
            name: name,
            params: params,
            path: name, 
            parent: parent,
            interfaces: interfaces,
            fields: fields,
            meta: meta,
            doc: doc,
            isPrivate: isPrivate,
            pos: 0 
        };
    }

    function parseFields(expectBraces:Bool):Array<FieldInfo> {
        if (expectBraces) consume("{");
        else {
             if (match("{")) next(); else return []; 
        }

        var fields:Array<FieldInfo> = [];
        
        while (!match("}") && peek() != TEof) {
            
            fields.push(parseField());
            
            if (match(";")) next();
        }
        
        consume("}");
        return fields;
    }

    function parseField():FieldInfo {
        var meta = parseMeta();
        var doc = "";
        var access:Array<Access> = [];
        
        
        while (true) {
            if (match("public")) { next(); access.push(APublic); }
            else if (match("private")) { next(); access.push(APrivate); }
            else if (match("static")) { next(); access.push(AStatic); }
            else if (match("override")) { next(); access.push(AOverride); }
            else if (match("dynamic")) { next(); access.push(ADynamic); }
            else if (match("inline")) { next(); access.push(AInline); }
            else if (match("macro")) { next(); access.push(AMacro); }
            else if (match("final")) { next(); access.push(AFinal); }
            else if (match("extern")) { next(); access.push(AExtern); }
            else break;
        }

        var kind = "var";
        if (match("function")) {
            next();
            kind = "function";
        } else if (match("var")) {
            next();
            kind = "var";
        } else {
            
            
            kind = "var"; 
        }
        
        
        var name = "";
        if (match("new")) {
             name = "new";
             next();
        } else {
             name = consumeId();
        }

        var type:String = null;
        var methodInfo:MethodInfo = null;
        
        
        var methodParams = parseTypeParams();

        if (kind == "function" || (kind == "var" && match("("))) {
             
             kind = "function";
             methodInfo = parseMethodSignature();
        }

        
        if (match(":")) {
            next();
            type = parseComplexType();
            if (methodInfo != null) {
                methodInfo.ret = type;
            }
        }

        
        if (match("=")) {
            next();
            skipExpression();
        } else if (match("{") && kind == "function") {
            
            skipBlock();
        }
        
        if (match(";")) next();

        return {
            name: name,
            access: access,
            kind: kind,
            type: type,
            methodInfo: methodInfo,
            meta: meta,
            doc: doc,
            pos: 0
        };
    }

    function parseMethodSignature():MethodInfo {
        consume("(");
        var args:Array<ArgInfo> = [];
        if (!match(")")) {
            while (true) {
                var q = false;
                if (match("?")) {
                    next();
                    q = true;
                }
                var argName = consumeId();
                var argType = null;
                var val = null;
                
                if (match(":")) {
                    next();
                    argType = parseComplexType();
                }
                
                if (match("=")) {
                    next();
                    
                    val = captureExpression();
                }
                
                args.push({
                    name: argName,
                    type: argType,
                    optional: q,
                    value: val
                });

                if (match(",")) next();
                else break;
            }
        }
        consume(")");
        return {
            args: args,
            ret: "Void" 
        };
    }

    function parseMeta():Array<MetaInfo> {
        var metas:Array<MetaInfo> = [];
        while (match("@")) {
            next();
            var name = "";
            if (match(":")) { 
                next();
                name = ":" + consumeId();
            } else {
                name = consumeId();
            }
            
            var params:Array<String> = [];
            if (match("(")) {
                next();
                while (!match(")")) {
                    params.push(captureExpression());
                    if (match(",")) next();
                }
                consume(")");
            }
            metas.push({name: name, params: params, pos: 0});
        }
        return metas;
    }

    function parseTypeParams():Array<String> {
        if (match("<")) {
            var start = tokenIdx;
            next();
            
            var depth = 1;
            while (depth > 0 && peek() != TEof) {
                var t = next();
                switch(t) {
                    case TSymbol("<"): depth++;
                    case TSymbol(">"): depth--;
                    default:
                }
            }
            
            
            
            
            
            
            
            return ["TODO_GENERIC_PARAMS"]; 
        }
        return [];
    }
    
    
    function parseComplexType():String {
        
        
        
        
        
        var depthParen = 0;
        var depthAngle = 0;
        var depthBrace = 0;
        
        var parts:Array<String> = [];
        
        while (peek() != TEof) {
            var t = peek();
            var s = "";
            switch (t) {
                case TId(id): s = id;
                case TSymbol(sym): s = sym;
                case TString(str): s = '"' + str + '"'; 
                case TInt(i): s = i;
                case TFloat(f): s = f;
                default:
            }

            if (depthParen == 0 && depthAngle == 0 && depthBrace == 0) {
                 if (s == ";" || s == "=" || s == "{" || s == "," || s == "}" || s == ")") {
                      if (s == "{" && parts.length == 0) {
                           
                           
                      } else if (s == "->" && parts.length > 0) {
                           
                      } else {
                          break;
                      }
                 }
                 if (s == "implements" || s == "extends") break;
            }

            next();
            parts.push(s);

            if (s == "(") depthParen++;
            else if (s == ")") depthParen--;
            else if (s == "<") depthAngle++;
            else if (s == ">") depthAngle--;
            else if (s == "{") depthBrace++;
            else if (s == "}") depthBrace--;
        }
        
        return parts.join(" "); 
    }

    
    function skipBlock() {
        if (!match("{")) return;
        next();
        var depth = 1;
        while (depth > 0 && peek() != TEof) {
            var t = next();
            switch (t) {
                case TSymbol("{"): depth++;
                case TSymbol("}"): depth--;
                default:
            }
        }
    }

    
    
    function skipExpression() {
        var depthBrace = 0;
        var depthParen = 0;
        var depthBracket = 0;
        
        while (peek() != TEof) {
             if (depthBrace == 0 && depthParen == 0 && depthBracket == 0) {
                  if (match(";")) break;
             }
             
             var t = next();
             switch (t) {
                 case TSymbol("{"): depthBrace++;
                 case TSymbol("}"): depthBrace--;
                 case TSymbol("("): depthParen++;
                 case TSymbol(")"): depthParen--;
                 case TSymbol("["): depthBracket++;
                 case TSymbol("]"): depthBracket--;
                 default:
             }
        }
    }
    
    
    function captureExpression():String {
         var parts:Array<String> = [];
         var depthBrace = 0;
         var depthParen = 0;
         var depthBracket = 0;
         
         while (peek() != TEof) {
              if (depthBrace == 0 && depthParen == 0 && depthBracket == 0) {
                   if (match(",") || match(")")) break;
              }
              
              var t = peek();
              var s = "";
              switch (t) {
                  case TId(id): s = id;
                  case TSymbol(sym): s = sym;
                  case TString(str): s = '"' + str + '"';
                  case TInt(i): s = i;
                  case TFloat(f): s = f;
                  default:
              }
              
              next();
              parts.push(s);
              
              if (s == "{") depthBrace++;
              else if (s == "}") depthBrace--;
              else if (s == "(") depthParen++;
              else if (s == ")") depthParen--;
              else if (s == "[") depthBracket++;
              else if (s == "]") depthBracket--;
         }
         return parts.join(" ");
    }

}
