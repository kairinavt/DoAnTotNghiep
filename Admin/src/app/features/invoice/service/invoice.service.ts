import { Injectable } from '@angular/core';
import { HttpService } from '../../service/http.service';
import { IInvoice } from '../../../models/invoices.model';

@Injectable({ providedIn: 'root' })
export class InvoiceService {
  constructor(private httpService: HttpService) {}

  getInvoice() {
    return this.httpService.get<IInvoice[]>({
      controller: 'Invoice', url: '/getall-invoice'
    });
  }

  getInvoiceById(id: string) {
    return this.httpService.get<IInvoice>({
      controller: 'Invoice', url: `/getbyid-invoice/${id}`
    });
  }

  getInvoiceByAccountId(accountId: string) {
    return this.httpService.get<IInvoice[]>({
      controller: 'Invoice', url: `/get-by-accountId/${accountId}`
    });
  }

  // Hủy đơn hàng — gọi PUT /cancel-invoice/:id
  cancelInvoice(id: string, cancelReason: string) {
    return this.httpService.put<IInvoice>({
      controller: 'Invoice',
      url: `/cancel-invoice/${id}`,
      data: { cancelReason }
    });
  }
  completeInvoice(id: string) {
  return this.httpService.put<IInvoice>({
    controller: 'Invoice',
    url: `/complete/${id}`,
    data: {}
  });
  }
}