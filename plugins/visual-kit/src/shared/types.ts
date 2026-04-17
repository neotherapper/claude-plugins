export type SurfaceKind =
  | 'lesson' | 'gallery' | 'outline' | 'comparison' | 'feedback' | 'free';

export interface SurfaceSpecBase {
  surface: SurfaceKind;
  version: number;
}

export interface ServerInfo {
  status: 'running';
  pid: number;
  port: number;
  host: string;
  url: string;
  started_at: string; // ISO 8601
  project_dir: string;
  visual_kit_version: string;
}

export interface VkEvent {
  type: string;
  ts: string;
  [key: string]: unknown;
}
