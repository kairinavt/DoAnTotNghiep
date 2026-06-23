import { Component, OnInit } from '@angular/core';
import { first, forkJoin } from 'rxjs';
import { IInvoice } from '../../models/invoices.model';
import { IProduct } from '../../models/product.model';
import { IInventory } from '../../models/warehouse.model';
import { InvoiceService } from '../invoice/service/invoice.service';
import { ProductService } from '../product/service/product.service';
import { WarehouseService } from '../warehouse/service/warehouse.service';

interface ITopProduct {
  name: string;
  img: string;
  totalQty: number;
  totalRevenue: number;
}

// Mở rộng IInvoice với các field tổng hợp dùng để hiển thị ở bảng "Đơn hàng gần đây"
interface IRecentOrder extends IInvoice {
  dateDisplay?: string;
  totalQty?: number;
  totalPrice?: number;
}

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  loading = true;

  // Thẻ tóm tắt
  totalRevenue = 0;
  totalOrders = 0;
  cancelledOrders = 0;
  totalProducts = 0;
  lowStockCount = 0;

  // Biểu đồ doanh thu 7 ngày
  revenueChartData: { date: string; revenue: number }[] = [];

  // Top sản phẩm bán chạy
  topProducts: ITopProduct[] = [];

  // Tồn kho thấp
  lowStockItems: IInventory[] = [];

  // Đơn hàng gần đây
  recentOrders: IRecentOrder[] = [];

  constructor(
    private invoiceService: InvoiceService,
    private productService: ProductService,
    private warehouseService: WarehouseService
  ) {}

  ngOnInit(): void {
    forkJoin({
      invoices: this.invoiceService.getInvoice(),
      products: this.productService.getAllProduct({ cateIds: [] }),
      inventory: this.warehouseService.getInventory(),
      lowStock: this.warehouseService.getLowStock()
    }).pipe(first()).subscribe({
      next: ({ invoices, products, inventory, lowStock }) => {
        this.loading = false;
        this.processInvoices(invoices || []);
        this.processProducts(products || [], invoices || []);
        this.lowStockCount = (lowStock || []).length;
        this.lowStockItems = (lowStock || []).slice(0, 5);
        this.totalProducts = (products || []).length;
      },
      error: () => { this.loading = false; }
    });
  }

  processInvoices(invoices: IInvoice[]) {
    const completed = invoices.filter(i => i.status === 'completed');
    const cancelled = invoices.filter(i => i.status === 'cancelled');

    this.totalOrders = invoices.length;
    this.cancelledOrders = cancelled.length;
    this.totalRevenue = completed.reduce((sum, inv) =>
      sum + (inv.details?.reduce((s, d) => s + d.quantity * d.price, 0) ?? 0), 0);

    // Đơn hàng gần đây nhất (5 cái), bổ sung các field tổng hợp để hiển thị
    this.recentOrders = [...invoices].slice(-5).reverse().map(inv => this.toRecentOrder(inv));

    // Doanh thu 7 ngày gần nhất (chỉ tính completed)
    this.revenueChartData = this.buildRevenueChart(completed);
  }

  /** Bổ sung field tổng hợp (ngày hiển thị, tổng số món, tổng tiền) cho 1 hóa đơn để hiển thị ở bảng đơn hàng gần đây */
  private toRecentOrder(inv: IInvoice): IRecentOrder {
    const totalQty = inv.details?.reduce((s, d) => s + d.quantity, 0) ?? 0;
    const totalPrice = inv.details?.reduce((s, d) => s + d.quantity * d.price, 0) ?? 0;
    const rawDate = inv.details?.[0]?.date ?? '';
    return {
      ...inv,
      dateDisplay: rawDate || '—',
      totalQty,
      totalPrice
    };
  }

  buildRevenueChart(invoices: IInvoice[]): { date: string; revenue: number }[] {
    const days: { date: string; revenue: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const label = `${d.getDate()}/${d.getMonth() + 1}`;

      const revenue = invoices
        .filter(inv => {
          const pd = this.parseDate(inv.details?.[0]?.date ?? '');
          return pd
            && pd.getDate() === d.getDate()
            && pd.getMonth() === d.getMonth()
            && pd.getFullYear() === d.getFullYear();
        })
        .reduce((sum, inv) =>
          sum + (inv.details?.reduce((s, dt) => s + dt.quantity * dt.price, 0) ?? 0), 0);

      days.push({ date: label, revenue });
    }
    return days;
  }

  /** Parse chuỗi ngày dạng "dd-mm-yyyy" (định dạng thực tế của dữ liệu) hoặc "dd/mm/yyyy" thành Date */
  private parseDate(raw: string): Date | null {
    if (!raw) return null;
    const parts = raw.includes('-') ? raw.split('-') : raw.split('/');
    if (parts.length >= 2) {
      return new Date(
        parts.length === 3 ? +parts[2] : new Date().getFullYear(),
        +parts[1] - 1,
        +parts[0]
      );
    }
    const d = new Date(raw);
    return isNaN(d.getTime()) ? null : d;
  }

  processProducts(products: IProduct[], invoices: IInvoice[]) {
    const map = new Map<string, ITopProduct>();

    for (const inv of invoices.filter(i => i.status === 'completed')) {
      for (const d of inv.details || []) {
        const id = d.productId;
        const existing = map.get(id);
        if (existing) {
          existing.totalQty += d.quantity;
          existing.totalRevenue += d.quantity * d.price;
        } else {
          map.set(id, {
            name: d.product?.nameProduct ?? 'Sản phẩm',
            img: d.product?.img ?? '',
            totalQty: d.quantity,
            totalRevenue: d.quantity * d.price
          });
        }
      }
    }

    this.topProducts = Array.from(map.values())
      .sort((a, b) => b.totalQty - a.totalQty)
      .slice(0, 5);
  }

  formatPrice(price: number): string {
    return price.toLocaleString('vi-VN') + ' đ';
  }

  getOrderStatus(inv: IInvoice): string {
    if (inv.status === 'cancelled') return 'Đã hủy';
    if (inv.status === 'completed') return 'Hoàn thành';
    return 'Đang hoạt động';
  }

  getOrderStatusClass(inv: IInvoice): string {
    if (inv.status === 'cancelled') return 'bg-secondary';
    if (inv.status === 'completed') return 'bg-success';
    return 'bg-primary';
  }

  maxRevenue(): number {
    return Math.max(...this.revenueChartData.map(d => d.revenue), 1);
  }
}