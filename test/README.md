# FlowchartBuilder Demo

This demo shows how to instantiate the `FlowchartBuilder`.

## Building

Run the following command in this directory:

```bash
haxe build.hxml
```

## Running

The generated `demo.js` is intended for a Haxe JS target.

Since `FlowchartBuilder` relies on `js.node.Fs` to load UI resources (`flowchart.html`, `css`), this demo is best run in an Electron environment or a Node.js environment with DOM simulation.

However, `Demo.hx` includes a fallback that mocks the UI structure if `Fs` is not available, allowing you to open `index.html` in a standard web browser to see the basic initialization (though styles might be missing if not manually injected).

To view in browser:
Open `index.html` in your web browser.
