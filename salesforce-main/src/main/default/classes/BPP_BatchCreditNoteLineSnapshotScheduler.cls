global class BPP_BatchCreditNoteLineSnapshotScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        BPP_BatchCreditNoteLineSnapshot myBatch = new BPP_BatchCreditNoteLineSnapshot(System.today());
        ID batchProcessId = Database.executeBatch(myBatch);     
    }
}