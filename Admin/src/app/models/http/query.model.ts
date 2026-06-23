export interface IQueryData {
  controller: string;
  url: string;
  data?: any;
  params?: { [key: string]: any }; // Hoặc dùng kiểu: any hoặc HttpParams
}