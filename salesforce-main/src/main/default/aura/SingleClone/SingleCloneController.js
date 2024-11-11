({
    doInit : function(component, event, helper) {
        var action = component.get("c.cloneSobject");
        action.setParams({"recordId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            var successMsg = 'Record cloned successfully!';
            if (state === "SUCCESS") {
                component.set("v.Spinner",false);
                component.set("v.showErrors",false);
                component.set("v.showSuccess",true);
                component.set("v.successMessage",successMsg);
                
                var sObjectEvent = $A.get("e.force:navigateToSObject");
                sObjectEvent.setParams({
                    "recordId": response.getReturnValue(),
                    "slideDevName": "detail"
                });
                sObjectEvent.fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    component.set("v.showSuccess",false);
                    component.set("v.showErrors",true);
                    component.set("v.errorMessage",errors[0].message);
                }
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