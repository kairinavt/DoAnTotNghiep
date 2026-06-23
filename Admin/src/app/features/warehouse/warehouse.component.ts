import { Component, OnInit } from '@angular/core';
import { first } from 'rxjs';
import { IInventory, IStockHistory } from '../../models/warehouse.model';
import { WarehouseService } from './service/warehouse.service';
import { MessageService } from 'primeng/api';
import { ProductService } from '../product/service/product.service';
import { IProduct } from '../../models/product.model';

@Component({
  selector: 'app-warehouse',
  templateUrl: './warehouse.component.html',
  styleUrl: './warehouse.component.scss'
})
export class WarehouseComponent implements OnInit {
  inventory: IInventory[] = [];
  lowStock: IInventory[] = [];
  allProducts: IProduct[] = [];

  // Form nhập / xuất
  importQty: number = 0;
  exportQty: number = 0;
  note: string = '';
  selectedProductId: string = '';
  submitAttempted: boolean = false;

  // Form set ngưỡng cảnh báo
  minQtyProductId: string = '';
  minQtyValue: number = 0;

  // Lịch sử
  showHistory: boolean = false;
  stockHistory: IStockHistory[] = [];

  constructor(
    private warehouseService: WarehouseService,
    private toast: MessageService,
    private productService: ProductService
  ) {}

  ngOnInit(): void {
    this.loadWarehouseData();
    this.getAllProducts();
  }

  getAllProducts() {
    this.productService.getAllProduct({ cateIds: [] })
      .pipe(first())
      .subscribe({
        next: (value) => this.allProducts = value || []
      });
  }

  // Bỏ hoàn toàn selectedWarehouseId — không cần chọn kho
  loadWarehouseData() {
    this.warehouseService.getInventory()
      .pipe(first())
      .subscribe({ next: (value) => this.inventory = value || [] });

    this.warehouseService.getLowStock()
      .pipe(first())
      .subscribe({ next: (value) => this.lowStock = value || [] });
  }

  doImport() {
    this.submitAttempted = true;
    if (!this.selectedProductId || this.importQty <= 0) return;

    this.warehouseService.importStock({
      productId: this.selectedProductId,
      quantity: this.importQty,
      note: this.note
    }).pipe(first()).subscribe({
      next: () => {
        this.toast.add({ severity: 'success', summary: 'Thành công', detail: 'Nhập hàng thành công' });
        this.resetForm();
        this.loadWarehouseData();
        if (this.showHistory) this.loadHistory();
      },
      error: (err) => {
        this.toast.add({ severity: 'error', summary: 'Lỗi', detail: err?.error?.message || 'Nhập hàng thất bại' });
      }
    });
  }

  doExport() {
    this.submitAttempted = true;
    if (!this.selectedProductId || this.exportQty <= 0) return;

    this.warehouseService.exportStock({
      productId: this.selectedProductId,
      quantity: this.exportQty,
      note: this.note
    }).pipe(first()).subscribe({
      next: () => {
        this.toast.add({ severity: 'success', summary: 'Thành công', detail: 'Xuất hàng thành công' });
        this.resetForm();
        this.loadWarehouseData();
        if (this.showHistory) this.loadHistory();
      },
      error: (err) => {
        const msg = err?.error?.message || err?.error || 'Xuất hàng thất bại';
        this.toast.add({ severity: 'error', summary: 'Lỗi', detail: msg });
      }
    });
  }

  doSetMinQty() {
    if (!this.minQtyProductId || this.minQtyValue < 0) return;

    this.warehouseService.setMinQuantity(this.minQtyProductId, this.minQtyValue)
      .pipe(first())
      .subscribe({
        next: () => {
          this.toast.add({ severity: 'success', summary: 'Thành công', detail: 'Cập nhật ngưỡng cảnh báo thành công' });
          this.minQtyProductId = '';
          this.minQtyValue = 0;
          this.loadWarehouseData();
        },
        error: () => {
          this.toast.add({ severity: 'error', summary: 'Lỗi', detail: 'Cập nhật ngưỡng thất bại' });
        }
      });
  }

  toggleHistory() {
    this.showHistory = !this.showHistory;
    if (this.showHistory && !this.stockHistory.length) {
      this.loadHistory();
    }
  }

  loadHistory() {
    this.warehouseService.getStockHistory()
      .pipe(first())
      .subscribe({ next: (value) => this.stockHistory = value || [] });
  }

  private resetForm() {
    this.importQty = 0;
    this.exportQty = 0;
    this.note = '';
    this.selectedProductId = '';
    this.submitAttempted = false;
  }
}