import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';

export default class ReviewApplicationSectionComment extends LightningModal {
  @api section;
  @api previousComment;
  @track comment;

  connectedCallback() {
    this.comment = this.previousComment;
  }

  handleOkay() {
    this.close(this.comment);
  }

  handleClear() {
    this.close('');
  }

  get header() {
    return `Comments for ${this.section}`;
  }

  handleCommentChange(event) {
    this.comment = event.target.value;
  }
}
