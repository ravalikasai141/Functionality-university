import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import SendStudentSyncEvent from '@salesforce/apex/QuickActionSend.sendStudentSyncEvent';

export default class StudentSync extends LightningElement {
  /**
   * Account Id passed by record page
   */
  @api recordId;

  /**
   * Shows the loading spinner when true
   */
  @track loading = false;

  /**
   * Shows the error toast when it has a value
   */
  @track error;

  /**
   * Handles cancel button, dismisses the screen
   */
  async handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  /**
   * Handles the confirm click button, sends event via controller
   */
  async handleConfirm() {
    this.loading = true;

    try {
      await SendStudentSyncEvent({ record: { sobjectType: 'Account', Id: this.recordId } });

      this.dispatchEvent(new CloseActionScreenEvent());

      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'Student successfully synced',
          variant: 'success'
        })
      );
    } catch (e) {
      this.error = 'Unable to sync student: ' + e.body.message;
    } finally {
      this.loading = false;
    }
  }
}
