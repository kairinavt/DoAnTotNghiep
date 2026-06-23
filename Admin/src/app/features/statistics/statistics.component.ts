import { Component, OnInit } from '@angular/core';
import { first, forkJoin } from 'rxjs';
import { IInvoice } from '../../models/invoices.model';
import { InvoiceService } from '../invoice/service/invoice.service';
import { ProductService } from '../product/service/product.service';
import { WarehouseService } from '../warehouse/service/warehouse.service';

@Component({
  selector: 'app-statistics',
  templateUrl: './statistics.component.html',
  styleUrl: './statistics.component.scss'
})
export class StatisticsComponent implements OnInit {
  loading = true;
  activeTab: 'revenue' | 'product' | 'customer' = 'revenue';

  // Filter doanh thu
  revenueMode: 'day' | 'week' | 'month' = 'day';

  // ===== DOANH THU =====
  revenueChartData: any;
  revenueChartOptions: any;
  totalRevenue = 0;
  avgOrderValue = 0;
  totalActiveOrders = 0;

  // ===== SẢN PHẨM =====
  topSaleChartData: any;
  topSaleChartOptions: any;
  inventoryChartData: any;
  inventoryChartOptions: any;
  topProducts: { name: string; img: string; qty: number; revenue: number }[] = [];

  // ===== KHÁCH HÀNG =====
  customerChartData: any;
  customerChartOptions: any;
  topCustomers: { name: string; email: string; orders: number; revenue: number }[] = [];
  newCustomers = 0;
  returningCustomers = 0;

  private allInvoices: IInvoice[] = [];

  constructor(
    private invoiceService: InvoiceService,
    private productService: ProductService,
    private warehouseService: WarehouseService
  ) {}

  ngOnInit(): void {
    forkJoin({
      invoices: this.invoiceService.getInvoice(),
      inventory: this.warehouseService.getInventory()
    }).pipe(first()).subscribe({
      next: ({ invoices, inventory }) => {
        this.loading = false;
        this.allInvoices = (invoices || []).filter(i => i.status === 'completed');
        this.buildRevenueChart();
        this.buildProductChart(invoices || []);
        this.buildInventoryChart(inventory || []);
        this.buildCustomerChart();
      },
      error: () => { this.loading = false; }
    });
  }

  // ===== DOANH THU =====
  buildRevenueChart() {
    const labels: string[] = [];
    const data: number[] = [];
    const now = new Date();

    // Xác định khoảng thời gian đầu/cuối tương ứng với revenueMode đang chọn,
    // để dùng chung cho cả biểu đồ và 3 thẻ tổng hợp phía trên.
    let rangeStart: Date;
    let rangeEnd: Date;

    if (this.revenueMode === 'day') {
      rangeEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
      rangeStart = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 13, 0, 0, 0, 0);

      for (let i = 13; i >= 0; i--) {
        const d = new Date(now);
        d.setDate(d.getDate() - i);
        const label = `${d.getDate()}/${d.getMonth() + 1}`;
        labels.push(label);
        const rev = this.getRevenueForDate(d);
        data.push(rev);
      }
    } else if (this.revenueMode === 'week') {
      rangeEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
      rangeStart = new Date(now);
      rangeStart.setDate(rangeStart.getDate() - 7 * 7);
      rangeStart.setHours(0, 0, 0, 0);

      for (let i = 7; i >= 0; i--) {
        const d = new Date(now);
        d.setDate(d.getDate() - i * 7);
        const label = `T${this.getWeek(d)}`;
        labels.push(label);
        data.push(this.getRevenueForWeek(d));
      }
    } else {
      rangeEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
      rangeStart = new Date(now.getFullYear(), now.getMonth() - 5, 1, 0, 0, 0, 0);

      for (let i = 5; i >= 0; i--) {
        const d = new Date(now);
        d.setMonth(d.getMonth() - i);
        const label = `T${d.getMonth() + 1}/${d.getFullYear()}`;
        labels.push(label);
        data.push(this.getRevenueForMonth(d));
      }
    }

