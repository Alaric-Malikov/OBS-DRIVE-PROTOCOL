import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

// This simulator is for development only.
// In production builds, Vite replaces import.meta.env.PROD with `true`
// and tree-shakes App entirely — nothing is rendered or shipped.
if (!import.meta.env.PROD) {
  createRoot(document.getElementById("root")!).render(<App />);
}
