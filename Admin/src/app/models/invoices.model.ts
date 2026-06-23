import { IAccount } from "./account.model";
import { IProduct } from "./product.model";

export interface IInvoice {
    status?: string;
    cancelReason?: string;
    _id?: string;
    nameInvoice: string;
    details: IDetailInvoice[];
    accountId: string;
    account: IAccount;
    dateDisplay?: string;
    addressDisplay?: string;
    totalPrice?: number;
    totalQty?: number;
}

export interface IDetailInvoice {
    _id?: string;
    productId: string;
    product: IProduct;
    quantity: number;
    price: number;
    address: string;
    date: string;
}