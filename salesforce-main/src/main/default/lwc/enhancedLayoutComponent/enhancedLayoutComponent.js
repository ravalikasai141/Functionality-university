import { LightningElement, api, track } from 'lwc';
import retrieveFieldDetails from '@salesforce/apex/EnhancedLayoutController.retrieveFieldDetails';
import LOCALE from '@salesforce/i18n/locale';

export default class EnhancedLayoutComponent extends LightningElement {
  @api
  sectionAPIName;

  @api
  sectionLabel;

  @api
  columnWidth;

  @api
  recordId;

  @track
  showSpinner = true;

  @track
  sectionFields = [];

  /**
   * Iteratively interrogate the results of the query to retrieve any values at a given level using a list of property names (Field Segments).
   *
   * @param {Object}  queryResults  The results of the query against the base record
   * @param {Array}  fieldSegments  A list of field segments to iteratively interrogate into the query records (E.g. Account.Name -> ['Account', 'Name'])
   * @returns {String|null} The value at the given level to interrogate to or null if a value could not be found
   */
  getValueFromQuery(queryResults, fieldSegments) {
    let fieldValue = queryResults;

    for (let segmentIdx = 0; segmentIdx < fieldSegments.length; segmentIdx++) {
      const nextFieldSegment = fieldSegments[segmentIdx];

      // If the current level does not have the next field segment, break out of the loop
      if (!Object.hasOwn(fieldValue, nextFieldSegment)) {
        fieldValue = null;
        break;
      }

      // Extract the next field from the query
      fieldValue = fieldValue[nextFieldSegment];
    }

    return fieldValue;
  }

  /**
   * Handles calling the APEX class to retrieve any fields to render and the results of the query using those fields
   */
  connectedCallback() {
    retrieveFieldDetails({
      sectionAPIName: this.sectionAPIName,
      recordId: this.recordId
    })
      .then((response) => {
        if (!response.queryResultsString) {
          return;
        }

        const queryResults = JSON.parse(response.queryResultsString)[0];

        response.fields.forEach((fieldDetails) => {
          // If there is an error message to render, do so
          if (fieldDetails.errorMessage) {
            this.sectionFields.push({
              styling: `slds-col slds-size_${this.columnWidth}-of-2`,
              errorMessage: `Error rendering field: ${fieldDetails.fullPath}: ${fieldDetails.errorMessage}`
            });
            return;
          }

          // If the current user does not have permission to view this field, skip
          if (fieldDetails.missingPermissions) {
            return;
          }

          // Otherwise create an object containing properties required by all field types
          let fieldToRender = {
            name: fieldDetails.fullPath,
            label: fieldDetails.label,
            value: this.getValueFromQuery(queryResults, fieldDetails.fieldSegments),
            styling: `slds-col slds-size_1-of-2`,
            renderGeneric: true
          };

          // And then populate the object with any specifics required for certain field types
          switch (fieldDetails.type) {
            case 'REFERENCE': {
              fieldToRender.renderGeneric = false;
              fieldToRender.renderLink = true;
              fieldToRender.url = `/${fieldToRender.value}`;
              fieldToRender.value = this.getValueFromQuery(queryResults, fieldDetails.lookupFieldSegments);
              break;
            }
            case 'PICKLIST':
            case 'MULTIPICKLIST': {
              fieldToRender.renderGeneric = false;
              fieldToRender.renderText = true;

              let valueLabels = [];
              fieldToRender.value?.split(';').forEach((fieldAPIName) => {
                const picklistLabel = fieldDetails.picklistValuesToLabels[fieldAPIName];

                // If we were able to find the label for the given value return it, otherwise fall back on the API name
                valueLabels.push(picklistLabel ? picklistLabel : fieldAPIName);
              });

              fieldToRender.value = valueLabels?.join(';');
              break;
            }
            case 'BOOLEAN': {
              fieldToRender.renderGeneric = false;
              fieldToRender.renderCheckbox = true;
              break;
            }
            case 'LOCATION': {
              fieldToRender.value = `${fieldToRender.value.latitude}, ${fieldToRender.value.longitude}`;
              break;
            }
            case 'DATETIME': {
              if (!fieldToRender.value) {
                break;
              }

              const dateValue = new Date(fieldToRender.value);
              const formattedHours = String(dateValue.getHours()).padStart(2, '0');
              const formattedMinutes = String(dateValue.getMinutes()).padStart(2, '0');
              fieldToRender.value = `${dateValue.toLocaleDateString(LOCALE)} ${formattedHours}:${formattedMinutes}`;
              break;
            }
            case 'DATE': {
              if (!fieldToRender.value) {
                break;
              }

              fieldToRender.value = new Date(fieldToRender.value).toLocaleDateString(LOCALE);
              break;
            }
            case 'TIME': {
              if (!fieldToRender.value) {
                break;
              }

              fieldToRender.value = fieldToRender.value.replace('.000Z', '');
              break;
            }
            case 'CURRENCY': {
              fieldToRender.formatter = 'currency';
              fieldToRender.type = 'number';
              break;
            }
            case 'URL': {
              fieldToRender.renderGeneric = false;
              fieldToRender.renderLink = true;
              fieldToRender.url = `https://${fieldToRender.value}`;
              break;
            }
            case 'EMAIL': {
              fieldToRender.renderGeneric = false;
              fieldToRender.renderLink = true;
              fieldToRender.url = `mailto:${fieldToRender.value}`;
              break;
            }
            case 'PHONE': {
              fieldToRender.renderGeneric = false;
              fieldToRender.renderLink = true;
              fieldToRender.url = `tel:${fieldToRender.value}`;
              break;
            }
            case 'PERCENT': {
              fieldToRender.value = `${fieldToRender.value}%`;
              break;
            }
            case 'STRING':
            case 'TEXTAREA': {
              fieldToRender.renderGeneric = false;
              fieldToRender.renderText = true;
              break;
            }
            default:
          }

          this.sectionFields.push(fieldToRender);
        });
      })
      .finally(() => {
        this.showSpinner = false;
      });
  }
}
