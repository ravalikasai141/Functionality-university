@isTest
public class MaskSObjectBatchTest {

	@TestVisible private static String NAME = 'Test Mask Data';
	private static String PHONE = '0606060606';
	private static String LUHN = '48399322600057';
	private static String LASTNAME = 'Doe';
	private static String ASSISTANTNAME = 'Jane DOE';
	private static String TESTLABEL = 'TEST';
	private static String EMAIL = 'jdoe@masksobject.com';
	private static String TITLE = 'Account Executive';

	/**
	 * @description This method creates required data to test the framework, it is static to be used in
	 *  MaskSObjectPostCopyTest
	 */
	public static void createTestData(){

		List<MaskSObject__c> sobjMask = new List<MaskSObject__c>{
			new MaskSObject__c(Sequence__c = 1, APIName__c = 'Account'),
			new MaskSObject__c(Sequence__c = 2, APIName__c = 'Contact', WhereClause__c = 'AssistantName != null', BatchSize__c = 1600)
		};
		insert sobjMask;

		List<MaskSObjectField__c> fieldMask = new List<MaskSObjectField__c>{
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(0).Id, APIName__c = 'Name',
				Mode__c = MaskSObjectConstants.MODE_BOTH,  Action__c = MaskSObjectConstants.ACTION_OBFUSCATE),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(0).Id, APIName__c = 'Phone',
				Mode__c = MaskSObjectConstants.MODE_BOTH,  Action__c = MaskSObjectConstants.ACTION_OBFUSCATE),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(0).Id, APIName__c = 'Description',
				Mode__c = MaskSObjectConstants.MODE_BOTH,  Action__c = MaskSObjectConstants.ACTION_LUHN),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'FirstName',
				Mode__c = MaskSObjectConstants.MODE_BOTH,  Action__c = MaskSObjectConstants.ACTION_REPLACE,
				ActionType__c = MaskSObjectConstants.ACTION_TYPE_DICT_FIRST),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'LastName',
				Mode__c = MaskSObjectConstants.MODE_BOTH,  Action__c = MaskSObjectConstants.ACTION_REPLACE,
				ActionType__c = MaskSObjectConstants.ACTION_TYPE_DICT_LAST),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'AssistantName',
				Mode__c = MaskSObjectConstants.MODE_BOTH,  Action__c = MaskSObjectConstants.ACTION_REPLACE,
				ActionType__c = MaskSObjectConstants.ACTION_TYPE_HARDCODED,
				Value__c = TESTLABEL),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'HomePhone',
				Mode__c = MaskSObjectConstants.MODE_BOTH,  Action__c = MaskSObjectConstants.ACTION_ERASE),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'Title',
				Mode__c = MaskSObjectConstants.MODE_BOTH,  Action__c = MaskSObjectConstants.ACTION_RANDOMIZE),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'Email',
				Mode__c = MaskSObjectConstants.MODE_BOTH,  Action__c = MaskSObjectConstants.ACTION_REPLACE,
				ActionType__c = MaskSObjectConstants.ACTION_TYPE_DICT_EMAIL)
		};
		insert fieldMask;

		insert new Account(Name = NAME, Phone = PHONE, Description = LUHN);
		insert new Contact(FirstName = 'John', LastName = LASTNAME, AssistantName = ASSISTANTNAME, Email = EMAIL, HomePhone = PHONE);
	}

	@isTest
	static void maskSobjectTest(){
		createTestData();

		Test.startTest();
		Database.executeBatch(new MaskSObjectBatch());
		Test.stopTest();

		Account acc = [SELECT Id, Name, Phone, Description FROM Account LIMIT 1];
		System.assertNotEquals(NAME, acc.Name, 'The account Name should be masked');
		System.assertNotEquals(PHONE, acc.Phone, 'The account Phone should be masked');
		System.assertNotEquals(LUHN, acc.Description, 'The account Description should be masked');

		Contact cont = [SELECT Id, FirstName, LastName, AssistantName, Email, HomePhone, Title FROM Contact LIMIT 1];
		System.assertNotEquals(LASTNAME, cont.FirstName, 'The contact FirstName should be masked');
		System.assertNotEquals(LASTNAME, cont.LastName, 'The contact LastName should be masked');
		System.assertEquals(TESTLABEL, cont.AssistantName, 'The contact AssistantName should be replaced by ' + TESTLABEL);
		System.assertNotEquals(EMAIL, cont.Email, 'The contact Email should be masked');
		System.assertNotEquals(TITLE, cont.Title, 'The contact Title should be masked');
		System.assertEquals(null, cont.HomePhone, 'The contact HomePhone should be erased');

	}

	@isTest
	static void maskSobjectNameTest(){
		createTestData();

		Test.startTest();
		MaskSObjectUtils.executeBatch('Contact');
		Test.stopTest();

		Contact cont = [SELECT Id, LastName, AssistantName, Email FROM Contact LIMIT 1];
		System.assertNotEquals(LASTNAME, cont.LastName, 'The contact LastName should be masked');
		System.assertEquals(TESTLABEL, cont.AssistantName, 'The contact AssistantName should be replaced by ' + TESTLABEL);
		System.assertNotEquals(EMAIL, cont.Email, 'The contact Email should be masked');

		Account acc = [SELECT Id, Name, Phone FROM Account LIMIT 1];
		System.assertEquals(NAME, acc.Name, 'The account Name should not be masked');
		System.assertEquals(PHONE, acc.Phone, 'The account Phone should not be masked');
	}
}