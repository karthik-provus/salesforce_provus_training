public class QuoteTriggerHandler {
    public static void handleBeforeUpdate(List<Quote> newQuotes, Map<Id, Quote> oldMap) {
        Id draftId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Draft').getRecordTypeId();
        Id submittedId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Submitted').getRecordTypeId();
        Id approvedId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Approved').getRecordTypeId();

        for (Quote newQuote : newQuotes) {
            Quote oldQuote = oldMap.get(newQuote.Id);

            // Rejection Path
            if (newQuote.Status == 'Rejected' && oldQuote.Status != 'Rejected') {
                newQuote.Status = 'Draft';
                newQuote.RecordTypeId = draftId;
                newQuote.Approval_Required__c = false;
            }

            // Approval Path
            if (newQuote.Status == 'Approved' && oldQuote.Status != 'Approved') {
                newQuote.RecordTypeId = approvedId;
                newQuote.Approval_Required__c = false;
            }

            // Submission Path
            if (newQuote.Status == 'Submitted' && oldQuote.Status == 'Draft') {
                if (newQuote.Violation_Count__c > 0) {
                    newQuote.RecordTypeId = submittedId; 
                    newQuote.Approval_Required__c = true;
                } else if (newQuote.Line_Item_Count__c > 0) { 
                    newQuote.Status = 'Approved';
                    newQuote.RecordTypeId = approvedId;
                    newQuote.Approval_Required__c = false;
                } else {
                    newQuote.addError('You cannot submit an empty quote.');
                }
            }
        }
    }
}