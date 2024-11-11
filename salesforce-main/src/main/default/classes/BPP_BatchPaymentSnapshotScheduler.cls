global class BPP_BatchPaymentSnapshotScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        BPP_BatchPaymentSnapshot myBatch = new BPP_BatchPaymentSnapshot(System.today());
        ID batchProcessId = Database.executeBatch(myBatch);    
    }
}