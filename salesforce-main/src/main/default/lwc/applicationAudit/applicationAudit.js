import { LightningElement, track, wire, api } from 'lwc';
import fetchAudits from '@salesforce/apex/ApplicationAuditController.fetchAudits';

export default class ApplicationAudit extends LightningElement {
  @api recordId;

  gridColumns = [
    {
      type: 'text',
      fieldName: 'updatedBy',
      label: 'Updated By'
    },
    {
      type: 'text',
      fieldName: 'identifier',
      label: 'Identifier'
    },
    {
      type: 'text',
      fieldName: 'field',
      label: 'Field'
    },
    {
      type: 'text',
      fieldName: 'oldValue',
      label: 'Old Value'
    },
    {
      type: 'text',
      fieldName: 'newValue',
      label: 'New Value'
    },
    {
      type: 'text',
      fieldName: 'object',
      label: 'Record type'
    },
    {
      type: 'date',
      fieldName: 'updated',
      label: 'Modified Date',
      typeAttributes: {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      }
    }
  ];

  @track gridData;
  @track preSelected;
  @track expanded;

  @wire(fetchAudits, { opportunityId: '$recordId' })
  fetch(result) {
    const { error, data } = result;
    this.preSelected = [];
    this.expanded = [];

    if (!error && data) {
      this.gridData = data;

      for (let i = 0; i < this.gridData.length; i++) {
        this.expanded.push(this.gridData[i].updated);

        if (this.gridData[i].object === 'Application') {
          this.preSelected.push(this.gridData[i].updated);
        }
      }
    }
  }
}
