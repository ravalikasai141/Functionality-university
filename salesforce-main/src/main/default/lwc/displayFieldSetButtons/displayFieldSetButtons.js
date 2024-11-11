import { LightningElement, track } from 'lwc';
import { publish, createMessageContext, releaseMessageContext } from 'lightning/messageService';
import RenderFieldSetMessageChannel from '@salesforce/messageChannel/RenderFieldSet__c';

export default class displayFieldSetButtons extends LightningElement {
  context = createMessageContext();

  @track
  viewMode = true;

  @track
  showError = false;

  @track
  errorMessage;

  disconnectCallback() {
    releaseMessageContext(this.context);
  }

  handleEditClick() {
    this.showError = false;
    this.errorMessage = '';
    this.viewMode = false;
    this.publishMessage('EDIT');
  }

  handleSaveClick() {
    this.showError = true;
    this.errorMessage =
      'This is an example error message. This would likely show the error message that was returned by the failed save transaction.';
    this.publishMessage('SAVE');
  }

  handleCancelClick() {
    this.showError = false;
    this.errorMessage = '';
    this.viewMode = true;
    this.publishMessage('CANCEL');
  }

  handleErrorClose() {
    this.showError = false;
    this.errorMessage = '';
  }

  publishMessage(viewMode) {
    publish(this.context, RenderFieldSetMessageChannel, {
      viewMode: viewMode,
      source: 'buttons'
    });
  }
}