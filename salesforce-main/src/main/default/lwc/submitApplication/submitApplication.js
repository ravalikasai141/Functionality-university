import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import submitApplicationHandler from '@salesforce/apex/SubmitApplicationHandler.checkApplication';

export default class SubmitApplication extends LightningElement {
  @track returnedMessage;

  _recordId;

  @api set recordId(value) {
    this._recordId = value;

    submitApplicationHandler({
      recordId: this._recordId
    }).then((response) => {
      this.returnedMessage = response;
    });
  }

  get recordId() {
    return this._recordId;
  }

  closeModal() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}
