import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Application fields
import COURSE_INSTANCE from '@salesforce/schema/Opportunity.Course_Instance__c';
import END_DATE from '@salesforce/schema/Opportunity.End_Date__c';
import LINE_MANAGER from '@salesforce/schema/Opportunity.Line_Manager__c';
import CLIENT from '@salesforce/schema/Opportunity.Client__c';
import BD_OPPORTUNITY from '@salesforce/schema/Opportunity.BD_Opportunity__c';
import DISTANCE from '@salesforce/schema/Opportunity.Travel_distance_Miles__c';
import EXEMPTIONS from '@salesforce/schema/Opportunity.Exemptions_commentary__c';
import CATEGORY from '@salesforce/schema/Opportunity.Category__c';
import DIVISION from '@salesforce/schema/Opportunity.Division__c';

// Learner role fields
import JOB_TITLE from '@salesforce/schema/Opportunity.Job_Title_Apprentice__c';
import JOB_STARTED from '@salesforce/schema/Opportunity.Job_Started_On_Apprentice__c';
import CONTRACTED_HOURS from '@salesforce/schema/Opportunity.Weekly_Contracted_Hours_Apprentice__c';

// Company Address fields
import COMPANY_NAME from '@salesforce/schema/Opportunity.Sponsoring_Organization__c';
import COMPANY_ADDRESS1 from '@salesforce/schema/Opportunity.Company_Street_1__c';
import COMPANY_ADDRESS2 from '@salesforce/schema/Opportunity.Company_Street_2__c';
import COMPANY_ADDRESS3 from '@salesforce/schema/Opportunity.Company_Street_3__c';
import COMPANY_ZIP from '@salesforce/schema/Opportunity.Company_Zip_Postal_Code__c';
import COMPANY_CITY from '@salesforce/schema/Opportunity.Company_City__c';
import COMPANY_COUNTRY from '@salesforce/schema/Opportunity.Company_Lookup_Country__c';

// Line Manager Detail fields
import LINE_MANAGER_JOB from '@salesforce/schema/Opportunity.Line_Manager_Job_Title__c';
import LINE_MANAGER_FIRST from '@salesforce/schema/Opportunity.Line_Manager_First_Name__c';
import LINE_MANAGER_LAST from '@salesforce/schema/Opportunity.Line_Manager_Last_Name__c';
import LINE_MANAGER_EMAIL from '@salesforce/schema/Opportunity.Line_Manager_Email__c';
import LINE_MANAGER_PHONE from '@salesforce/schema/Opportunity.Line_Manager_Telephone__c';

export default class ReviewApplicationEdit extends LightningElement {
  @api opportunityId;

  @api accountId;

  @track loading;

  applicationFields = [
    LINE_MANAGER,
    BD_OPPORTUNITY,
    CLIENT,
    DISTANCE,
    { fieldApiName: 'ULN__pc', objectApiName: 'Account' },
    { fieldApiName: 'NI_Number__pc', objectApiName: 'Account' },
    CATEGORY,
    DIVISION
  ];

  accountFields = [
    { fieldApiName: 'ULN__pc', objectApiName: 'Account' },
    { fieldApiName: 'NI_Number__pc', objectApiName: 'Account' }
  ];

  lineManagerFields = [LINE_MANAGER_FIRST, LINE_MANAGER_EMAIL, LINE_MANAGER_LAST, LINE_MANAGER_PHONE, LINE_MANAGER_JOB];

  productFields = [COURSE_INSTANCE, END_DATE];

  roleFields = [JOB_TITLE, CONTRACTED_HOURS, JOB_STARTED];

  exemptionFields = [EXEMPTIONS];

  companyFields = [
    COMPANY_NAME,
    COMPANY_ADDRESS1,
    COMPANY_ZIP,
    COMPANY_ADDRESS2,
    COMPANY_CITY,
    COMPANY_ADDRESS3,
    COMPANY_COUNTRY
  ];

  showError(e) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'An error has occurred...',
        message: e,
        variant: 'error'
      })
    );
  }
}
