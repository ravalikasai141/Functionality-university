({
	 callsubmitjscontroller : function(component, event, helper) {    
        
           var action = component.get("c.submitApp");        
        action.setParams({
            recordId: component.get("v.recordId")
        });
         
        action.setCallback(this, function(response){
            var state = response.getState();
            var rtnvalue = response.getReturnValue();
            var successMsg ='Submission Successful';
            //alert('@@rtnvalue@@'+rtnvalue);
            //alert('@@v.errorMessage@@'+v.errorMessage);
            if(rtnvalue !== 'Success')
            { 
                component.set("v.errorMessage",rtnvalue);
                component.set("v.showSuccess",false);
                component.set("v.showError",true);   
            }
            
            else if (rtnvalue === "Success") {
                component.set("v.Spinner",false);
                $A.get('e.force:refreshView').fire();
                component.set("v.showError",false);
                component.set("v.showSuccess",true);
                component.set("v.successMessage",successMsg);
                window.setTimeout(
                    $A.getCallback(function() {
                        $A.get("e.force:closeQuickAction").fire();
                         
                    }),5000
                );
               
            }
            
        });
        $A.enqueueAction(action);
    },
    // this function automatic call by aura:waiting event  
    showSpinner: function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
   },
    
 // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
       component.set("v.Spinner", false);
    }
})