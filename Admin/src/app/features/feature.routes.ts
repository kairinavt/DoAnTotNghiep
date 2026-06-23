import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ProductComponent } from './product/product.component';
import { WelcomePageComponent } from './welcome-page/welcome-page.component';
import { InvoiceComponent } from './invoice/invoice.component';
import { AccountComponent } from './account/account.component';
import { WarehouseComponent } from './warehouse/warehouse.component';
import { OrderComponent } from './order/order.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { StatisticsComponent } from './statistics/statistics.component';
import { ExportComponent } from './warehouse/export/export.component';
export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'product', component: ProductComponent },
  { path: 'bill', component: InvoiceComponent },
  { path: 'account', component: AccountComponent },
  { path: 'warehouse', component: WarehouseComponent },
  { path: 'warehouse/export', component: ExportComponent },
  { path: 'order', component: OrderComponent },
  { path: 'statistics', component: StatisticsComponent },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class FeatureRoutingModule { }