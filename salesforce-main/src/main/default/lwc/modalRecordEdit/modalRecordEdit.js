import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';

export default class ModalRecordEdit extends LightningModal {
  @api fields;
  @api header;
  @api object;
  @api recordId;
  @track formLoading = true;

  async onCancel() {
    this.close();
  }

  async onSuccess() {
    this.close('updated');
  }

  async onLoad() {
    this.formLoading = false;
    this.template.querySelector('.form-wrapper').classList.remove('slds-hide');
  }
}
