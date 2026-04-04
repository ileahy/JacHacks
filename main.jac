import from typing { Any }
import from datetime { datetime }

node Memo {
    has title: str,
        audio_data: str,
        created_at: str = "";
}

def:pub save_memo(title: str, audio_data: str) -> Memo {
    memo = Memo(
        title=title,
        audio_data=audio_data,
        created_at=str(datetime.now())
    );
    root() ++> memo;
    return memo;
}

def:pub get_memos() -> list[Memo] {
    return [root()-->][?:Memo];
}

def:pub delete_memo(memo_id: str) -> bool {
    for m in [root()-->][?:Memo] {
        if jid(m) == memo_id {
            del m;
            return True;
        }
    }
    return False;
}

cl {
    glob _recorder: Any = None;

    def:pub app() -> JsxElement {
        has memos: list = [];
        has loading: bool = True;
        has recording: bool = False;
        has saving: bool = False;
        has title: str = "";
        has error: str = "";

        async can with entry {
            memos = await get_memos();
            loading = False;
        }

        async def do_save(audio_data: str) {
            saving = True;
            name = (title.strip() if title.strip() else "Voice Memo");
            memo = await save_memo(name, audio_data);
            memos = memos + [memo];
            title = "";
            saving = False;
        }

        async def start_rec() {
            error = "";
            nav: Any = navigator;
            stream: Any = await nav.mediaDevices.getUserMedia({"audio": True});
            rfl: Any = Reflect;
            MR: Any = MediaRecorder;
            rec: Any = rfl.construct(MR, [stream]);
            chunks: Any = [];

            rec.ondataavailable = lambda(e: Any) {
                if e.data and e.data.size > 0 {
                    chunks.push(e.data);
                }
            };

            rec.onstop = lambda {
                BlobCls: Any = Blob;
                FRCls: Any = FileReader;
                blob: Any = rfl.construct(BlobCls, [chunks, {"type": "audio/webm"}]);
                reader: Any = rfl.construct(FRCls, []);
                reader.onloadend = lambda {
                    do_save(reader.result);
                };
                reader.readAsDataURL(blob);
                tracks: Any = stream.getTracks();
                tracks.forEach(lambda(t: Any) { t.stop(); });
            };

            rec.start();
            _recorder = rec;
            recording = True;
        }

        def stop_rec() {
            if _recorder {
                rec: Any = _recorder;
                if rec.state != "inactive" {
                    rec.stop();
                }
                _recorder = None;
                recording = False;
            }
        }

        async def handle_delete(mid: str) {
            await delete_memo(mid);
            memos = [m for m in memos if jid(m) != mid];
        }

        if loading {
            return <div style={{"maxWidth": "600px", "margin": "40px auto", "fontFamily": "sans-serif"}}>
                <p>Loading...</p>
            </div>;
        }

        return <div style={{"maxWidth": "600px", "margin": "40px auto", "fontFamily": "sans-serif", "padding": "0 16px"}}>
            <h1 style={{"marginBottom": "4px"}}>Voice Memos</h1>
            {error and <p style={{"color": "red"}}>{error}</p>}
            {saving and <p style={{"color": "#888", "fontStyle": "italic"}}>Saving memo...</p>}
            <div style={{"marginBottom": "24px", "padding": "16px", "background": "#f9f9f9", "borderRadius": "8px"}}>
                <input
                    value={title}
                    onChange={lambda e: ChangeEvent { title = e.target.value; }}
                    placeholder="Memo title (optional)..."
                    style={{"width": "100%", "padding": "8px", "marginBottom": "12px", "boxSizing": "border-box"}}
                    disabled={recording or saving}
                />
                <div style={{"display": "flex", "alignItems": "center", "gap": "12px"}}>
                    {not recording and <button
                        onClick={lambda { start_rec(); }}
                        disabled={saving}
                        style={{"padding": "12px 28px", "background": "#e74c3c", "color": "white", "border": "none", "borderRadius": "50px", "cursor": "pointer", "fontSize": "15px"}}
                    >
                        Record
                    </button>}
                    {recording and <button
                        onClick={lambda { stop_rec(); }}
                        style={{"padding": "12px 28px", "background": "#333", "color": "white", "border": "none", "borderRadius": "50px", "cursor": "pointer", "fontSize": "15px"}}
                    >
                        Stop
                    </button>}
                    {recording and <span style={{"color": "#e74c3c", "fontWeight": "bold"}}>
                        Recording...
                    </span>}
                </div>
            </div>
            {not memos and <p style={{"color": "#aaa", "textAlign": "center"}}>No memos yet. Hit Record to start!</p>}
            <ul style={{"listStyle": "none", "padding": "0"}}>
                {[
                    <li
                        key={jid(m)}
                        style={{"padding": "14px", "marginBottom": "10px", "background": "#f5f5f5", "borderRadius": "8px"}}
                    >
                        <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "flex-start", "marginBottom": "8px"}}>
                            <div>
                                <strong>{m.title}</strong>
                                <p style={{"margin": "2px 0 0", "fontSize": "0.75em", "color": "#999"}}>{m.created_at}</p>
                            </div>
                            <button
                                onClick={lambda { handle_delete(jid(m)); }}
                                style={{"background": "none", "border": "none", "cursor": "pointer", "color": "#bbb", "fontSize": "18px"}}
                            >
                                x
                            </button>
                        </div>
                        <audio controls src={m.audio_data} style={{"width": "100%"}} />
                    </li>
                    for m in memos
                ]}
            </ul>
        </div>;
    }
}
