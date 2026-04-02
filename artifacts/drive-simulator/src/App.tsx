import { useState, useCallback, useRef } from "react";

// ── Virtual File System ─────────────────────────────────────────────────────

type FSFile = { kind: "file"; name: string; size: number; content?: string; mime: string };
type FSDir  = { kind: "dir";  name: string; children: FSNode[] };
type FSNode = FSFile | FSDir;

const INITIAL_FS: FSDir = {
  kind: "dir", name: "root",
  children: [
    {
      kind: "dir", name: "launcher",
      children: [
        { kind: "file", name: "start.bat", size: 1842, mime: "text/plain", content: "@echo off\necho Starting Drive File Manager...\npython manage.py runserver 127.0.0.1:8000" },
        { kind: "file", name: "stop.bat", size: 312, mime: "text/plain", content: "@echo off\ntaskkill /f /im python.exe\necho Stopped." },
        { kind: "file", name: "install_deps.bat", size: 487, mime: "text/plain", content: "@echo off\npip install django\necho Done!" },
      ],
    },
    {
      kind: "dir", name: "app",
      children: [
        {
          kind: "dir", name: "filemanager",
          children: [
            { kind: "file", name: "manage.py", size: 690, mime: "text/plain", content: "#!/usr/bin/env python\nimport os, sys\n\ndef main():\n    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'filemanager.settings')\n    from django.core.management import execute_from_command_line\n    execute_from_command_line(sys.argv)\n\nif __name__ == '__main__':\n    main()" },
            { kind: "file", name: "requirements.txt", size: 22, mime: "text/plain", content: "django>=4.2,<5.2" },
          ],
        },
      ],
    },
    { kind: "file", name: "autorun.inf", size: 89, mime: "text/plain", content: "[autorun]\nopen=launcher\\start.bat\nicon=launcher\\icon.ico\nlabel=My Drive" },
    { kind: "file", name: "README.txt", size: 2048, mime: "text/plain", content: "Drive File Manager\n==================\nSee launcher\\start.bat to begin." },
  ],
};

function findNode(root: FSDir, path: string[]): FSNode | null {
  if (path.length === 0) return root;
  const [head, ...rest] = path;
  const child = root.children.find(c => c.name === head);
  if (!child) return null;
  if (rest.length === 0) return child;
  if (child.kind === "dir") return findNode(child, rest);
  return null;
}

function getDir(root: FSDir, path: string[]): FSDir | null {
  const node = findNode(root, path);
  return node?.kind === "dir" ? node : null;
}

