@isTest
private class ConnectApiManagedTopicControllerTest {
    
    @isTest(SeeAllData=true)
    private static void itShouldReturnSubTopics() {
        // Try to get the Community ID for Live environment:
        String communityId = [Select Id from Network where Name = 'BPP Help Centre'].Id;
        
        Knowledge__kav ka = createNewArticleAsADraft('Test Article', 'Test Body', 'test');
        
        //Using ConnectApi.Topics.createTopic to create the topics as they cannot be created via standard insert operations
        ConnectApi.Topic topic 	  = createTopic(communityId, 'Test topic', 'topic description');
        ConnectApi.Topic subTopic = createTopic(communityId, 'Test subTopic', 'subTopic description');
        
        createTopicAssignment(subTopic.Id, ka.Id);
        
        //Using ConnectApi.ManagedTopics.createManagedTopic to create the Navigational topics as they cannot be created via standard insert operations
        ConnectApi.ManagedTopic parentTopic = createNavigationalParentTopic(communityId,topic.Id, ConnectApi.ManagedTopicType.Navigational);
        createNavigationalChildTopic(communityId,subTopic.Id, ConnectApi.ManagedTopicType.Navigational, parentTopic.Id);
        
        Test.startTest();
        List<ConnectApiManagedTopicController.SubTopicWrapper> subTopicWrapper = ConnectApiManagedTopicController.getSubTopics(topic.Id);
        Test.stopTest();
        System.assertEquals(1, subTopicWrapper.size());
        
    }
    
    private static Knowledge__kav createNewArticleAsADraft(String title, String summary, String urlName) {
        
        Knowledge__kav newArticle = new Knowledge__kav(
            Title = title,
            Summary = summary,
            UrlName = urlName);
        
        insert newArticle;
        
        return [SELECT Id,Title, KnowledgeArticleId FROM Knowledge__kav WHERE Id =: newArticle.Id];
    }
    
    private static ConnectApi.Topic createTopic(String communityId, String name, String description) { 
        return ConnectApi.Topics.createTopic(communityId, name, description);
    }
    
    private static void createTopicAssignment(String topicId, String articleId) { 
        TopicAssignment ta = new TopicAssignment(
            TopicId = topicId, 
            EntityId = articleId);
        insert ta;
    }
    
    private static ConnectApi.ManagedTopic createNavigationalParentTopic(String communityId, String recordId, ConnectApi.ManagedTopicType managedTopicType) { 
        return ConnectApi.ManagedTopics.createManagedTopic(communityId,recordId, ConnectApi.ManagedTopicType.Navigational);
    }
    
    private static void createNavigationalChildTopic(String communityId, String recordId, ConnectApi.ManagedTopicType managedTopicType, String parentId) { 
        ConnectApi.ManagedTopics.createManagedTopic(communityId,recordId, ConnectApi.ManagedTopicType.Navigational, parentId);
    }
    
}