import { createElement } from 'lwc';
import SubmitApplication from 'c/submitApplication';

import submitApplicationHandler from '@salesforce/apex/SubmitApplicationHandler.checkApplication';

jest.mock(
  '@salesforce/apex/SubmitApplicationHandler.checkApplication',
  () => {
    return { default: jest.fn() };
  },
  { virtual: true }
);

describe('c-submit-application', () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('should submit application', () => {
    const element = createElement('c-submit-application', {
      is: SubmitApplication
    });
    document.body.appendChild(element);

    submitApplicationHandler.mockResolvedValue('Application Submitted Successfully');
    element.recordId = 'ID-123';

    expect(submitApplicationHandler).toHaveBeenCalled();
  });
});
