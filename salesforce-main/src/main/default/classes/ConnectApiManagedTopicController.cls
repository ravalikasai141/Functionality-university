public without sharing class ConnectApiManagedTopicController {
    
    @AuraEnabled(cacheable=true)
    public static List<SubTopicWrapper> getSubTopics(Id topicId){
        
        Map<Id, List<ConnectApi.Topic>> subTopicMap = new Map<Id,  List<ConnectApi.Topic>>();
        Map<Id, Integer> subTopicKnowledgeArticleCountMap = new Map<Id,  Integer>();
        List<ConnectApi.Topic> subTopicList = new List<ConnectApi.Topic>();
        List<SubTopicWrapper> returnList = new List<SubTopicWrapper>();
        Set<Id> subTopicIdSet = new Set<Id>();
        
        // Get a managed topic, including its parent and children managed topics 
        List<ConnectApi.ManagedTopic> topics = getManagedTopics();
        
        // Loop through the parent topics
        for (ConnectApi.ManagedTopic managedTopic : topics) {
            
            if(((ConnectApi.Topic)managedTopic.topic).Id == topicId){
                // List of sub topics
                for (ConnectApi.ManagedTopic childManagedTopic : managedTopic.children) {
                    subTopicIdSet.add((childManagedTopic.topic).Id);
                    subTopicList.add((childManagedTopic.topic));
                }
                
                subTopicMap.put((managedTopic.topic).Id, subTopicList);
                break;
            }
        }
        
        if(!subTopicIdSet.isEmpty()){
            // Get the Knowledge articles for the sub topics 
            subTopicKnowledgeArticleCountMap = getKnowledgeArticleCount(subTopicIdSet);
            
            for(ConnectApi.Topic subTopic : subTopicMap.get(topicId)){
                SubTopicWrapper wrapper = new SubTopicWrapper();
                wrapper.subTopicId = subTopic.id;
                wrapper.subTopic = subTopic;
                wrapper.knowledgeArticleCount = subTopicKnowledgeArticleCountMap.get(subTopic.id);
                returnList.add(wrapper);
            }
        }
        return returnList;
    }   
    
    private static List<ConnectApi.ManagedTopic> getManagedTopics() {
        Id commId = [SELECT Id, name FROM Network WHERE name = 'BPP Help Centre'].Id; 
        ConnectAPI.ManagedTopicCollection mTopics = ConnectAPI.ManagedTopics.getManagedTopics(
            commId,
            ConnectApi.ManagedTopicType.Navigational,
            2);
        return mTopics.managedTopics;
    }
    
    private static Map<Id,  Integer> getKnowledgeArticleCount(Set<Id> subTopicIdSet){
        
        Map<Id, Integer> subTopicKnowledgeArticleCountMap = new Map<Id,  Integer>();
        Map<Id, List<Knowledge__kav>> subTopicKnowledgeArticleMap = new Map<Id,  List<Knowledge__kav>>();
        Map<Id, Knowledge__kav> knowledgeArticleMap;
        Set<Id> knowledgeArticleIdSet = new Set<Id>();
        
        // Get list of knowledge articles assigned to topics
        List<TopicAssignment> topicAssignmentList = [SELECT Id,Topic.Name, EntityId, Entity.Name FROM TopicAssignment WHERE Topic.Id IN :subTopicIdSet];
        for (TopicAssignment ta : topicAssignmentList) {
            knowledgeArticleIdSet.add(ta.EntityId);
        } 
		
        // Get map of knowledge articles that are online
        
        knowledgeArticleMap = new Map<Id, Knowledge__kav>([SELECT Id FROM Knowledge__kav WHERE PublishStatus = 'Online' AND Id IN :knowledgeArticleIdSet]);
        
        for (TopicAssignment ta : topicAssignmentList) {
            if(!subTopicKnowledgeArticleMap.containskey(ta.Topic.Id)){
                subTopicKnowledgeArticleMap.put(ta.Topic.Id, new List<Knowledge__kav>());
            }
            
            If(knowledgeArticleMap.containsKey(ta.EntityId)){
                subTopicKnowledgeArticleMap.get(ta.Topic.Id).add(knowledgeArticleMap.get(ta.EntityId)); 
            }
        }
        for (String subTopics : subTopicKnowledgeArticleMap.keySet()) {
            subTopicKnowledgeArticleCountMap.put(subTopics, subTopicKnowledgeArticleMap.get(subTopics).size());
        }
        return subTopicKnowledgeArticleCountMap;
    }
    
    @TestVisible
    private class SubTopicWrapper{
        @AuraEnabled
        public Id subTopicId;
        @AuraEnabled
        public ConnectApi.Topic subTopic;
        @AuraEnabled
        public Integer knowledgeArticleCount;
    }
}