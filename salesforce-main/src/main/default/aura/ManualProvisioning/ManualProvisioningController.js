({
	manualProvisioning : function(component, event, helper) {
		var action = component.get("c.manualProvision");
		action.setParams({recordId: component.get("v.recordId")});
		action.setCallback(this, function(response){
            component.set("v.showWarning",false);
			var state = response.getState();
			var rtnvalue = response.getReturnValue();
			var successMsg = 'HUB Provisioning in process.';
			if (rtnvalue !== 'Success') {
				component.set("v.errorMessage",rtnvalue);
				component.set("v.showSuccess",false);
				component.set("v.showError",true);
			} else if (rtnvalue === "Success") {
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
	showSpinner: function(component, event, helper) { // this function automatic call by aura:waiting event
		component.set("v.Spinner", true); // make Spinner attribute true for display loading spinner
	},
	hideSpinner : function(component,event,helper){  // this function automatic call by aura:doneWaiting event
		component.set("v.Spinner", false);  // make Spinner attribute to false for hide loading spinner
	}
})