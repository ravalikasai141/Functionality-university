const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: ['<rootDir>/.localdevserver'],
  moduleNameMapper: {
    '^@salesforce/apex$': '<rootDir>/src/test/jest-mocks/apex',
    '^@salesforce/schema$': '<rootDir>/src/test/jest-mocks/schema',
    '^lightning/navigation$': '<rootDir>/src/test/jest-mocks/lightning/navigation',
    '^lightning/platformShowToastEvent$': '<rootDir>/src/test/jest-mocks/lightning/platformShowToastEvent',
    '^lightning/uiRecordApi$': '<rootDir>/src/test/jest-mocks/lightning/uiRecordApi',
    '^lightning/messageService$': '<rootDir>/src/test/jest-mocks/lightning/messageService',
    '^lightning/actions$': '<rootDir>/src/test/jest-mocks/lightning/actions',
    '^lightning/alert$': '<rootDir>/src/test/jest-mocks/lightning/alert',
    '^lightning/confirm$': '<rootDir>/src/test/jest-mocks/lightning/confirm',
    '^lightning/prompt$': '<rootDir>/src/test/jest-mocks/lightning/prompt',
    '^lightning/modal*': '<rootDir>/src/test/jest-mocks/lightning/modal'
  }
};
