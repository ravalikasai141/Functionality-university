import { LightningElement, api, track } from 'lwc';

export default class ReviewApplicationField extends LightningElement {
  @api label;
  @api answer;
  @api hidebutton = false;

  @track showComment;
  @track commentIcon = 'utility:engage';
  @track fieldBackground;

  get fieldStyling() {
    return `slds-col slds-size_${this.hidebutton ? 8 : 7}-of-8`;
  }

  handleShowComment() {
    this.showComment = !this.showComment;
    this.commentIcon = this.showComment ? 'utility:clear' : 'utility:engage';
    this.fieldBackground = this.showComment ? 'yellow-background' : '';
  }
}