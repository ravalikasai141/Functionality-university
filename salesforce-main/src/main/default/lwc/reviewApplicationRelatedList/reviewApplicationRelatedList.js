import { LightningElement, api, track } from 'lwc';
import CommentModal from 'c/reviewApplicationSectionComment';

export default class ReviewApplicationRelatedList extends LightningElement {
  @api rows;
  @api columns;

  @track selectedRows = [];

  @track rowComments = {};

  async handleRowAction(event) {
    const record = event.detail.row;

    const result = await CommentModal.open({
      size: 'small',
      previousComment: this.rowComments[record.Id],
      section: record.Name
    });

    if (result) {
      this.selectedRows.push(record.Id);
      this.rowComments[record.Id] = result;
    } else {
      if (this.selectedRows.includes(record.Id)) {
        this.selectedRows.splice(this.selectedRows.indexOf(record.Id));
      }

      if (this.rowComments[record.Id] != null) {
        this.rowComments[record.Id] = null;
      }
    }

    this.selectedRows = [...this.selectedRows];
  }
}