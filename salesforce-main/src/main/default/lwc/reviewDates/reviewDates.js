import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import OpportunityName from '@salesforce/schema/Opportunity.Name';
import OpportunityStartDate from '@salesforce/schema/Opportunity.Start_Date__c';
import OpportunityEndDate from '@salesforce/schema/Opportunity.End_Date__c';

import ProductId from '@salesforce/schema/Opportunity.Course_Instance__c';
import ProductName from '@salesforce/schema/Opportunity.Course_Instance__r.Name';
import ProductStartDate from '@salesforce/schema/Opportunity.Course_Instance__r.Start_Date__c';
import ProductEndDate from '@salesforce/schema/Opportunity.Course_Instance__r.End_Date__c';
import ApplicationDateAlignmentModal from 'c/modalApplicationDateAlignment';

import updateOpportunityProductDates from '@salesforce/apex/ApplicationReviewController.updateOpportunityProductDates';

export default class ReviewDates extends LightningElement {
  @api recordId;

  @track error;

  @track datesMisaligned = false;

  @track productId;

  @track productName;

  @track opportunityName;

  @track oppStartDate;

  @track oppEndDate;

  @track productStartDate;

  @track productEndDate;

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [
      ProductId,
      ProductName,
      OpportunityName,
      OpportunityStartDate,
      OpportunityEndDate,
      ProductStartDate,
      ProductEndDate
    ]
  })
  fetch(result) {
    if (result.data) {
      this.productId = getFieldValue(result.data, ProductId);

      if (this.productId) {
        this.productName = getFieldValue(result.data, ProductName);
        this.opportunityName = getFieldValue(result.data, OpportunityName);

        this.oppStartDate = getFieldValue(result.data, OpportunityStartDate);
        this.oppEndDate = getFieldValue(result.data, OpportunityEndDate);
        this.productStartDate = getFieldValue(result.data, ProductStartDate);
        this.productEndDate = getFieldValue(result.data, ProductEndDate);

        if (this.oppStartDate !== this.productStartDate || this.oppEndDate !== this.productEndDate) {
          this.datesMisaligned = true;
        }
      }
    }

    if (result.error) {
      this.error = 'Unable to load Review Date data: ' + result.error.body.message;
    }
  }

  async handleUpdateClick() {
    this.error = '';
    this.dispatchEvent(new CustomEvent('loading'));

    const result = await ApplicationDateAlignmentModal.open({
      size: 'large',
      description: "Accessible description of modal's purpose",
      opportunityLink: `/${this.recordId}`,
      productLink: `/${this.productId}`,
      productName: this.productName,
      opportunityName: this.opportunityName,
      currentStartDate: this.oppStartDate,
      currentEndDate: this.oppEndDate,
      newStartDate: this.productStartDate,
      newEndDate: this.productEndDate
    });

    if (result) {
      try {
        await updateOpportunityProductDates({ opportunityId: this.recordId });

        this.datesMisaligned = false;
        this.dispatchEvent(new CustomEvent('success'));
      } catch (e) {
        this.error = 'Unable to save Review Date data: ' + e;
        this.dispatchEvent(new CustomEvent('error'));
      }
    } else {
      this.dispatchEvent(new CustomEvent('close'));
    }
  }
}
