import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ELIGIBILITY_JSON_FIELD from '@salesforce/schema/Opportunity.Eligibility_JSON__c';

const FIELDS = [ELIGIBILITY_JSON_FIELD];
export default class eligibilityData extends LightningElement {
  @api recordId;
  @track displaySpinner = true;

  @track answers;
  @track eliStatus;
  @track eliSubmitted;
  @track eliTemplate;
  @track summary;

  @track infoText;

  get formattedDate() {
    const date = new Date(this.eliSubmitted);

    // if date is invalid, return N/A
    if (isNaN(date.getTime())) {
      return 'N/A';
    }
    return date.toLocaleDateString('en-GB');
  }

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredOpportunity({ error, data }) {
    if (data) {
      const eliJSONString = getFieldValue(data, ELIGIBILITY_JSON_FIELD);

      if (!eliJSONString) {
        this.infoText = 'Eligibility not provided.';
        this.displaySpinner = false;
        return;
      }

      try {
        const eliData = JSON.parse(eliJSONString);

        this.eliStatus = eliData.eligibility.isEligible ? eliData.eligibility.isEligible : 'N/A';
        this.eliSubmitted = eliData.eligibility.submittedOn ? eliData.eligibility.submittedOn : 'N/A';
        this.eliTemplate = eliData.eligibility.templateCode ? eliData.eligibility.templateCode : 'N/A';

        this.answers = eliData.eligibility.answers;
        this.summary = eliData.eligibility.summaryText;
      } catch (parseError) {
        this.infoText = 'An internal error has occurred loading eligibility data. Please try again later.';
      }
    } else if (error) {
      this.infoText = 'An internal error has occurred loading eligibility data. Please try again later.';
    }

    this.displaySpinner = false;
  }
}
