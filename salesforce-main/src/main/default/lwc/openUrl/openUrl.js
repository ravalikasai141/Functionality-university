import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class OpenUrl extends LightningElement {
  @api url;
  connectedCallback() {
    window.open(this.url, '_blank');
    const nextNavigationEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(nextNavigationEvent);
  }
}
