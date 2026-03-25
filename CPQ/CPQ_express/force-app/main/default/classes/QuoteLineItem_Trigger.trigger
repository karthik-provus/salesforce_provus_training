trigger QuoteLineItem_Trigger on QuoteLineItem (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        QuoteLineItemHandler.handleBeforeInsertUpdate(Trigger.new);
    }
}