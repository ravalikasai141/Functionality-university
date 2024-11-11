import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import SECTION_JSON_FIELD from '@salesforce/schema/Opportunity.Section_JSON__c';

const FIELDS = [SECTION_JSON_FIELD];
export default class ApplicationSection extends LightningElement {
  @api recordId;
  @track displaySpinner = true;
  @track sections;
  @track infoText;

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredOpportunity({ error, data }) {
    if (data) {
      const sectionJSONString = getFieldValue(data, SECTION_JSON_FIELD);

      if (!sectionJSONString) {
        this.infoText = 'No section data is available for this application';
        this.displaySpinner = false;
        return;
      }

      try {
        const stageData = JSON.parse(sectionJSONString);
        this.sections = stageData ? stageData : 'No sections';

        this.sections.forEach((section) => {
          section.code = section.code.replace(/_/g, ' ');
          section.code = section.code.toLowerCase();
          section.isComplete = section.status === 'COMPLETED' ? true : false;
          section.isInProgress = section.status === 'IN_PROGRESS' ? true : false;
        });
      } catch (parseError) {
        this.infoText = 'Hmm... There has been a Parser error. If this issue persists, please contact App Support';
      }
    } else if (error) {
      this.infoText =
        "Hmm... It's not been possible to load the section data for this student. If this issue persists, please contact App Support";
    }

    this.displaySpinner = false;
  }
}
