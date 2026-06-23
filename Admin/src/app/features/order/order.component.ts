import { Component, OnInit } from '@angular/core';
import { first, forkJoin } from 'rxjs';
import { IInvoice } from '../../models/invoices.model';
import { InvoiceService } from '../invoice/service/invoice.service';
import { ConfirmationDialogService } from '../service/confirmation.service';
import { MessageService } from 'primeng/api';

@Component({
  selector: 'app-order',
  templateUrl: './order.component.html',
  styleUrl: './order.component.scss'
})
export class OrderComponent implements OnInit {
  invoices: IInvoice[] = [];
  filteredInvoices: IInvoice[] = [];
  selectedStatus: string = 'all';
  loading: boolean = false;
  completingAll: boolean = false;

  statusOptions = [
    { label: 'Tất cả', value: 'all' },
    { label: 'Đang hoạt động', value: 'active' },
    { label: 'Hoàn thành', value: 'completed' },
    { label: 'Đã hủy', value: 'cancelled' }
  ];

  constructor(
    private invoiceService: InvoiceService,
    private confirmDialog: ConfirmationDialogService,
    private toast: MessageService
  ) {}

  ngOnInit(): void {
    this.getOrders();
  }

  getOrders() {
    this.loading = true;
    this.invoiceService.getInvoice()
      .pipe(first())
      .subscribe({
        next: (value) => {
          this.loading = false;
          if (value && value.length) {
            this.invoices = value.map(invoice => ({
              ...invoice,
              dateDisplay: invoice.details?.[0]?.date ?? '—',
              addressDisplay: invoice.details?.[0]?.address ?? '—',
              totalPrice: invoice.details?.reduce((sum, d) => sum + d.quantity * d.price, 0) ?? 0,
              totalQty: invoice.details?.reduce((sum, d) => sum + d.quantity, 0) ?? 0
            }));
            this.filterByStatus();
          }
        },
        error: () => {
          this.loading = false;
          this.toast.add({ severity: 'error', summary: 'Lỗi', detail: 'Không thể tải danh sách đơn hàng' });
        }
      });
  }

  filterByStatus() {
    if (this.selectedStatus === 'all') {
      this.filteredInvoices = [...this.invoices];
    } else {
      this.filteredInvoices = this.invoices.filter(i => (i.status || 'active') === this.selectedStatus);
    }
  }

  // Số đơn active chưa hoàn thành (dùng cho nút "Hoàn thành tất cả")
  get activeCount(): number {
    return this.invoices.filter(i => (i.status || 'active') === 'active').length;
  }

  // Tổng doanh thu chỉ tính đơn completed
  get completedRevenue(): number {
    return this.invoices
      .filter(i => i.status === 'completed')
      .reduce((sum, i) => sum + ((i as any).totalPrice ?? 0), 0);
  }

  cancelOrder(invoice: IInvoice) {
    this.confirmDialog.showConfirmDialog(
      `Bạn có chắc muốn hủy đơn hàng ${invoice.nameInvoice}? Hàng sẽ được hoàn kho và khách hàng sẽ nhận email thông báo.`,
      'Xác nhận hủy đơn'
    ).subscribe({
      next: (confirmed) => {
        if (!confirmed) return;
        this.invoiceService.cancelInvoice(invoice._id!, 'Khách hàng không còn nhu cầu')
          .pipe(first())
          .subscribe({
            next: () => {
              this.toast.add({ severity: 'success', summary: 'Thành công', detail: `Đã hủy đơn ${invoice.nameInvoice}` });
              this.getOrders();
            },
            error: (err) => {
              this.toast.add({ severity: 'error', summary: 'Lỗi', detail: err?.error?.message || 'Hủy đơn thất bại' });
            }
          });
      }
    });
  }

  completeOrder(invoice: IInvoice) {
    this.confirmDialog.showConfirmDialog(
      `Xác nhận hoàn thành đơn hàng ${invoice.nameInvoice}? Đơn sẽ được tính vào doanh thu`,
      'Xác nhận hoàn thành'
    ).subscribe({
      next: (confirmed) => {
        if (!confirmed) return;
        this.invoiceService.completeInvoice(invoice._id!)
          .pipe(first())
          .subscribe({
            next: () => {
              this.toast.add({ severity: 'success', summary: 'Thành công', detail: `Đơn ${invoice.nameInvoice} đã hoàn thành` });
              this.getOrders();
            },
            error: (err) => {
              this.toast.add({ severity: 'error', summary: 'Lỗi', detail: err?.error?.message || 'Hoàn thành đơn thất bại' });
            }
          });
      }
    });
  }

  completeAllOrders() {
    const activeOrders = this.invoices.filter(i => (i.status || 'active') === 'active');
    if (!activeOrders.length) return;

    this.confirmDialog.showConfirmDialog(
      `Xác nhận hoàn thành tất cả ${activeOrders.length} đơn đang hoạt động? Toàn bộ sẽ được tính vào doanh thu.`,
      'Hoàn thành tất cả đơn hàng'
    ).subscribe({
      next: (confirmed) => {
        if (!confirmed) return;
        this.completingAll = true;
        const calls = activeOrders.map(inv => this.invoiceService.completeInvoice(inv._id!).pipe(first()));
        forkJoin(calls).subscribe({
          next: () => {
            this.completingAll = false;
            this.toast.add({ severity: 'success', summary: 'Thành công', detail: `Đã hoàn thành ${activeOrders.length} đơn hàng` });
            this.getOrders();
          },
          error: (err) => {
            this.completingAll = false;
            this.toast.add({ severity: 'error', summary: 'Lỗi', detail: err?.error?.message || 'Có lỗi khi hoàn thành đơn hàng' });
            this.getOrders();
          }
        });
      }
    });
  }

  formatPrice(price: number): string {
    return price.toLocaleString('vi-VN') + ' đ';
  }
}