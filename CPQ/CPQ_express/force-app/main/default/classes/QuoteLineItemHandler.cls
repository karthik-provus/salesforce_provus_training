public class QuoteLineItemHandler {
    public static void handleBeforeInsertUpdate(List<QuoteLineItem> items) {
        Set<Id> pricebookEntryIds = new Set<Id>();

for (QuoteLineItem qli : items) {
    if (qli.PricebookEntryId != null) {
        pricebookEntryIds.add(qli.PricebookEntryId);
    }
}

Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>([
    SELECT Id, Product2Id, Product2.Product_Category__r.Max_Discount_Allowed__c
    FROM PricebookEntry
    WHERE Id IN :pricebookEntryIds
]);

        for (QuoteLineItem item : items) {

    if (item.Quantity <= 0) {
        item.Quantity.addError('Quantity must be a positive integer.');
        continue;
    }

    Decimal categoryLimit = 0;

    if (pbeMap.containsKey(item.PricebookEntryId)) {
        PricebookEntry pbe = pbeMap.get(item.PricebookEntryId);

        if (pbe.Product2.Product_Category__r != null) {
            categoryLimit = pbe.Product2.Product_Category__r.Max_Discount_Allowed__c;
        }
    }

    Decimal finalAllowedLimit = (categoryLimit > 50) ? categoryLimit : 50;

    if (item.Discount > finalAllowedLimit) {
        item.Discount.addError('Discount Violation! Max allowed is ' + finalAllowedLimit + '%.');
    }
}
        
    }
}