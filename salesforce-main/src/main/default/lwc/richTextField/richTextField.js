import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class RichTextField extends LightningElement {
  @api fieldValue;

  handleChange(event) {
    const attributeChangeEvent = new FlowAttributeChangeEvent('fieldValue', event.target.value);
    this.dispatchEvent(attributeChangeEvent);
  }
}
