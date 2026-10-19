# Deployment & Export Guide — Yangon Frontline

## 1. Export Pipelines

### 1.1 Desktop Export (Windows x86_64)
- **Tooling:** Godot 4.7.2 CLI at `D:\Tools\Godot\godot.cmd`.
- **Template:** `windows_release_x86_64.exe` (located in self-contained templates on Drive D:).
- **Command:**
  ```powershell
  & "D:\Tools\Godot\godot.cmd" --headless --path "D:\Games\ygn frontier" --export-release "Windows Desktop" "D:\Games\ygn frontier\build\desktop\YangonFrontline.exe"
  ```

### 1.2 WebGL Browser Export (HTML5 / WebAssembly)
- **Tooling:** Godot Web Export Presets.
- **Template:** `web_release.zip` / `web_nothreads_release.zip`.
- **Command:**
  ```powershell
  & "D:\Tools\Godot\godot.cmd" --headless --path "D:\Games\ygn frontier" --export-release "Web" "D:\Games\ygn frontier\build\web\index.html"
  ```

---

## 2. Web Server Configuration & MIME Types
Modern browser engines mandate specific HTTP response headers for WebAssembly and SharedArrayBuffer:
```nginx
# Nginx Configuration
location / {
    root /var/www/yangon-frontline;
    index index.html;

    # Cross-Origin Isolation Headers (required for multi-threaded WASM if enabled)
    add_header Cross-Origin-Opener-Policy "same-origin";
    add_header Cross-Origin-Embedder-Policy "require-corp";

    types {
        text/html                             html;
        application/javascript               js;
        application/wasm                     wasm;
        application/octet-stream             pck;
        application/json                     json;
    }
}
```

---

## 3. Local Development Web Server
For instant local verification without complex server setups:
```powershell
# Using Node.js lightweight static server
npx serve -s "D:\Games\ygn frontier\build\web" -l 8080 --cors
```

---

## 4. Drive D: Hard Isolation Policy
All exported builds, intermediate objects, and packaging artifacts are placed in `D:\Games\ygn frontier\build\`. Under no circumstances are build directories mapped to Drive C:.
