({
	 callProfilejscontroller : function(component, event, helper) {    
        
           var action = component.get("c.performCompanyProfileIdCallout");        
        action.setParams({
            recordId: component.get("v.recordId")
        });
         
        action.setCallback(this, function(response){
            var state = response.getState();
            var rtnvalue = response.getReturnValue();
            var successMsg ='Profile Id created Successfully';
            alert(rtnvalue);
            if (rtnvalue === "Success") {
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
            
            else if(rtnvalue === "Atleast One Active Billing Address is Required"){
                component.set("v.showSuccess",false);
                component.set("v.showError",true);
                component.set("v.errorMessage",rtnvalue);   
            }
            
            else if (rtnvalue === "Profile Company ID already Exits") {
                component.set("v.showSuccess",false);
                component.set("v.showError",true);
                component.set("v.errorMessage",rtnvalue); 
                }
                else if(rtnvalue !== 'Success'){
                    component.set("v.showSuccess",false);
                    component.set("v.showError",true);
                component.set("v.errorMessage",rtnvalue);
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