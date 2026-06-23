export interface IWarehouse {
  _id?: string;
  name: string;
  address?: string;
}

export interface IInventory {
  _id?: string;
  productId: any; // populated IProduct
  warehouseId: any; // populated IWarehouse
  quantity: number;
  minQuantity: number;
}

export interface IStockHistory {
  _id?: string;
  productId: any;
  warehouseId: any;
  type: 'import' | 'export';
  quantity: number;
  note?: string;
  date: string;
}