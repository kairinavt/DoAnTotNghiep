import { Injectable } from '@angular/core';
import { HttpService } from '../../service/http.service';
import { IInventory, IStockHistory } from '../../../models/warehouse.model';

@Injectable({ providedIn: 'root' })
export class WarehouseService {
  constructor(private httpService: HttpService) {}

  // Bỏ warehouseId — không cần chọn kho nữa
  getInventory() {
    return this.httpService.get<IInventory[]>({
      controller: 'Warehouse', url: '/get-inventory'
    });
  }

  getLowStock() {
    return this.httpService.get<IInventory[]>({
      controller: 'Warehouse', url: '/get-low-stock'
    });
  }

  setMinQuantity(productId: string, minQuantity: number) {
    return this.httpService.put<IInventory>({
      controller: 'Warehouse', url: '/set-min-quantity',
      data: { productId, minQuantity }
    });
  }

  importStock(data: { productId: string; quantity: number; note?: string }) {
    return this.httpService.post<IInventory>({
      controller: 'Warehouse', url: '/import-stock', data
    });
  }

  exportStock(data: { productId: string; quantity: number; note?: string }) {
    return this.httpService.post<IInventory>({
      controller: 'Warehouse', url: '/export-stock', data
    });
  }

  getStockHistory(filter: any = {}) {
    return this.httpService.get<IStockHistory[]>({
      controller: 'Warehouse', url: '/get-stock-history', params: filter
    });
  }
}