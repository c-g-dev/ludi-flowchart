package history;

import ui.Toast;

class TransactionManager {
    var undoStack:Array<Transaction>;
    var redoStack:Array<Transaction>;
    var isExecuting:Bool;

    public function new() {
        undoStack = [];
        redoStack = [];
        isExecuting = false;
    }

    public function add(transaction:Transaction) {
        if (isExecuting) return;
        
        undoStack.push(transaction);
        redoStack = []; // Clear redo stack on new action
        
        // Execute the action immediately?
        // Usually, the action is performed by the caller, then added here.
        // Or we pass a transaction that has already executed.
        // Let's assume the transaction captures the state *after* the change, 
        // or encapsulates the change itself.
        // Better pattern: Action is performed -> Transaction created -> Added to manager.
        // OR: Manager.execute(transaction) which calls redo() (do).
        
        // We will assume "do" happened, so we just add it.
        // But for consistency, let's say "add" assumes it's done.
    }
    
    public function execute(transaction:Transaction) {
        isExecuting = true;
        transaction.redo();
        isExecuting = false;
        undoStack.push(transaction);
        redoStack = [];
    }

    public function undo() {
        if (undoStack.length == 0) return;
        
        var transaction = undoStack.pop();
        isExecuting = true;
        transaction.undo();
        isExecuting = false;
        redoStack.push(transaction);
        
        Toast.show("Undo: " + transaction.getLabel());
    }

    public function redo() {
        if (redoStack.length == 0) return;
        
        var transaction = redoStack.pop();
        isExecuting = true;
        transaction.redo();
        isExecuting = false;
        undoStack.push(transaction);
        
        Toast.show("Redo: " + transaction.getLabel());
    }
}
