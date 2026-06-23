import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { SidebarModule } from 'primeng/sidebar';
import { TableModule } from 'primeng/table';
import { TooltipModule } from 'primeng/tooltip';
import { ChartModule } from 'primeng/chart';
import { FeatureRoutingModule } from './feature.routes';
import { ProductComponent } from './product/product.component';
import { NgbDropdownModule, NgbModalModule } from '@ng-bootstrap/ng-bootstrap';
import { FormlyModule } from '@ngx-formly/core';
import { ProductEditComponent } from './product/product-edit/product-edit.component';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { FormlyModule as AppFormlyModule } from '../formly/formly.module';
import { ToastModule } from 'primeng/toast';
import { ConfirmationService, MessageService } from 'primeng/api';
import { OverlayPanelModule } from 'primeng/overlaypanel';
import { InputTextModule } from "../formly/form/input-text/input-text.module";
import { ConfirmationDialogService } from './service/confirmation.service';
import { InvoiceComponent } from './invoice/invoice.component';
import { AccountComponent } from './account/account.component';
import { AccountEditComponent } from './account/account-edit/account-edit.component';
import { ImageModule } from 'primeng/image';
import { WarehouseComponent } from './warehouse/warehouse.component';
import { ExportComponent } from './warehouse/export/export.component';
import { OrderComponent } from './order/order.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { StatisticsComponent } from './statistics/statistics.component';

@NgModule({
  declarations: [
    ProductComponent,
    ProductEditComponent,
    InvoiceComponent,
    AccountComponent,
    AccountEditComponent,
    WarehouseComponent,
    ExportComponent,
    OrderComponent,
    DashboardComponent,
    StatisticsComponent
  ],
  imports: [
    CommonModule,
    FeatureRoutingModule,
    SidebarModule,
    RouterLink,
    TableModule,
    ButtonModule,
    TooltipModule,
    ChartModule,
    NgbDropdownModule,
    NgbModalModule,
    FormlyModule.forChild({}),
    AppFormlyModule,
    ReactiveFormsModule,
    FormsModule,
    ToastModule,
    OverlayPanelModule,
    InputTextModule,
    ImageModule
  ],
  providers: [MessageService, ConfirmationService, ConfirmationDialogService]
})
export class FeatureModule { }