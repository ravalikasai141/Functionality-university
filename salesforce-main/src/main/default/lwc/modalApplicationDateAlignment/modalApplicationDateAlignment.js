import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ModalApplicationDateAlignment extends LightningModal {
  // The Name field of both the Opportunity and related Product
  @api opportunityName;
  @api productName;

  // The Link to the Opportunity and related Product in "/RecordId" format
  @api productLink;
  @api opportunityLink;

  // Start and End Date values for Opportunity (Current) and related Product (New)
  @api currentStartDate;
  @api currentEndDate;
  @api newStartDate;
  @api newEndDate;

  handleConfirm() {
    this.close('Confirm');
  }

  handleCancel() {
    this.close();
  }
}
