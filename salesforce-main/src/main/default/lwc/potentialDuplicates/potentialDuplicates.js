import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

import findDuplicates from '@salesforce/apex/DuplicateRules.findDuplicates';

export default class potentialDuplicates extends NavigationMixin(LightningElement) {
  @api account;
  @api contact;
  @api selectedRecord;

  @track duplicateRecordHeaders = [];
  @track duplicateRecordData = [];

  @track error;
  @track isLoading;

  get headings() {
    // Create a list of all headings that will be used for all object types
    let headingValues = ['Name'];

    // Add any object specific headings
    if (this.account) {
      headingValues.push('Account Number');
    } else {
      headingValues.push('Email');
    }

    // Add the a blank value to make room for the button
    headingValues.push(null);
    return headingValues;
  }

  get headingText() {
    const objectName = this.account ? 'Client Account' : 'Line Manager';
    return `Existing ${objectName} Record(s) detected, please select 'Use' to relate the contact to this record, or 'Create New Record' to create a new ${objectName} `;
  }

  connectedCallback() {
    this.duplicateRecordData = [];
    this.isLoading = true;

    let jsonRecord;
    let sobjectType;
    if (this.contact) {
      jsonRecord = JSON.stringify(this.contact);
      sobjectType = 'Contact';
    } else {
      jsonRecord = JSON.stringify(this.account);
      sobjectType = 'Account';
    }
    findDuplicates({ jsonRecord, sobjectType })
      .then((response) => {
        if (response) {
          response.forEach((record) => {
            const currentRecord = {
              id: record.Id,
              name: record.Name,
              fields: []
            };

            // Extract any Account specific fields
            if (this.account) {
              currentRecord.fields.push(record.BPP_Account_Number__c);
            }

            // Extract any Contact specific fields
            if (this.contact) {
              currentRecord.fields.push(record.Email);
            }

            this.duplicateRecordData.push(currentRecord);
          });
        } else {
          // no matches found, navigate to the next screen
          const navigateNextEvent = new FlowNavigationNextEvent();
          this.dispatchEvent(navigateNextEvent);
        }

        this.isLoading = false;
      })
      .catch((e) => {
        this.error = `An internal error has occurred: "${e.body.message}". Please exit the flow, retry and contact support if the issue persists.`;
        this.isLoading = false;
      });
  }

  handleClick(event) {
    const attributeChangeEvent = new FlowAttributeChangeEvent('selectedRecord', event.target.dataset.recordid);
    this.dispatchEvent(attributeChangeEvent);

    // navigate to the next screen
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
  }

  constructViewURL(recordId) {
    const pageRef = {
      type: 'standard__recordPage',
      attributes: {
        actionName: 'view',
        recordId: recordId
      }
    };

    return this[NavigationMixin.GenerateUrl](pageRef);
  }

  handleCreateNew() {
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  navigateToRecord(event) {
    const recordId = event.currentTarget.dataset.id;

    this[NavigationMixin.GenerateUrl]({
      type: 'standard__recordPage',
      attributes: {
        recordId: recordId,
        actionName: 'view'
      }
    }).then((url) => {
      window.open(url, '_blank');
    });
  }
}
