import { LightningElement, wire, api } from 'lwc';
import getSubTopics from '@salesforce/apex/ConnectApiManagedTopicController.getSubTopics';

export default class DisplaySubTopics extends LightningElement {
  
  @api recordId;
  siteUrl;
  records;
  showSubTopic = false;
 

  connectedCallback() {
    let communityUrl = `${window.location.origin}`;
    this.siteUrl = communityUrl;
  }

  @wire(getSubTopics, { topicId :'$recordId' })
    navigationTopics({ error, data } ) {
    if (data) {
      let rows = [];
      let tempRows = JSON.parse(JSON.stringify(data));

      for ( let i = 0; i < tempRows.length; i++ ) {
          let row =  tempRows[ i ];
          row.subTopic.hrefVal = this.siteUrl + "/s/topic/" + row.subTopic.id; 
          rows.push( row );
      }

      this.records = rows;
      if(this.records.length) this.showSubTopic = true;
    }
    if (error){
      this.showSubTopic = false;
    }  
  } 
}