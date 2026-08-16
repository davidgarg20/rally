/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_RALLY_API_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
