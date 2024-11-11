({
	myAction : function(component, event, helper) {
        var action = component.get("c.emailflagcheck");
        action.setParams({
            recordId: component.get("v.recordId")
        });
       action.setCallback(component, function(response) {
           //alert("From server: " + response.getReturnValue());
           //$A.get('e.force:refreshView').fire(); 
           //window.location.reload()
          if(response.getReturnValue() == true)
          {
              $A.get('e.force:refreshView').fire(); 
          }
        }); 
        $A.enqueueAction(action);
         
    }
   
})