import { LightningElement, api, track } from 'lwc';
import startReview from '@salesforce/apex/ApplicationReviewController.startReview';
import startFinalReview from '@salesforce/apex/ApplicationReviewController.startFinalReview';

export default class ReviewApplicationUnavailable extends LightningElement {
  @api stage;

  @api opportunityId;

  @api status;

  @api resubmissionDate;

  @track statusMessage;

  @track startReviewAllowed;

  @track startAcceptanceReviewAllowed;

  @track showBanner;

  @track error;

  @track loading;

  async connectedCallback() {
    this.state();
  }

  async startReview() {
    this.loading = true;

    try {
      await startReview({ opportunityId: this.opportunityId });
      this.dispatchEvent(new CustomEvent('review'));
    } catch (e) {
      this.error = 'Unable to start review, please try again';
    } finally {
      this.loading = false;
    }
  }

  async startAcceptanceReview() {
    this.loading = true;

    try {
      await startFinalReview({ opportunityId: this.opportunityId });
      this.dispatchEvent(new CustomEvent('review'));
    } catch (e) {
      this.error = 'Unable to start review, please try again';
    } finally {
      this.loading = false;
    }
  }

  state() {
    this.showBanner = true;

    switch (this.stage) {
      default:
        this.statusMessage =
          'This application is not ready for review, it must be in the BPP Review status before it can be reviewed';
        break;
      case 'BPP Review':
        if (this.status === 'Not Started') {
          if (this.resubmissionDate) {
            this.statusMessage = `This application was resubmitted following information provided by the applicant on ${this.getSubmissionDate()}`;
          } else {
            this.statusMessage =
              'The Review for this application has not yet been started, you can start a review for this by clicking the button below.';
          }
          this.startReviewAllowed = true;
          this.showBanner = false;
        } else if (this.status === 'Awaiting Information') {
          this.statusMessage =
            'This application is currently in Awaiting Information stage, feedback has been passed to the student.';
        }
        break;
      case 'Line Manager Review':
        this.statusMessage = 'This application has already passed review stage. It can no longer be edited.';
        break;
      case 'Acceptance':
        if (this.status === 'New') {
          this.statusMessage = 'To begin the final review process use the button below.';
          this.startAcceptanceReviewAllowed = true;
          this.showBanner = false;
        } else {
          this.statusMessage = 'This application has already passed review stage. It can no longer be edited.';
        }
        break;
    }
  }

  getSubmissionDate() {
    const dt = new Date(this.resubmissionDate);

    return dt.toLocaleDateString('en-GB', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  }
}
