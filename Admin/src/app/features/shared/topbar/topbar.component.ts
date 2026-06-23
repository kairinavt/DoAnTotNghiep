import { CommonModule } from '@angular/common';
import { Component, ElementRef, ViewChild } from '@angular/core';
import { RouterModule, Router } from '@angular/router';
import { MenuItem } from 'primeng/api';
import { SidebarModule } from 'primeng/sidebar';

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [CommonModule, SidebarModule, RouterModule],
  templateUrl: './topbar.component.html',
  styleUrl: './topbar.component.scss'
})
export class TopbarComponent {
  
  expanded: boolean[] = [];
  items: MenuItem[] = [
    {
      label: 'Quản Lý món ăn',
      routerLink: '/product',
      command: () => this.navigate('product')
    },
    {
      label: 'Quản lý bán hàng',
      expanded: false,
      items: [
        {
          label: 'Hóa đơn',
          routerLink: '/bill',
          command: onclick => this.navigate('bill')
        },
        {
          label: 'Trạng thái Đơn hàng',
          routerLink: '/order',
          command: onclick => this.navigate('order')
        }
      ]
    },
    {
      label: 'Quản Lý Tài Khoản',
      routerLink: '/account',
      command: () => this.navigate('account')
    },
    {
      label: 'Quản Lý Kho',
      expanded: false,
      items: [
        {
          label: 'Nhập hàng',
          routerLink: '/warehouse',
          command: onclick => this.navigate('warehouse')
        },
        {
          label: 'Xuất hàng',
          routerLink: '/warehouse/export',
          command: onclick => this.navigate('warehouse/export')
        }
      ]
    },
    {
      label: 'Thống kê',
      routerLink: '/statistics',
      command: () => this.navigate('statistics')
    },
  ];
  visibleSidebar = false;

  @ViewChild('menubutton') menuButton!: ElementRef;

  @ViewChild('topbarmenubutton') topbarMenuButton!: ElementRef;

  @ViewChild('topbarmenu') menu!: ElementRef;

  constructor(private router: Router) { }

  navigate(id: string) {
    this.router.navigate([id])
  }

  toggle(index: number) {
    this.expanded[index] = !this.expanded[index];
    this.items[index].expanded = !this.items[index].expanded;
    console.log(this.items[index]);
    
  }
}