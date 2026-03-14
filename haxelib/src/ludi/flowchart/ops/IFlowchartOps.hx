package ludi.flowchart.ops;

import ludi.flowchart.model.Graph;
import ludi.flowchart.model.FlowchartNode;
import ludi.flowchart.model.FlowchartConnection;
import ludi.flowchart.model.Note;
import ludi.flowchart.model.NodeTemplate;

interface IFlowchartOps {
    /**
     * Tries to load a text file from the given path.
     * Used for loading UI templates (html/css).
     * @param path The absolute path to the file.
     * @return The file content or null if not found/error.
     */
    function tryLoadText(path:String):Null<String>;

    /**
     * Checks if a file exists at the given path.
     * @param path The absolute path to the file.
     * @return True if exists.
     */
    function exists(path:String):Bool;

    /**
     * Saves the flowchart data.
     * @param graph The flowchart graph.
     * @param notes The list of notes.
     * @param onComplete Optional callback when save is done.
     */
    function saveFlowchart(graph:Graph<FlowchartNode, FlowchartConnection>, notes:Array<Note>, ?onComplete:Void->Void):Void;

    /**
     * Requests to load a flowchart.
     * This usually triggers a file picker or similar UI.
     * @param templates The available node templates (needed for reconstruction).
     * @param onLoaded Callback with the loaded graph and notes.
     */
    function requestLoadFlowchart(templates:Array<NodeTemplate>, onLoaded:(Graph<FlowchartNode, FlowchartConnection>, Array<Note>)->Void):Void;
}