    // Lọc hóa đơn theo đúng khoảng thời gian của mode đang chọn
    const invoicesInRange = this.allInvoices.filter(inv => {
      const pd = this.parseDate(inv.details?.[0]?.date ?? '');
      return pd && pd >= rangeStart && pd <= rangeEnd;
    });

    this.totalRevenue = invoicesInRange.reduce((s, inv) => s + this.getInvoiceRevenue(inv), 0);
    this.totalActiveOrders = invoicesInRange.length;
    this.avgOrderValue = this.totalActiveOrders > 0
      ? Math.round(this.totalRevenue / this.totalActiveOrders) : 0;

    this.revenueChartData = {
      labels,
      datasets: [{
        label: 'Doanh thu (đ)',
        data,
        fill: true,
        backgroundColor: 'rgba(102, 126, 234, 0.15)',
        borderColor: '#667eea',
        tension: 0.4,
        pointBackgroundColor: '#667eea',
        pointRadius: 4
      }]
    };

    this.revenueChartOptions = {
      responsive: true,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx: any) => ctx.parsed.y.toLocaleString('vi-VN') + ' đ'
          }
        }
      },
      scales: {
        y: {
          ticks: {
            callback: (v: number) => v >= 1000000
              ? (v / 1000000).toFixed(1) + 'M'
              : (v / 1000).toFixed(0) + 'K'
          }
        }
      }
    };
  }

  switchRevenueMode(mode: 'day' | 'week' | 'month') {
    this.revenueMode = mode;
    this.buildRevenueChart();
  }

  private getRevenueForDate(d: Date): number {
    return this.allInvoices
      .filter(inv => {
        const pd = this.parseDate(inv.details?.[0]?.date ?? '');
        return pd
          && pd.getDate() === d.getDate()
          && pd.getMonth() === d.getMonth()
          && pd.getFullYear() === d.getFullYear();
      })
      .reduce((s, inv) => s + this.getInvoiceRevenue(inv), 0);
  }

  private getRevenueForWeek(d: Date): number {
    const week = this.getWeek(d);
    const year = d.getFullYear();
    return this.allInvoices
      .filter(inv => {
        const raw = inv.details?.[0]?.date ?? '';
        const pd = this.parseDate(raw);
        return pd && this.getWeek(pd) === week && pd.getFullYear() === year;
      })
      .reduce((s, inv) => s + this.getInvoiceRevenue(inv), 0);
  }

  private getRevenueForMonth(d: Date): number {
    return this.allInvoices
      .filter(inv => {
        const raw = inv.details?.[0]?.date ?? '';
        const pd = this.parseDate(raw);
        return pd && pd.getMonth() === d.getMonth() && pd.getFullYear() === d.getFullYear();
      })
      .reduce((s, inv) => s + this.getInvoiceRevenue(inv), 0);
  }

  /** Tổng tiền của một hóa đơn (dùng chung để tránh lặp code và đồng nhất cách tính) */
  private getInvoiceRevenue(inv: IInvoice): number {
    return inv.details?.reduce((s, d) => s + d.quantity * d.price, 0) ?? 0;
  }

  private getWeek(d: Date): number {
    const start = new Date(d.getFullYear(), 0, 1);
    return Math.ceil(((d.getTime() - start.getTime()) / 86400000 + start.getDay() + 1) / 7);
  }

  private parseDate(raw: string): Date | null {
    if (!raw) return null;
    // Dữ liệu thực tế có dạng "dd-mm-yyyy" (ví dụ "08-06-2026"),
    // nhưng vẫn hỗ trợ thêm "dd/mm/yyyy" để phòng dữ liệu cũ/khác nguồn.
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

  // ===== SẢN PHẨM =====
  buildProductChart(invoices: IInvoice[]) {
    const active = invoices.filter(i => i.status === 'completed');
    const map = new Map<string, { name: string; img: string; qty: number; revenue: number }>();

    for (const inv of active) {
      for (const d of inv.details || []) {
        const id = d.productId;
        const ex = map.get(id);
        if (ex) {
          ex.qty += d.quantity;
          ex.revenue += d.quantity * d.price;
        } else {
          map.set(id, {
            name: d.product?.nameProduct ?? 'SP',
            img: d.product?.img ?? '',
            qty: d.quantity,
            revenue: d.quantity * d.price
          });
        }
      }
    }

    this.topProducts = Array.from(map.values())
      .sort((a, b) => b.qty - a.qty)
      .slice(0, 8);

    const colors = ['#667eea','#764ba2','#f093fb','#f5576c','#4facfe','#43e97b','#fa709a','#fee140'];

    this.topSaleChartData = {
      labels: this.topProducts.map(p => p.name),
      datasets: [{
        data: this.topProducts.map(p => p.qty),
        backgroundColor: colors,
        borderWidth: 0
      }]
    };
    this.topSaleChartOptions = {
      responsive: true,
      plugins: {
        legend: { position: 'right', labels: { font: { size: 11 } } },
        tooltip: { callbacks: { label: (ctx: any) => ` ${ctx.label}: ${ctx.parsed} món` } }
      }
    };
  }

  buildInventoryChart(inventory: any[]) {
    const items = inventory.slice(0, 8);
    this.inventoryChartData = {
      labels: items.map(i => i.productId?.nameProduct ?? ''),
      datasets: [
        {
          label: 'Tồn kho',
          data: items.map(i => i.quantity),
          backgroundColor: items.map(i =>
            i.quantity === 0 ? '#f5576c' :
            i.quantity <= i.minQuantity ? '#ffc107' : '#43e97b'
          )
        },
        {
          label: 'Ngưỡng cảnh báo',
          data: items.map(i => i.minQuantity),
          backgroundColor: 'rgba(0,0,0,0.08)',
          borderColor: '#aaa',
          borderWidth: 1,
          type: 'line',
          pointRadius: 0,
          fill: false
        }
      ]
    };
    this.inventoryChartOptions = {
      responsive: true,
      plugins: { legend: { position: 'top' } },
      scales: { y: { beginAtZero: true } }
    };
  }

  // ===== KHÁCH HÀNG =====
  buildCustomerChart() {
    const map = new Map<string, { name: string; email: string; orders: number; revenue: number }>();

    for (const inv of this.allInvoices) {
      const id = inv.accountId;
      const ex = map.get(id);
      const rev = this.getInvoiceRevenue(inv);
      if (ex) {
        ex.orders++;
        ex.revenue += rev;
      } else {
        map.set(id, {
          name: inv.account?.name ?? 'Khách hàng',
          email: inv.account?.email ?? '',
          orders: 1,
          revenue: rev
        });
      }
    }

    this.topCustomers = Array.from(map.values())
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 10);

    this.returningCustomers = Array.from(map.values()).filter(c => c.orders > 1).length;
    this.newCustomers = map.size - this.returningCustomers;

    this.customerChartData = {
      labels: this.topCustomers.slice(0, 6).map(c => c.name),
      datasets: [{
        label: 'Doanh thu (đ)',
        data: this.topCustomers.slice(0, 6).map(c => c.revenue),
        backgroundColor: '#667eea',
        borderRadius: 6
      }]
    };
    this.customerChartOptions = {
      responsive: true,
      indexAxis: 'y',
      plugins: {
        legend: { display: false },
        tooltip: { callbacks: { label: (ctx: any) => ctx.parsed.x.toLocaleString('vi-VN') + ' đ' } }
      },
      scales: {
        x: { ticks: { callback: (v: number) => (v / 1000).toFixed(0) + 'K' } }
      }
    };
  }

  formatPrice(p: number) {
    return p.toLocaleString('vi-VN') + ' đ';
  }
}