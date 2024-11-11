import { LightningElement, api, track } from 'lwc';
import autoPopulateReview from '@salesforce/apex/ApplicationReviewController.autoPopulateReview';
import submitReview from '@salesforce/apex/ApplicationReviewController.submitReview';

export default class ReviewApplicationComment extends LightningElement {
  @api opportunityId;

  @track commentRequired;

  @track comment;

  @track status;

  @track disabled = true;

  @track error;

  @track commentValid;

  @track commentError;

  feedbackRequired = false;

  reviewOptions = [
    { label: 'Pre-Approved', value: 'pre-approved' },
    { label: 'Feedback Required', value: 'feedback-required' }
  ];

  formats = ['bold', 'italic', 'underline', 'strike', 'link', 'list', 'indent', 'clean'];

  async handleCommentChange(event) {
    this.comment = event.target.value;
    this.validate();
  }

  async handleStatusChange(event) {
    this.status = event.target.value;

    if (this.status === 'feedback-required') {
      this.commentRequired = true;
    }

    this.validate();
  }

  async handleAutoFeedback() {
    const content = await autoPopulateReview();

    await this.handleStatusChange({ target: { value: 'feedback-required' } });

    this.comment = content;
    this.validate();
  }

  async handleSubmit() {
    this.disabled = true;
    this.error = null;

    // fire loading event to prevent any changes on pages
    this.dispatchEvent(new CustomEvent('loading'));
    // submit review
    try {
      await submitReview({
        opportunityId: this.opportunityId,
        comment: this.comment,
        feedbackRequired: this.feedbackRequired
      });

      this.dispatchEvent(new CustomEvent('success'));
    } catch (e) {
      this.error = e.body.message;
      this.dispatchEvent(new CustomEvent('error'));
    } finally {
      this.disabled = false;
    }
  }

  async validate() {
    this.disabled = true;
    this.commentValid = true;
    this.commentError = null;

    if (this.status === 'pre-approved') {
      this.disabled = false;
      this.feedbackRequired = false;
    } else if (this.status === 'feedback-required') {
      this.feedbackRequired = true;
      if (this.comment) {
        this.disabled = false;
      }
    }

    if (this.comment && this.comment.length > 5000) {
      this.disabled = true;
      this.commentValid = false;
      this.commentError = 'Review comment must be under 5000 characters';
    }
  }
}
