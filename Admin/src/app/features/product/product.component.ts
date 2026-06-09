import { Component, OnInit } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { first } from 'rxjs';
import { ICategory } from '../../models/http/category.model';
import { IProduct } from '../../models/product.model';
import { ProductEditComponent } from './product-edit/product-edit.component';
import { ProductService } from './service/product.service';
import { ConfirmationDialogService } from '../service/confirmation.service';
import { MessageService } from 'primeng/api';

@Component({
  selector: 'app-product',
  templateUrl: './product.component.html',
  styleUrl: './product.component.scss'
})
export class ProductComponent implements OnInit {

  products: IProduct[] = [];

  categories: ICategory[] = [
    {
      _id: 'all',
      name: 'All'
    }
  ];

  selectedCate: ICategory | undefined;
  newCate: string = '';

  // Danh mục đang sửa
  editingCateId: string = '';

  constructor(
    private productService: ProductService,
    private modal: NgbModal,
    private confirmDialog: ConfirmationDialogService,
    private toast: MessageService
  ) {}

  ngOnInit(): void {
    this.getProducts();
    this.getCategories();
  }

  getProducts() {
    const cateIds =
      this.selectedCate &&
      this.selectedCate._id &&
      this.selectedCate._id !== 'all'
        ? [this.selectedCate._id]
        : [];

    this.productService
      .getAllProduct({
        cateIds: cateIds
      })
      .pipe(first())
      .subscribe({
        next: (value) => {
          this.products = value && value.length ? value : [];
        }
      });
  }

  editProduct(id?: string) {
    const modalRef = this.modal.open(ProductEditComponent, {
      size: 'md',
      centered: true,
      backdrop: 'static'
    });

    const instance = modalRef.componentInstance as ProductEditComponent;

    instance.id = id ?? '';
    instance.title = `${id ? 'Sửa' : 'Thêm'} món ăn`;

    modalRef.result.then((val) => {
  if (val === true) {
    this.toast.add({
      severity: 'success',
      summary: 'Thành công',
      detail: 'Lưu thông tin món ăn thành công'
    });
    this.getProducts();
  } else if (val === false) {
    this.toast.add({
      severity: 'error',
      summary: 'Lỗi',
      detail: 'Lưu thông tin món ăn không thành công'
    });
  }
});;
  }

  deletePro(id: string) {
    this.confirmDialog
      .showConfirmDialog(
        'Bạn có chắc muốn xóa món ăn này?',
        'Xác nhận xóa'
      )
      .subscribe({
        next: (value) => {
          if (value) {
            this.productService
              .deletePro(id)
              .pipe(first())
              .subscribe({
                next: (result) => {
                  if (result) {
                    this.toast.add({
                      severity: 'success',
                      summary: 'Thành công',
                      detail: 'Xóa thành công'
                    });

                    this.getProducts();
                  }
                }
              });
          }
        }
      });
  }

  getCategories() {
    this.productService
      .getAllCategories()
      .pipe(first())
      .subscribe({
        next: (value) => {
          if (value && value.length) {
            this.categories = [
              {
                _id: 'all',
                name: 'All'
              },
              ...value
            ];
          }
        }
      });
  }

  cateChange(cate: ICategory) {
    this.selectedCate = { ...cate };
    this.getProducts();
  }

  // Bấm nút sửa danh mục
  editCate(cate: ICategory) {
    this.editingCateId = cate._id ?? '';
    this.newCate = cate.name;
  }

  // Thêm mới hoặc cập nhật
  saveCategory() {
    if (!this.newCate.trim()) return;

    // UPDATE
    if (this.editingCateId) {
      this.productService
        .updateCategory({
          _id: this.editingCateId,
          name: this.newCate
        })
        .pipe(first())
        .subscribe({
          next: (value) => {
            if (value) {
              this.toast.add({
                severity: 'success',
                summary: 'Thành công',
                detail: 'Cập nhật danh mục thành công'
              });

              this.editingCateId = '';
              this.newCate = '';

              this.getCategories();
            }
          }
        });

      return;
    }

    // ADD
    this.productService
      .addCategory({
        name: this.newCate
      })
      .pipe(first())
      .subscribe({
        next: (value) => {
          if (value) {
            this.toast.add({
              severity: 'success',
              summary: 'Thành công',
              detail: 'Thêm danh mục thành công'
            });

            this.newCate = '';
            this.getCategories();
          }
        }
      });
  }

  cancelEditCategory() {
    this.editingCateId = '';
    this.newCate = '';
  }

  deleteCate(cateId: string) {
    this.confirmDialog
      .showConfirmDialog(
        'Bạn có chắc muốn xóa danh mục này?',
        'Xác nhận xóa'
      )
      .subscribe({
        next: (value) => {
          if (value) {
            this.productService
              .deleteCate(cateId)
              .pipe(first())
              .subscribe({
                next: (result) => {
                  if (result) {
                    this.toast.add({
                      severity: 'success',
                      summary: 'Thành công',
                      detail: 'Xóa thành công'
                    });

                    this.getCategories();
                  }
                }
              });
          }
        }
      });
  }
}