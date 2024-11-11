/**
 * @description This class is used to schedule MaskSObjectBatch class
 */
public with sharing class MaskSObjectBatchSchedulable implements Schedulable{
	public void execute(SchedulableContext sc) {
		if(!Test.isRunningTest()) Database.executeBatch(new MaskSObjectBatch(true));
	}
}