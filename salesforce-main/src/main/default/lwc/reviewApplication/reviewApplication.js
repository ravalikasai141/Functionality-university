import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import AccountId from '@salesforce/schema/Opportunity.AccountId';
import StageName from '@salesforce/schema/Opportunity.StageName';
import BPP_Sub_Status__c from '@salesforce/schema/Opportunity.BPP_Sub_Status__c';
import Resubmission_Date__c from '@salesforce/schema/Opportunity.Resubmission_Date__c';

export default class ReviewApplication extends LightningElement {
  @api recordId;

  @track loading = true;

  @track allowReview;

  @track allowFinalReview;

  @track reviewUnavailable;

  @track stageName;

  @track status;

  @track resubmissionDate;

  @track accountId;

  @track _result;

  @wire(getRecord, { recordId: '$recordId', fields: [AccountId, StageName, BPP_Sub_Status__c, Resubmission_Date__c] })
  fetch(result) {
    this._result = result;

    if (result.data || result.error) {
      if (result.data) {
        this.stageName = getFieldValue(result.data, StageName);
        this.accountId = getFieldValue(result.data, AccountId);
        this.status = getFieldValue(result.data, BPP_Sub_Status__c);
        this.resubmissionDate = getFieldValue(result.data, Resubmission_Date__c);

        if (this.stageName === 'BPP Review' && this.status === 'In Progress') {
          this.allowReview = true;
          this.reviewUnavailable = false;
        } else if (this.stageName === 'Acceptance' && (this.status === 'In Progress' || this.status === 'On Hold')) {
          this.allowFinalReview = true;
          this.reviewUnavailable = false;
        } else {
          this.reviewUnavailable = true;
          this.allowFinalReview = false;
          this.allowReview = false;
        }
      }

      this.loading = false;
    }
  }

  async onReviewStart() {
    await refreshApex(this._result);
  }

  async refreshData() {
    await refreshApex(this._result);
  }

  async onReviewLoading() {
    this.loading = true;
  }

  async onModalClose() {
    this.loading = false;
  }

  async onReviewSuccess() {
    await refreshApex(this._result);
  }

  async onReviewError() {
    this.loading = false;
  }
}
