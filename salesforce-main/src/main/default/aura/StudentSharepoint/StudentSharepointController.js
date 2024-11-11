({
	openActionWindow : function(component, event, helper) {
        var recid = component.get("v.recordId");
		var URL = "https://bppserviceslimited.sharepoint.com/sites/student-documentation/Documents/Forms/AllItems.aspx?FolderCTID=0x0120006753B799F5A0B74699D4314A9A490ACD&viewid=44163286%2Df9ff%2D4c51%2D8ec9%2D63b30ab11c64&id=%2Fsites%2Fstudent%2Ddocumentation%2FDocuments%2FQA%2F"+recid; 
        window.open(URL);
        window.setTimeout(
            $A.getCallback(function() {
                $A.get("e.force:closeQuickAction").fire();
                
            }),500
        );
	}
})