function humanSize(n: number): string {
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / 1024 / 1024).toFixed(1)} MB`;
}

function fileIcon(mime: string, isDir: boolean): string {
  if (isDir) return "📁";
  if (mime.startsWith("image/")) return "🖼️";
  if (mime === "application/pdf") return "📄";
  if (mime.startsWith("video/")) return "🎬";
  if (mime.startsWith("audio/")) return "🎵";
  if (mime.startsWith("text/")) return "📝";
  return "📎";
}

function fileIconClass(mime: string, isDir: boolean): string {
  if (isDir) return "folder";
  if (mime.startsWith("image/")) return "image";
  if (mime === "application/pdf") return "pdf";
  if (mime.startsWith("video/")) return "video";
  if (mime.startsWith("audio/")) return "audio";
  if (mime.startsWith("text/")) return "text";
  return "other";
}

// ── Toast ────────────────────────────────────────────────────────────────────

type Toast = { id: number; msg: string; type: "success" | "error" | "info" };
let toastCounter = 0;

// ── Screens ──────────────────────────────────────────────────────────────────

type Screen = "desktop" | "autoplay" | "filemanager";

// ── Main App ─────────────────────────────────────────────────────────────────

export default function App() {
  const [screen, setScreen] = useState<Screen>("desktop");
  const [fs, setFs] = useState<FSDir>(INITIAL_FS);
  const [currentPath, setCurrentPath] = useState<string[]>([]);
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [toasts, setToasts] = useState<Toast[]>([]);

  // Modals
  const [renameTarget, setRenameTarget] = useState<{ path: string[]; name: string } | null>(null);
  const [renameValue, setRenameValue] = useState("");
  const [newFolderOpen, setNewFolderOpen] = useState(false);
  const [newFolderName, setNewFolderName] = useState("");
  const [previewNode, setPreviewNode] = useState<FSFile | null>(null);
  const [uploadOpen, setUploadOpen] = useState(false);
  const [pendingUploads, setPendingUploads] = useState<File[]>([]);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // ── Toast helpers ──────────────────────────────────────────────────────────
  const toast = useCallback((msg: string, type: Toast["type"] = "success") => {
    const id = ++toastCounter;
    setToasts(t => [...t, { id, msg, type }]);
    setTimeout(() => setToasts(t => t.filter(x => x.id !== id)), 3000);
  }, []);

  // ── FS helpers ─────────────────────────────────────────────────────────────
  const currentDir = getDir(fs, currentPath)!;

  const navigate = (name: string) => {
    setCurrentPath(p => [...p, name]);
    setSelected(new Set());
    setSearch("");
  };

  const goUp = () => {
    setCurrentPath(p => p.slice(0, -1));
    setSelected(new Set());
    setSearch("");
  };

  const goTo = (idx: number) => {
    setCurrentPath(p => p.slice(0, idx + 1));
    setSelected(new Set());
    setSearch("");
  };

  const mutateDir = (path: string[], fn: (dir: FSDir) => FSDir): FSDir => {
    if (path.length === 0) return fn(fs);
    const mutate = (node: FSDir, remaining: string[]): FSDir => {
      const [head, ...rest] = remaining;
      return {
        ...node,
        children: node.children.map(c => {
          if (c.name !== head) return c;
          if (c.kind !== "dir") return c;
          if (rest.length === 0) return fn(c);
          return mutate(c, rest);
        }),
      };
    };
    return mutate(fs, path);
  };

  const deleteNodes = (names: string[]) => {
    const nameSet = new Set(names);
    setFs(prev => mutateDir(currentPath, dir => ({
      ...dir,
      children: dir.children.filter(c => !nameSet.has(c.name)),
    })));
    setSelected(new Set());
    toast(`Deleted ${names.length} item(s)`);
  };

  const doRename = () => {
    if (!renameTarget || !renameValue.trim()) return;
    const newName = renameValue.trim();
    setFs(prev => mutateDir(renameTarget.path.slice(0, -1), dir => ({
      ...dir,
      children: dir.children.map(c =>
        c.name === renameTarget.name ? { ...c, name: newName } : c
      ),
    })));
    toast("Renamed successfully");
    setRenameTarget(null);
  };

  const doNewFolder = () => {
    if (!newFolderName.trim()) return;
    const name = newFolderName.trim();
    if (currentDir.children.some(c => c.name === name)) {
      toast("Folder already exists", "error"); return;
    }
    setFs(prev => mutateDir(currentPath, dir => ({
      ...dir,
      children: [...dir.children, { kind: "dir", name, children: [] }],
    })));
    toast("Folder created");
    setNewFolderOpen(false);
    setNewFolderName("");
  };

  const doUpload = () => {
    if (!pendingUploads.length) return;
    const newFiles: FSFile[] = pendingUploads.map(f => ({
      kind: "file",
      name: f.name,
      size: f.size,
      mime: f.type || "application/octet-stream",
    }));
    setFs(prev => mutateDir(currentPath, dir => ({
      ...dir,
      children: [...dir.children, ...newFiles],
    })));
    toast(`Uploaded ${newFiles.length} file(s)`);
    setUploadOpen(false);
    setPendingUploads([]);
  };

  // ── Filtered + sorted entries ──────────────────────────────────────────────
  const entries = currentDir.children.filter(c =>
    !search || c.name.toLowerCase().includes(search.toLowerCase())
  ).sort((a, b) => {
    if (a.kind !== b.kind) return a.kind === "dir" ? -1 : 1;
    return a.name.localeCompare(b.name);
  });

  // ── Toggle selection ───────────────────────────────────────────────────────
  const toggleSelect = (name: string) => {
    setSelected(prev => {
      const next = new Set(prev);
      next.has(name) ? next.delete(name) : next.add(name);
      return next;
    });
  };
  const toggleAll = (checked: boolean) => {
    setSelected(checked ? new Set(entries.map(e => e.name)) : new Set());
  };

  // ── Breadcrumbs ────────────────────────────────────────────────────────────
  const breadcrumbs = [
    { label: "E:\\", idx: -1 },
    ...currentPath.map((p, i) => ({ label: p, idx: i })),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP SCREEN
  // ══════════════════════════════════════════════════════════════════════════
  if (screen === "desktop") {
    return (
      <div style={{
        minHeight: "100vh", background: "linear-gradient(135deg, #1a237e 0%, #283593 50%, #1565c0 100%)",
        display: "flex", flexDirection: "column", fontFamily: "var(--app-font-sans)",
        position: "relative", overflow: "hidden",
      }}>
        {/* Wallpaper texture */}
        <div style={{ position: "absolute", inset: 0, opacity: 0.04,
          backgroundImage: "radial-gradient(circle at 1px 1px, white 1px, transparent 0)",
          backgroundSize: "32px 32px" }} />

        {/* Desktop icons area */}
        <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", gap: 16, position: "relative", zIndex: 1 }}>
          <p style={{ color: "rgba(255,255,255,0.5)", fontSize: 13, marginBottom: 24 }}>Windows Simulation — Test Environment</p>

          {/* USB Icon / plug-in button */}
          <button
            onClick={() => setScreen("autoplay")}
            style={{
              background: "rgba(255,255,255,0.1)", border: "2px solid rgba(255,255,255,0.3)",
              borderRadius: 16, padding: "32px 48px", cursor: "pointer",
              display: "flex", flexDirection: "column", alignItems: "center", gap: 16,
              color: "#fff", transition: "all 0.2s", backdropFilter: "blur(8px)",
            }}
            onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = "rgba(255,255,255,0.18)"; (e.currentTarget as HTMLButtonElement).style.transform = "translateY(-2px)"; }}
            onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = "rgba(255,255,255,0.1)"; (e.currentTarget as HTMLButtonElement).style.transform = "translateY(0)"; }}
          >
            <span style={{ fontSize: 64 }}>🔌</span>
            <span style={{ fontSize: 16, fontWeight: 600 }}>Plug in Thumb Drive</span>
            <span style={{ fontSize: 12, opacity: 0.7 }}>Click to simulate inserting the drive</span>
          </button>
        </div>

        {/* Windows taskbar */}
        <div style={{
          height: 40, background: "rgba(0,0,0,0.85)", backdropFilter: "blur(8px)",
          display: "flex", alignItems: "center", padding: "0 12px", gap: 8,
          borderTop: "1px solid rgba(255,255,255,0.08)", zIndex: 10,
        }}>
          <div style={{ background: "#0078d4", borderRadius: 4, padding: "4px 12px", fontSize: 13, color: "#fff", fontWeight: 600 }}>⊞</div>
          <div style={{ flex: 1 }} />
          <div style={{ color: "rgba(255,255,255,0.7)", fontSize: 12 }}>
            {new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
          </div>
        </div>
      </div>
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTOPLAY DIALOG
  // ══════════════════════════════════════════════════════════════════════════
  if (screen === "autoplay") {
    return (
      <div style={{
        minHeight: "100vh", background: "linear-gradient(135deg, #1a237e 0%, #283593 50%, #1565c0 100%)",
        display: "flex", flexDirection: "column", fontFamily: "var(--app-font-sans)",
        position: "relative", overflow: "hidden",
      }}>
        <div style={{ position: "absolute", inset: 0, opacity: 0.04,
          backgroundImage: "radial-gradient(circle at 1px 1px, white 1px, transparent 0)",
          backgroundSize: "32px 32px" }} />

        <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", position: "relative", zIndex: 1 }}>
          {/* AutoPlay dialog */}
          <div style={{
            background: "#f0f0f0", borderRadius: 8, width: 400, boxShadow: "0 20px 60px rgba(0,0,0,0.6)",
            overflow: "hidden", border: "1px solid #aaa", fontFamily: "'Segoe UI', sans-serif",
          }}>
            {/* Title bar */}
            <div style={{
              background: "linear-gradient(to bottom, #4a90d9, #2066b4)", padding: "6px 12px",
              display: "flex", alignItems: "center", gap: 8, color: "#fff",
            }}>
              <span style={{ fontSize: 14 }}>💿</span>
              <span style={{ fontSize: 13, fontWeight: 600, flex: 1 }}>AutoPlay</span>
              <button
                onClick={() => setScreen("desktop")}
                style={{ background: "rgba(255,255,255,0.2)", border: "none", color: "#fff", width: 18, height: 18, borderRadius: 2, cursor: "pointer", fontSize: 11, display: "flex", alignItems: "center", justifyContent: "center" }}
              >✕</button>
            </div>
            {/* Drive info */}
            <div style={{ padding: "12px 16px", borderBottom: "1px solid #ccc", display: "flex", alignItems: "center", gap: 12 }}>
              <span style={{ fontSize: 32 }}>🗄️</span>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: "#000" }}>My Drive (E:)</div>
                <div style={{ fontSize: 11, color: "#666" }}>Removable Disk</div>
              </div>
            </div>
            {/* Options */}
            <div style={{ padding: "8px 16px" }}>
              <div style={{ fontSize: 11, color: "#444", marginBottom: 8, fontWeight: 600 }}>What do you want Windows to do?</div>

              <button
                onClick={() => setScreen("filemanager")}
                style={{
                  width: "100%", padding: "10px 12px", background: "#fff", border: "2px solid #0078d4",
                  borderRadius: 4, display: "flex", alignItems: "center", gap: 12, cursor: "pointer",
                  marginBottom: 6, textAlign: "left",
                }}
              >
                <span style={{ fontSize: 24 }}>📂</span>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "#000" }}>Run program</div>
                  <div style={{ fontSize: 11, color: "#666" }}>Launch Drive File Manager</div>
                </div>
              </button>

              <button
                style={{
                  width: "100%", padding: "10px 12px", background: "#fff", border: "1px solid #ccc",
                  borderRadius: 4, display: "flex", alignItems: "center", gap: 12, cursor: "pointer",
                  marginBottom: 6, textAlign: "left",
                }}
              >
                <span style={{ fontSize: 24 }}>🗂️</span>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "#000" }}>Open folder to view files</div>
                  <div style={{ fontSize: 11, color: "#666" }}>using Windows Explorer</div>
                </div>
              </button>

              <button
                style={{
                  width: "100%", padding: "10px 12px", background: "#fff", border: "1px solid #ccc",
                  borderRadius: 4, display: "flex", alignItems: "center", gap: 12, cursor: "pointer",
                  textAlign: "left",
                }}
              >
                <span style={{ fontSize: 24 }}>🚫</span>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "#000" }}>Take no action</div>
                </div>
              </button>
            </div>
            <div style={{ padding: "8px 16px 12px", textAlign: "right", borderTop: "1px solid #e0e0e0" }}>
              <button
                onClick={() => setScreen("desktop")}
                style={{ padding: "4px 16px", background: "#e1e1e1", border: "1px solid #aaa", borderRadius: 3, cursor: "pointer", fontSize: 12 }}
              >Cancel</button>
            </div>
          </div>
        </div>

        {/* Windows taskbar */}
        <div style={{
          height: 40, background: "rgba(0,0,0,0.85)", backdropFilter: "blur(8px)",
          display: "flex", alignItems: "center", padding: "0 12px", gap: 8,
          borderTop: "1px solid rgba(255,255,255,0.08)", zIndex: 10,
        }}>
          <div style={{ background: "#0078d4", borderRadius: 4, padding: "4px 12px", fontSize: 13, color: "#fff", fontWeight: 600 }}>⊞</div>
          <div style={{ background: "rgba(255,255,255,0.1)", borderRadius: 4, padding: "4px 12px", fontSize: 12, color: "#fff" }}>💿 AutoPlay — My Drive (E:)</div>
          <div style={{ flex: 1 }} />
          <div style={{ color: "rgba(255,255,255,0.7)", fontSize: 12 }}>
            {new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
          </div>
        </div>
      </div>
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILE MANAGER SCREEN
  // ══════════════════════════════════════════════════════════════════════════
  return (
    <div style={{
      minHeight: "100vh", background: "#0f1117",
      display: "flex", flexDirection: "column",
      fontFamily: "var(--app-font-sans)", color: "#e8eaf6",
      position: "relative",
    }}>

      {/* ── Header ── */}
      <header style={{
        background: "#1a1d27", borderBottom: "1px solid #2e3248",
        padding: "0 24px", height: 56, display: "flex", alignItems: "center",
        gap: 16, position: "sticky", top: 0, zIndex: 100,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 17, fontWeight: 700, color: "#7c8cf8" }}>
          🗄️ Drive Browser <span style={{ fontSize: 12, color: "#7b82a8", fontWeight: 400 }}>— E:\</span>
        </div>

        {/* Search */}
        <div style={{ flex: 1, maxWidth: 360, position: "relative" }}>
          <span style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#7b82a8", fontSize: 13 }}>🔍</span>
          <input
            type="text"
            placeholder="Search in this folder…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            style={{
              width: "100%", background: "#22263a", border: "1px solid #2e3248",
              borderRadius: 20, padding: "7px 16px 7px 36px", color: "#e8eaf6",
              fontSize: 14, outline: "none", boxSizing: "border-box",
            }}
          />
        </div>

        <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 8 }}>
          {/* Replace the # below with your target URL when ready */}
          <a
            href="https://dbd1f9ab-ac3b-40fd-82a8-6c585b547c20-00-116alfcdzc3ss.riker.replit.dev/UnitDB"
            target="_blank"
            rel="noopener noreferrer"
            style={{ ...btnPrimary, textDecoration: "none" }}
          >🌐 Open Site</a>
          <button
            onClick={() => { setScreen("desktop"); setCurrentPath([]); setSelected(new Set()); }}
            style={{ background: "transparent", border: "1px solid #2e3248", borderRadius: 6, padding: "6px 12px", color: "#7b82a8", cursor: "pointer", fontSize: 12 }}
          >⏏ Eject Drive</button>
        </div>
      </header>

      {/* ── Breadcrumb ── */}
      <div style={{ padding: "10px 24px", display: "flex", alignItems: "center", gap: 6, fontSize: 13, color: "#7b82a8", flexWrap: "wrap" }}>
        {breadcrumbs.map((crumb, i) => (
          <span key={i} style={{ display: "flex", alignItems: "center", gap: 6 }}>
            {i > 0 && <span style={{ opacity: 0.5 }}>›</span>}
            {i < breadcrumbs.length - 1 ? (
              <button
                onClick={() => crumb.idx === -1 ? (setCurrentPath([]), setSelected(new Set()), setSearch("")) : goTo(crumb.idx)}
                style={{ background: "none", border: "none", color: "#7c8cf8", cursor: "pointer", fontSize: 13, padding: 0 }}
              >{crumb.label}</button>
            ) : (
              <span style={{ color: "#e8eaf6" }}>{crumb.label}</span>
            )}
          </span>
        ))}
      </div>

      {/* ── Toolbar ── */}
      <div style={{
        padding: "8px 24px", display: "flex", alignItems: "center", gap: 8,
        borderBottom: "1px solid #2e3248", flexWrap: "wrap",
      }}>
        {currentPath.length > 0 && (
          <button onClick={goUp} style={btnGhost}>← Back</button>
        )}
        <button onClick={() => { setNewFolderOpen(true); setNewFolderName(""); }} style={btnGhost}>📁 New Folder</button>
        <button onClick={() => { setUploadOpen(true); setPendingUploads([]); }} style={btnPrimary}>⬆ Upload</button>
        <button
          disabled={selected.size === 0}
          onClick={() => deleteNodes(Array.from(selected))}
          style={{ ...btnDanger, opacity: selected.size === 0 ? 0.4 : 1, pointerEvents: selected.size === 0 ? "none" : "auto" }}
        >🗑 Delete Selected</button>

        <span style={{ marginLeft: "auto", fontSize: 13, color: "#7b82a8" }}>
          {entries.length} item{entries.length !== 1 ? "s" : ""}{search ? ` matching "${search}"` : ""}
        </span>
      </div>

      {/* ── File Table ── */}
      <div style={{ padding: "0 24px 80px", overflowX: "auto", flex: 1 }}>
        {entries.length === 0 ? (
          <div style={{ textAlign: "center", padding: "80px 24px", color: "#7b82a8" }}>
            <div style={{ fontSize: 48, marginBottom: 16, opacity: 0.4 }}>📂</div>
            <p style={{ fontSize: 15, marginBottom: 8 }}>{search ? `No files matching "${search}"` : "This folder is empty"}</p>
            <p style={{ fontSize: 13 }}>Upload files or create a new folder to get started.</p>
          </div>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>
            <thead>
              <tr>
                <th style={thStyle}>
                  <input
                    type="checkbox"
                    checked={entries.length > 0 && selected.size === entries.length}
                    onChange={e => toggleAll(e.target.checked)}
                    style={{ accentColor: "#5b6ef5", width: 15, height: 15, cursor: "pointer" }}
                  />
                </th>
                <th style={{ ...thStyle, textAlign: "left", minWidth: 200 }}>Name</th>
                <th style={{ ...thStyle, textAlign: "right", width: 100 }}>Size</th>
                <th style={{ ...thStyle, textAlign: "right", width: 120 }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {entries.map(entry => {
                const isSelected = selected.has(entry.name);
                const mime = entry.kind === "file" ? entry.mime : "";
                return (
                  <tr
                    key={entry.name}
                    style={{
                      borderBottom: "1px solid rgba(255,255,255,0.04)",
                      background: isSelected ? "rgba(91,110,245,0.12)" : "transparent",
                      transition: "background 0.1s",
                    }}
                    onMouseEnter={e => { if (!isSelected) (e.currentTarget as HTMLTableRowElement).style.background = "rgba(91,110,245,0.06)"; }}
                    onMouseLeave={e => { if (!isSelected) (e.currentTarget as HTMLTableRowElement).style.background = "transparent"; }}
                  >
                    <td style={{ padding: "8px 12px", width: 36 }}>
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => toggleSelect(entry.name)}
                        style={{ accentColor: "#5b6ef5", width: 15, height: 15, cursor: "pointer" }}
                      />
                    </td>
                    <td style={{ padding: "8px 12px" }}>
                      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                        <span style={{
                          width: 32, height: 32, borderRadius: 6, display: "flex", alignItems: "center",
                          justifyContent: "center", fontSize: 18, flexShrink: 0,
                          background: entry.kind === "dir" ? "rgba(91,110,245,0.18)" : "rgba(127,127,127,0.12)",
                        }}>
                          {fileIcon(mime, entry.kind === "dir")}
                        </span>
                        {entry.kind === "dir" ? (
                          <button
                            onClick={() => navigate(entry.name)}
                            style={{ background: "none", border: "none", color: "#e8eaf6", cursor: "pointer", fontSize: 14, fontWeight: 500, padding: 0, textAlign: "left" }}
                            onMouseEnter={e => (e.currentTarget as HTMLButtonElement).style.color = "#7c8cf8"}
                            onMouseLeave={e => (e.currentTarget as HTMLButtonElement).style.color = "#e8eaf6"}
                          >{entry.name}</button>
                        ) : (
                          <button
                            onClick={() => entry.kind === "file" && setPreviewNode(entry as FSFile)}
                            style={{ background: "none", border: "none", color: "#e8eaf6", cursor: "pointer", fontSize: 14, fontWeight: 500, padding: 0, textAlign: "left" }}
                            onMouseEnter={e => (e.currentTarget as HTMLButtonElement).style.color = "#7c8cf8"}
                            onMouseLeave={e => (e.currentTarget as HTMLButtonElement).style.color = "#e8eaf6"}
                          >{entry.name}</button>
                        )}
                      </div>
                    </td>
                    <td style={{ padding: "8px 12px", textAlign: "right", color: "#7b82a8", fontSize: 13 }}>
                      {entry.kind === "file" ? humanSize(entry.size) : ""}
                    </td>
                    <td style={{ padding: "8px 12px", textAlign: "right" }}>
                      <div style={{ display: "flex", gap: 4, justifyContent: "flex-end" }}>
                        {entry.kind === "file" && (
                          <IconBtn title="Preview" onClick={() => entry.kind === "file" && setPreviewNode(entry as FSFile)}>👁</IconBtn>
                        )}
                        <IconBtn title="Rename" onClick={() => {
                          setRenameTarget({ path: [...currentPath, entry.name], name: entry.name });
                          setRenameValue(entry.name);
                        }}>✏️</IconBtn>
                        <IconBtn title="Delete" danger onClick={() => deleteNodes([entry.name])}>🗑</IconBtn>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* ── New Folder Modal ── */}
      {newFolderOpen && (
        <Modal title="New Folder" onClose={() => setNewFolderOpen(false)}>
          <input
            autoFocus
            type="text"
            placeholder="Folder name…"
            value={newFolderName}
            onChange={e => setNewFolderName(e.target.value)}
            onKeyDown={e => e.key === "Enter" && doNewFolder()}
            style={inputStyle}
          />
          <ModalActions>
            <button onClick={() => setNewFolderOpen(false)} style={btnGhost}>Cancel</button>
            <button onClick={doNewFolder} style={btnPrimary}>Create</button>
          </ModalActions>
        </Modal>
      )}

      {/* ── Rename Modal ── */}
      {renameTarget && (
        <Modal title="Rename" onClose={() => setRenameTarget(null)}>
          <input
            autoFocus
            type="text"
            value={renameValue}
            onChange={e => setRenameValue(e.target.value)}
            onKeyDown={e => e.key === "Enter" && doRename()}
            style={inputStyle}
          />
          <ModalActions>
            <button onClick={() => setRenameTarget(null)} style={btnGhost}>Cancel</button>
            <button onClick={doRename} style={btnPrimary}>Rename</button>
          </ModalActions>
        </Modal>
      )}

      {/* ── Upload Modal ── */}
      {uploadOpen && (
        <Modal title="Upload Files" onClose={() => setUploadOpen(false)}>
          <div
            onClick={() => fileInputRef.current?.click()}
            onDragOver={e => e.preventDefault()}
            onDrop={e => { e.preventDefault(); setPendingUploads(Array.from(e.dataTransfer.files)); }}
            style={{
              border: "2px dashed #2e3248", borderRadius: 8, padding: 32, textAlign: "center",
              cursor: "pointer", marginBottom: 16, color: "#7b82a8", transition: "border-color 0.15s",
            }}
            onMouseEnter={e => (e.currentTarget as HTMLDivElement).style.borderColor = "#5b6ef5"}
            onMouseLeave={e => (e.currentTarget as HTMLDivElement).style.borderColor = "#2e3248"}
          >
            <div style={{ fontSize: 32, marginBottom: 8 }}>⬆️</div>
            <p style={{ fontSize: 14 }}>Click or drag & drop files here</p>
          </div>
          <input
            ref={fileInputRef} type="file" multiple style={{ display: "none" }}
            onChange={e => setPendingUploads(Array.from(e.target.files ?? []))}
          />
          {pendingUploads.length > 0 && (
            <ul style={{ listStyle: "none", marginBottom: 12, maxHeight: 120, overflowY: "auto" }}>
              {pendingUploads.map((f, i) => (
                <li key={i} style={{ fontSize: 13, color: "#7b82a8", padding: "3px 0", display: "flex", justifyContent: "space-between" }}>
                  <span>{f.name}</span><span>{humanSize(f.size)}</span>
                </li>
              ))}
            </ul>
          )}
          <ModalActions>
            <button onClick={() => setUploadOpen(false)} style={btnGhost}>Close</button>
            <button onClick={doUpload} disabled={!pendingUploads.length} style={{ ...btnPrimary, opacity: pendingUploads.length ? 1 : 0.5 }}>
              Upload {pendingUploads.length > 0 ? `(${pendingUploads.length})` : ""}
            </button>
          </ModalActions>
        </Modal>
      )}

      {/* ── Preview Modal ── */}
      {previewNode && (
        <Modal title={previewNode.name} onClose={() => setPreviewNode(null)} wide>
          <div style={{ maxHeight: "60vh", overflow: "auto", marginBottom: 16, textAlign: "center" }}>
            {previewNode.mime.startsWith("text/") && previewNode.content ? (
              <pre style={{
                textAlign: "left", background: "#0f1117", borderRadius: 6, padding: 16,
                fontSize: 13, fontFamily: "monospace", whiteSpace: "pre-wrap", wordBreak: "break-all",
                color: "#e8eaf6", maxHeight: "55vh", overflowY: "auto",
              }}>{previewNode.content}</pre>
            ) : previewNode.mime.startsWith("image/") ? (
              <p style={{ color: "#7b82a8", padding: 32 }}>🖼️ Image preview (not available in simulator)</p>
            ) : (
              <p style={{ color: "#7b82a8", padding: 32 }}>Preview not available for this file type.</p>
            )}
          </div>
          <ModalActions>
            <button onClick={() => setPreviewNode(null)} style={btnGhost}>Close</button>
          </ModalActions>
        </Modal>
      )}

      {/* ── Toasts ── */}
      <div style={{ position: "fixed", bottom: 24, right: 24, display: "flex", flexDirection: "column", gap: 8, zIndex: 999 }}>
        {toasts.map(t => (
          <div key={t.id} style={{
            background: "#22263a", border: `1px solid ${t.type === "error" ? "#e05c5c" : t.type === "success" ? "#4caf7d" : "#2e3248"}`,
            borderRadius: 8, padding: "10px 16px", fontSize: 13, maxWidth: 300,
            color: t.type === "error" ? "#e05c5c" : t.type === "success" ? "#4caf7d" : "#e8eaf6",
            animation: "slideIn 0.2s ease",
          }}>{t.msg}</div>
        ))}
      </div>

      <style>{`@keyframes slideIn { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: translateY(0); } }`}</style>
    </div>
  );
}

// ── Reusable UI bits ──────────────────────────────────────────────────────────

function Modal({ title, children, onClose, wide }: { title: string; children: React.ReactNode; onClose: () => void; wide?: boolean }) {
  return (
    <div
      onClick={e => { if (e.target === e.currentTarget) onClose(); }}
      style={{
        position: "fixed", inset: 0, background: "rgba(0,0,0,0.6)", backdropFilter: "blur(3px)",
        zIndex: 500, display: "flex", alignItems: "center", justifyContent: "center",
      }}
    >
      <div style={{
        background: "#1a1d27", border: "1px solid #2e3248", borderRadius: 12,
        padding: 28, width: wide ? 640 : 380, maxWidth: "90%",
      }}>
        <h3 style={{ fontSize: 17, marginBottom: 16, color: "#e8eaf6", wordBreak: "break-all" }}>{title}</h3>
        {children}
      </div>
    </div>
  );
}

function ModalActions({ children }: { children: React.ReactNode }) {
  return <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>{children}</div>;
}

function IconBtn({ children, title, onClick, danger }: { children: React.ReactNode; title?: string; onClick?: () => void; danger?: boolean }) {
  return (
    <button
      title={title}
      onClick={onClick}
      style={{
        width: 28, height: 28, borderRadius: 6, border: "none", background: "transparent",
        color: "#7b82a8", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: 14, transition: "background 0.12s, color 0.12s",
      }}
      onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = danger ? "rgba(224,92,92,0.15)" : "#22263a"; (e.currentTarget as HTMLButtonElement).style.color = danger ? "#e05c5c" : "#e8eaf6"; }}
      onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = "transparent"; (e.currentTarget as HTMLButtonElement).style.color = "#7b82a8"; }}
    >{children}</button>
  );
}

// ── Shared styles ──────────────────────────────────────────────────────────────
const btnBase: React.CSSProperties = {
  display: "inline-flex", alignItems: "center", gap: 6, padding: "7px 14px",
  borderRadius: 8, fontSize: 13, fontWeight: 500, cursor: "pointer", border: "1px solid transparent",
  transition: "background 0.15s",
};
const btnPrimary: React.CSSProperties = { ...btnBase, background: "#5b6ef5", color: "#fff" };
const btnGhost: React.CSSProperties = { ...btnBase, background: "transparent", color: "#7b82a8", borderColor: "#2e3248" };
const btnDanger: React.CSSProperties = { ...btnBase, background: "transparent", color: "#e05c5c", borderColor: "#e05c5c" };
const thStyle: React.CSSProperties = {
  padding: "10px 12px", fontSize: 12, fontWeight: 600, textTransform: "uppercase",
  letterSpacing: "0.06em", color: "#7b82a8", borderBottom: "1px solid #2e3248",
  whiteSpace: "nowrap", textAlign: "left",
};
const inputStyle: React.CSSProperties = {
  width: "100%", background: "#22263a", border: "1px solid #2e3248", borderRadius: 8,
  padding: "9px 12px", color: "#e8eaf6", fontSize: 14, outline: "none",
  marginBottom: 16, boxSizing: "border-box",
};
