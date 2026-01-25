package history;

interface Transaction {
    function undo():Void;
    function redo():Void;
    function getLabel():String;
}
