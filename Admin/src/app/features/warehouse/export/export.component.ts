import { Component, OnInit } from '@angular/core';
import { first } from 'rxjs';
import { IInventory, IStockHistory } from '../../../models/warehouse.model';
import { WarehouseService } from '../service/warehouse.service';
import { MessageService } from 'primeng/api';
import { ProductService } from '../../product/service/product.service';
import { IProduct } from '../../../models/product.model';

@Component({
  selector: 'app-export',
  templateUrl: './export.component.html',
  styleUrl: './export.component.scss'
})
export class ExportComponent implements OnInit {
  inventory: IInventory[] = [];
  allProducts: IProduct[] = [];
  stockHistory: IStockHistory[] = [];

  // Form xuất hàng
  selectedProductId: string = '';
  exportQty: number = 0;
  note: string = '';
  submitAttempted: boolean = false;

  constructor(
    private warehouseService: WarehouseService,
    private toast: MessageService,
    private productService: ProductService
  ) {}

  ngOnInit(): void {
    this.loadData();
  }

  loadData() {
    this.warehouseService.getInventory()
      .pipe(first())
      .subscribe({ next: (value) => this.inventory = value || [] });

    this.productService.getAllProduct({ cateIds: [] })
      .pipe(first())
      .subscribe({ next: (value) => this.allProducts = value || [] });

    this.loadHistory();
  }

  loadHistory() {
    this.warehouseService.getStockHistory()
      .pipe(first())
      .subscribe({
        next: (value) => {
          // Chỉ lấy lịch sử loại 'export'
          this.stockHistory = (value || []).filter(h => h.type === 'export');
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
        this.loadData();
      },
      error: (err) => {
        const msg = err?.error?.message || err?.error || 'Xuất hàng thất bại';
        this.toast.add({ severity: 'error', summary: 'Lỗi', detail: msg });
      }
    });
  }

  private resetForm() {
    this.selectedProductId = '';
    this.exportQty = 0;
    this.note = '';
    this.submitAttempted = false;
  }

  formatPrice(price: number): string {
    return price.toLocaleString('vi-VN') + ' đ';
  }

  getStockStatus(item: IInventory): 'danger' | 'warning' | 'success' {
    if (item.quantity === 0) return 'danger';
    if (item.quantity <= item.minQuantity) return 'warning';
    return 'success';
  }
}