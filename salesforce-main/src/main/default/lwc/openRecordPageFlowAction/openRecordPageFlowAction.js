import { api, LightningElement } from 'lwc';

export default class OpenRecordPageFlowAction extends LightningElement {
  @api recordId;
  @api target = '_blank';

  connectedCallback() {
    const completeURL = `${window.location.origin}/${this.recordId}`;
    window.open(completeURL, this.target);
  }
}
