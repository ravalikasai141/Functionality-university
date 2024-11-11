global class BPP_BatchInvoiceLineSnapshotScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        BPP_BatchInvoiceLineSnapshot myBatch = new BPP_BatchInvoiceLineSnapshot(System.today());
        ID batchProcessId = Database.executeBatch(myBatch);     
    }
}