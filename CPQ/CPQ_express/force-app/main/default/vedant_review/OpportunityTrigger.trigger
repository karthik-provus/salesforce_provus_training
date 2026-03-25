trigger OpportunityTrigger on Opportunity (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}