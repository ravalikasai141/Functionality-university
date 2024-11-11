import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import StageName from '@salesforce/schema/Opportunity.StageName';
import SubStatus from '@salesforce/schema/Opportunity.BPP_Sub_Status__c';
import getPreview from '@salesforce/apex/RecallApplicationController.getPreview';
import recallOpportunity from '@salesforce/apex/RecallApplicationController.recallOpportunity';

/**
 * Handles application recalls by showing a preview of changes
 * then emiting changes as an applicationStageChanged event
 */
export default class RecallApplication extends LightningElement {
  /**
   * Opportunity Id passed by record page
   */
  @api recordId;

  /**
   * The current application status
   */
  @track currentStatus;

  /**
   * The current application sub status
   */
  @track currentSubStatus;

  /**
   * The new status - ie what the application is changed
   * to once confirming
   */
  @track newStatus;

  /**
   * The new sub status
   */
  @track newSubStatus;

  /**
   * Shows the loading spinner when true
   */
  @track loading = true;

  /**
   * Shows the error toast when it has a value
   */
  @track error;

  /**
   * Fetches the current opportunity status and sub status
   */
  @wire(getRecord, { recordId: '$recordId', fields: [StageName, SubStatus] })
  fetch(result) {
    if (result.data) {
      this.currentStatus = getFieldValue(result.data, StageName);
      this.currentSubStatus = getFieldValue(result.data, SubStatus);
    }

    if (result.error) {
      this.error = 'Unable to load data: ' + result.error;
    }
  }

  /**
   * Fetches the preview status and sub status
   */
  @wire(getPreview, { opportunityId: '$recordId' })
  fetchComparison(result) {
    if (result.data || result.error) {
      if (result.data) {
        this.newStatus = result.data.StageName;
        this.newSubStatus = result.data.BPP_Sub_Status__c;
      }

      if (result.error) {
        this.error = 'Unable to load data: ' + result.error;
      }

      this.loading = false;
    }
  }

  /**
   * Closes the quick action with no changes
   */
  async handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  /**
   * Updates the opportunity, emits an applicationStageChanged
   * event and then closes the quick action and shows a toast
   */
  async handleConfirm() {
    this.loading = true;

    try {
      await recallOpportunity({ opportunityId: this.recordId });

      // Close action screen
      this.dispatchEvent(new CloseActionScreenEvent());
      // Inform SF that record has changed
      getRecordNotifyChange([{ recordId: this.recordId }]);
      // Show toast
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'Opportunity recalled successfully',
          variant: 'success'
        })
      );
    } catch (e) {
      this.error = 'Unable to update application: ' + e;
    }
  }
}
