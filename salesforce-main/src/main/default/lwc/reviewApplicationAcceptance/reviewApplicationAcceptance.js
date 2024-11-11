import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import submitFinalReview from '@salesforce/apex/ApplicationReviewController.submitFinalReview';

// Editable fields
import DOCUMENT_REFERENCE from '@salesforce/schema/Account.ID_Document_Reference__c';
import DOCUMENT_TYPE from '@salesforce/schema/Account.ID_Document_Type__c';

// Fields required for Weekly Contracted Hours banner
import OLD_CONTRACTED_HOURS from '@salesforce/schema/Opportunity.Old_Weekly_Contracted_Hours__c';
import CONTRACTED_HOURS from '@salesforce/schema/Opportunity.Weekly_Contracted_Hours_Apprentice__c';

export default class ReviewApplicationAcceptance extends LightningElement {
  @api opportunityId;

  @api accountId;

  @track comment;

  @track status;

  @track disabled = true;

  @track error;

  @track commentRequired;

  @track contractedHoursChangedError;

  feedbackRequired = false;

  editableFields = [
    DOCUMENT_REFERENCE,
    { fieldApiName: 'ULN__pc', objectApiName: 'Account' },
    DOCUMENT_TYPE,
    { fieldApiName: 'NI_Number__pc', objectApiName: 'Account' }
  ];

  opportunityFields = [
    { fieldApiName: 'Course_Instance__c', objectApiName: 'Opportunity' },
    { fieldApiName: 'OOTJTH_Preserved__c', objectApiName: 'Opportunity' },
    { fieldApiName: 'Start_Date__c', objectApiName: 'Opportunity' },
    { fieldApiName: 'End_Date__c', objectApiName: 'Opportunity' },
    { fieldApiName: 'Category__c', objectApiName: 'Opportunity' },
    { fieldApiName: 'Division__c', objectApiName: 'Opportunity' }
  ];

  reviewOptions = [
    { label: 'Approved', value: 'approved' },
    { label: 'Awaiting Information', value: 'awaiting information' }
  ];

  formats = ['bold', 'italic', 'underline', 'strike', 'list', 'indent', 'clean'];

  @wire(getRecord, { recordId: '$opportunityId', fields: [OLD_CONTRACTED_HOURS, CONTRACTED_HOURS] })
  fetch(result) {
    if (result.data) {
      const oldHours = getFieldValue(result.data, OLD_CONTRACTED_HOURS);

      if (oldHours) {
        const newHours = getFieldValue(result.data, CONTRACTED_HOURS);

        this.contractedHoursChangedError = `Note the Line Manager has updated the weekly contracted hours from ${oldHours}
                                              to ${newHours} on this application. The overall off the job training hours have
                                              been recalculated based on the new weekly contracted hours`;
      }
    }
  }

  async handleCommentChange(event) {
    this.comment = event.target.value;
    this.validate();
  }

  async handleStatusChange(event) {
    this.status = event.target.value;
    this.validate();
  }

  async handleSubmit() {
    this.disabled = true;
    this.error = null;

    // fire loading event to prevent any changes on pages
    this.dispatchEvent(new CustomEvent('loading'));
    // submit review
    try {
      await submitFinalReview({
        opportunityId: this.opportunityId,
        comment: this.comment,
        awaitingInformation: this.status === 'awaiting information' ? true : false
      });

      this.dispatchEvent(new CustomEvent('success'));
    } catch (e) {
      this.error = e.body.message;
      this.dispatchEvent(new CustomEvent('error'));
    } finally {
      this.disabled = false;
    }
  }

  async validate() {
    this.disabled = true;

    if (this.status) {
      this.disabled = false;
      this.feedbackRequired = false;
    }

    if (this.status === 'awaiting information') {
      this.commentRequired = true;
    }

    if (this.commentRequired && !this.comment) {
      this.disabled = true;
    }
  }
}
