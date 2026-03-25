trigger QuoteTrigger on Quote (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        QuoteTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}