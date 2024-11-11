import { LightningElement, api, track } from 'lwc';

export default class ReviewApplicationEditSection extends LightningElement {
  @api title;

  @api apiName;

  @api recordId;

  @api fields;

  @track formLoading = true;

  async onLoad() {
    this.formLoading = false;
    this.template.querySelector('.form-wrapper').classList.remove('slds-hide');
  }
}
