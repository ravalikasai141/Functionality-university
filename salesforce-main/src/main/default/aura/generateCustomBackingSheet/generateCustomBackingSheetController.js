({
	doInit: function(component, event, helper) {   
        var action = component.get("c.generateCustomBackingSheet");        
        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var apexResponse = response.getReturnValue();
            var successMsg = 'Backing Sheet created successfully!';
            if (apexResponse === 'Success!'){
                component.set("v.Spinner",false);
                $A.get('e.force:refreshView').fire();
                component.set("v.showError", false);
                component.set("v.showSuccess", true);
                component.set("v.successMessage", successMsg);
                window.setTimeout(
                    $A.getCallback(function() { $A.get("e.force:closeQuickAction").fire(); }),5000
                );
            } else {
                component.set("v.showSuccess", false);
                component.set("v.showError", true);
                component.set("v.errorMessage", apexResponse);
            }
        });
        $A.enqueueAction(action);
    },
    showSpinner: function(component, event, helper) {
        component.set("v.Spinner", true); 
    },
    hideSpinner : function(component,event,helper){
        component.set("v.Spinner", false);
    }
})