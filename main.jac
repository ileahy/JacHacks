import from byllm.llm { Model }

glob llm = Model(model_name="claude-sonnet-4-6");

node Todo {
    has title: str,
        done: bool = False,
        feedback: str = "";
}

"""Give one sentence of brief, encouraging feedback or a helpful tip for this todo task"""
def get_todo_feedback(title: str) -> str by llm();

def:pub add_todo(title: str) -> Todo {
    feedback = get_todo_feedback(title);
    new_todo = Todo(title=title, feedback=feedback);
    root() ++> new_todo;
    return new_todo;
}

def:pub get_todos() -> list[Todo] {
    return [root()-->][?:Todo];
}

def:pub toggle_todo(todo_id: str) -> Todo | None {
    for t in [root()-->][?:Todo] {
        if jid(t) == todo_id {
            t.done = not t.done;
            return t;
        }
    }
    return None;
}

cl {
    def:pub app() -> JsxElement {
        has todos: list[Todo] = [];
        has text: str = "";
        has loading: bool = True;
        has adding: bool = False;

        async can with entry {
            todos = await get_todos();
            loading = False;
        }

        async def handle_add() {
            if text.strip() {
                adding = True;
                todo = await add_todo(text.strip());
                todos = todos + [todo];
                text = "";
                adding = False;
            }
        }

        async def handle_toggle(tid: str) {
            updated = await toggle_todo(tid);
            if updated {
                todos = [updated if jid(t) == tid else t for t in todos];
            }
        }

        return <div style={{"maxWidth": "600px", "margin": "40px auto", "fontFamily": "sans-serif"}}>
            <h1>Jac Full-Stack Test</h1>
            <p style={{"color": "green"}}>
                If you can see this, your setup is working!
            </p>
            <div style={{"display": "flex", "gap": "8px", "marginBottom": "16px"}}>
                <input
                    value={text}
                    onChange={lambda e: ChangeEvent { text = e.target.value; }}
                    onKeyDown={lambda e: KeyboardEvent {
                        if e.key == "Enter" { handle_add(); }
                    }}
                    placeholder="Add a todo..."
                    style={{"flex": "1", "padding": "8px"}}
                    disabled={adding}
                />
                <button
                    onClick={lambda { handle_add(); }}
                    style={{"padding": "8px 16px"}}
                    disabled={adding}
                >
                    {("Adding..." if adding else "Add")}
                </button>
            </div>
            {loading and <p>Loading...</p>}
            <ul style={{"listStyle": "none", "padding": "0"}}>
                {[
                    <li
                        key={jid(t)}
                        style={{
                            "padding": "12px",
                            "marginBottom": "8px",
                            "background": "#f5f5f5",
                            "borderRadius": "4px"
                        }}
                    >
                        <div
                            style={{"display": "flex", "alignItems": "center", "gap": "8px", "cursor": "pointer"}}
                            onClick={lambda { handle_toggle(jid(t)); }}
                        >
                            <span style={{"textDecoration": ("line-through" if t.done else "none"), "fontWeight": "500"}}>
                                {t.title}
                            </span>
                        </div>
                        {t.feedback and <p style={{"margin": "6px 0 0 24px", "color": "#555", "fontSize": "0.9em", "fontStyle": "italic"}}>
                            Claude: {t.feedback}
                        </p>}
                    </li>
                    for t in todos
                ]}
            </ul>
        </div>;
    }
}
