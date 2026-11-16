export {};
declare global {
  interface Window {
    puntoVuela: {
      platform: string;
      version: string;
      invoke(method: string, args?: unknown): Promise<any>;
    };
  }
}
