public class ApplyTaxCreditNote {
    
    
    @InvocableMethod(label='Apply Tax' description='Mimic the Apply Tax CPQ button on the credit note.')
    public static void getAccountNames(List<ID> creditNoteIds) 
    {
        String result;
        for (Id creditNoteId : creditNoteIds) 
        {
            result = blng.CreditNoteAPI.postTaxForCreditNote(creditNoteId);
            System.debug('Credit Note Id : ' + creditNoteId);
            System.debug('result Post Tax : ' + result);
        }
    }
}