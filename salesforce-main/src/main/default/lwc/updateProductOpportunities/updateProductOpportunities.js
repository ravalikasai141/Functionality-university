import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import ProductName from '@salesforce/schema/Product2.Name';
import ProductStartDate from '@salesforce/schema/Product2.Start_Date__c';
import ProductEndDate from '@salesforce/schema/Product2.End_Date__c';

import countOpportunitiesWithMismatchedDates from '@salesforce/apex/ProductOpportunityUpdateController.countOpportunitiesWithMismatchedDates';
import updateOpportunitiesWithMismatchedDates from '@salesforce/apex/ProductOpportunityUpdateController.updateOpportunitiesWithMismatchedDates';

export default class UpdateProductOpportunities extends LightningElement {
  // The amount of Opportunities that can be processed in a given update
  maxOppLimit = 5000;

  // Product Record Id, provided via the Aura wrapper
  @api recordId;

  // Product data retrieved via Wire call
  @track productName;
  @track productStartDate;
  @track productEndDate;

  @track error;
  @track loading = true;
  @track updateButtonDisabled = true;

  @track noRecordsToUpdate = false;

  // Whether or not the update has completed
  @track saveCompleted = false;

  // A general description of how many Opportunities were identified
  @track opportunityCountDescriptionText;

  // A warning message on how many Opportunities can be processed at once
  @track tooManyOpportunitiesAlertText;

  // A message of how many Opportunities will be processed in the update
  @track oppCardCount;

  // Messages of how many records were successful or not at updating
  @track failedUpdateText;
  @track successfulUpdateText;

  // A URL to the given Product
  get productLink() {
    return `/${this.recordId}`;
  }

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [ProductName, ProductStartDate, ProductEndDate]
  })
  fetchProductDetails(result) {
    if (!this.recordId) {
      return;
    }

    if (result.data) {
      this.productName = getFieldValue(result.data, ProductName);
      this.productStartDate = getFieldValue(result.data, ProductStartDate);
      this.productEndDate = getFieldValue(result.data, ProductEndDate);
    }

    if (result.error) {
      this.error = 'Unable to load Product data: ' + result.error.body.message;
      return;
    }

    countOpportunitiesWithMismatchedDates({
      productId: this.recordId,
      startDate: this.productStartDate,
      endDate: this.productEndDate
    })
      .then((totalOppCount) => {
        if (totalOppCount === 0) {
          this.noRecordsToUpdate = true;
        }

        // Identify how many Opportunities we will be committing to update in this action
        const countOfOppsToUpdate = totalOppCount > this.maxOppLimit ? this.maxOppLimit : totalOppCount;

        // Set a general description of the amount of records identified
        this.opportunityCountDescriptionText = `Found ${totalOppCount} linked ${
          totalOppCount !== 1 ? 'Opportunities' : 'Opportunity'
        } with a Start Date and/or End Date that ${
          totalOppCount !== 1 ? 'do' : 'does'
        } not align with the given Product.`;

        // If we are not going to update all Opps at once, set an alert message to be displayed after the general description
        if (totalOppCount !== countOfOppsToUpdate) {
          this.tooManyOpportunitiesAlertText = `Please note that the update limit is ${this.maxOppLimit} at a time and proceed accordingly.`;
        }

        // Set a label on the Opportunity card of how many Opportunities will be updated
        this.oppCardCount = `${countOfOppsToUpdate} linked ${
          countOfOppsToUpdate !== 1 ? 'Opportunities' : 'Opportunity'
        }`;

        this.updateButtonDisabled = false;
      })
      .catch((e) => {
        this.error = `An internal error has occurred: "${e.body.message}".`;
      })
      .finally(() => {
        this.loading = false;
      });
  }

  async handleCloseClick() {
    this.dispatchEvent(new CustomEvent('closemodal'));
  }

  async handleConfirmClick() {
    this.loading = true;
    this.updateButtonDisabled = true;

    updateOpportunitiesWithMismatchedDates({
      productId: this.recordId,
      startDate: this.productStartDate,
      endDate: this.productEndDate,
      queryCount: this.maxOppLimit
    })
      .then((response) => {
        // If any records failed to save, display a count of how many
        if (response.failCount > 0) {
          this.failedUpdateText = `${response.failCount} ${
            response.failCount === 1 ? 'Opportunity' : 'Opportunities'
          } failed to update.`;
        }

        // If any records were successfully saved, display a count of how many
        if (response.successCount > 0) {
          this.successfulUpdateText = `${response.successCount} ${
            response.successCount === 1 ? 'Opportunity' : 'Opportunities'
          } successfully updated.`;
        }

        this.saveCompleted = true;
      })
      .catch((e) => {
        this.error = `An internal error has occurred: "${e.body.message}".`;
      })
      .finally(() => {
        this.loading = false;
      });
  }
}
