package ui;

import js.Browser;
import js.html.Element;
import js.html.InputElement;
import js.html.DragEvent;
import model.NodeTemplate;

class PaletteView {
    var container:Element;
    var templates:Array<NodeTemplate>;
    
    var currentCategory:String = "Common";
    var searchQuery:String = "";
    
    var headerContainer:Element;
    var searchInput:InputElement;
    var listContainer:Element;

    public function new(containerId:String, templates:Array<NodeTemplate>) {
        this.container = Browser.document.getElementById(containerId);
        this.templates = templates;
        
        // Inject styles
        injectStyles();
        
        renderStructure();
        refresh();
    }
    
    function injectStyles() {
        var styleId = "palette-view-styles";
        if (Browser.document.getElementById(styleId) != null) return;

        var style = Browser.document.createStyleElement();
        style.id = styleId;
        style.textContent = "
            .palette-header {
                display: flex;
                flex-wrap: wrap;
                background-color: #252526;
                border-bottom: 1px solid #3e3e42;
                padding: 5px;
            }
            .palette-tab {
                padding: 5px 10px;
                cursor: pointer;
                color: #888;
                font-size: 0.9em;
                border-bottom: 2px solid transparent;
                user-select: none;
            }
            .palette-tab:hover {
                color: #ccc;
            }
            .palette-tab.active {
                color: white;
                border-bottom-color: #007acc;
            }
            .palette-search {
                padding: 8px;
                border-bottom: 1px solid #3e3e42;
            }
            .palette-search input {
                width: 100%;
                background-color: #333;
                border: 1px solid #3e3e42;
                color: white;
                padding: 6px;
                border-radius: 2px;
                box-sizing: border-box;
            }
            .palette-list {
                padding: 10px;
                overflow-y: auto;
                flex: 1;
            }
            .palette-item {
                background-color: #333;
                border: 1px solid #3e3e42;
                padding: 10px;
                margin-bottom: 8px;
                border-radius: 4px;
                cursor: grab;
                transition: background-color 0.2s;
                user-select: none;
            }
            .palette-item:hover {
                background-color: #3c3c3c;
                border-color: #007acc;
            }
        ";
        Browser.document.head.appendChild(style);
    }
    
    function renderStructure() {
        container.innerHTML = "";
        container.style.display = "flex";
        container.style.flexDirection = "column";
        container.style.height = "100%";
        
        headerContainer = Browser.document.createDivElement();
        headerContainer.className = "palette-header";
        container.appendChild(headerContainer);
        
        var searchContainer = Browser.document.createDivElement();
        searchContainer.className = "palette-search";
        
        searchInput = Browser.document.createInputElement();
        searchInput.type = "text";
        searchInput.placeholder = "Search Nodes...";
        searchInput.oninput = function(e) {
            searchQuery = searchInput.value.toLowerCase();
            refresh();
        };
        searchContainer.appendChild(searchInput);
        container.appendChild(searchContainer);
        
        listContainer = Browser.document.createDivElement();
        listContainer.className = "palette-list";
        container.appendChild(listContainer);
    }

    public function refresh() {
        renderHeader();
        renderList();
    }
    
    function renderHeader() {
        headerContainer.innerHTML = "";
        
        // Get all unique categories
        var categories = new Map<String, Bool>();
        
        for (t in templates) {
            var cat = t.category != null ? t.category : "Common";
            categories.set(cat, true);
        }
        
        var categoryList = [];
        for (c in categories.keys()) categoryList.push(c);
        categoryList.sort(function(a, b) return Reflect.compare(a, b));
        
        // Ensure "Common" is first if it exists
        if (categories.exists("Common")) {
            categoryList.remove("Common");
            categoryList.unshift("Common");
        }
        
        // Auto-select first category if current is invalid
        var categoryExists = false;
        for (c in categoryList) {
            if (c == currentCategory) {
                categoryExists = true;
                break;
            }
        }
        
        if (!categoryExists && categoryList.length > 0) {
            currentCategory = categoryList[0];
        }

        for (c in categoryList) {
            var tab = Browser.document.createDivElement();
            tab.className = "palette-tab" + (c == currentCategory ? " active" : "");
            tab.innerText = c;
            tab.onclick = function() {
                currentCategory = c;
                refresh();
            };
            headerContainer.appendChild(tab);
        }
    }

    function renderList() {
        listContainer.innerHTML = "";
        
        // Sort by name
        templates.sort(function(a, b) return Reflect.compare(a.name, b.name));
        
        var count = 0;
        
        for (t in templates) {
            var cat = t.category != null ? t.category : "Common";

            // Filter by search
            if (searchQuery.length > 0) {
                if (t.name.toLowerCase().indexOf(searchQuery) == -1) continue;
            } else {
                // Filter by category (only if not searching)
                if (cat != currentCategory) continue;
            }
            
            var div = Browser.document.createDivElement();
            div.className = "palette-item";
            div.innerText = t.name;
            div.draggable = true;
            
            div.addEventListener('dragstart', function(e:DragEvent) {
                e.dataTransfer.setData("templateName", t.name);
            });
            
            listContainer.appendChild(div);
            count++;
        }
        
        if (count == 0) {
            var empty = Browser.document.createDivElement();
            empty.style.color = "#888";
            empty.style.textAlign = "center";
            empty.style.padding = "20px";
            empty.innerText = "No nodes found";
            listContainer.appendChild(empty);
        }
    }
}
