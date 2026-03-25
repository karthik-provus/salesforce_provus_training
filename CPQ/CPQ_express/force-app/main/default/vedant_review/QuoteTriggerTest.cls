@isTest
private class QuoteTriggerTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Provus Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        
        Product_Category__c mockCategory = new Product_Category__c(
                Name = 'Test Category - 2',
            	Max_Discount_Allowed__c = 15
            );
        insert mockCategory;
        
        Id pricebookId = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name = 'Cloud Services', IsActive = true, Product_Category__c = mockCategory.Id);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
    }

    @isTest
    static void testEmptyQuoteSubmission() {
        Id pricebookId = Test.getStandardPricebookId();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Empty Quote', OpportunityId = opp.Id, Pricebook2Id = pricebookId);
        insert q;

        Test.startTest();
        q.Status = 'Submitted';
        Database.SaveResult result = Database.update(q, false);
        Test.stopTest();

        // Verify the error for empty quotes
        System.assert(!result.isSuccess(), 'Submission should fail for empty quotes');
        System.assert(result.getErrors()[0].getMessage().contains('You cannot submit an empty quote'));
    }

    @isTest
    static void testAutoApprovalPath() {
        Id pricebookId = Test.getStandardPricebookId();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        Quote q = new Quote(Name = 'Clean Quote', OpportunityId = opp.Id, Status = 'Draft', Pricebook2Id = pricebookId);
        insert q;

        // Add a product with NO violation (10% discount)
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Discount = 10
        );
        insert qli;

        Test.startTest();
        q.Status = 'Submitted';
        update q;
        Test.stopTest();

        Quote updatedQ = [SELECT Status, RecordTypeId FROM Quote WHERE Id = :q.Id];
        Id approvedId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Approved').getRecordTypeId();

        System.assertEquals('Approved', updatedQ.Status, 'Status should jump to Approved');
        System.assertEquals(approvedId, updatedQ.RecordTypeId, 'Record Type should be Approved');
    }

    @isTest
    static void testManualApprovalPath() {
        Id pricebookId = Test.getStandardPricebookId();

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        Quote q = new Quote(Name = 'Violated Quote', OpportunityId = opp.Id, Status = 'Draft', Pricebook2Id = pricebookId);
        insert q;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Discount = 20
        );
        insert qli;

        Test.startTest();
        q.Status = 'Submitted';
        update q;
        Test.stopTest();

        Quote updatedQ = [SELECT Status, Approval_Required__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals('Submitted', updatedQ.Status, 'Status should stay Submitted');
        System.assertEquals(true, updatedQ.Approval_Required__c, 'Approval Required flag should be true');
    }

    @isTest
    static void testRejectionReset() {
        Id pricebookId = Test.getStandardPricebookId();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        Quote q = new Quote(Name = 'Clean Quote', OpportunityId = opp.Id, Status = 'Draft', Pricebook2Id = pricebookId);
        insert q;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Discount = 78
        );
        insert qli;

        Test.startTest();
        q.Status = 'Rejected';
        update q;
        Test.stopTest();

        Quote updatedQ = [SELECT Status, RecordTypeId FROM Quote WHERE Id = :q.Id];
        Id draftId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Draft').getRecordTypeId();

        System.assertEquals('Draft', updatedQ.Status, 'Status should reset to Draft');
        System.assertEquals(draftId, updatedQ.RecordTypeId, 'Record Type should reset to Draft');
    }
    
    @isTest
static void testManagerApprovalSuccess() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    Id pricebookId = Test.getStandardPricebookId();
    Id approvedId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Approved').getRecordTypeId();
    PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

    // 1. Insert as DRAFT first (This avoids the validation rule)
    Quote q_new = new Quote(
        Name = 'Manual Approval Quote', 
        OpportunityId = opp.Id, 
        Status = 'Draft', // Start as Draft
        Pricebook2Id = pricebookId
    );
    insert q_new;
    
    // 2. Add the product while it is still a Draft
    QuoteLineItem qli = new QuoteLineItem(
        QuoteId = q_new.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100,
        Discount = 78
    );
    insert qli;

    // 3. Move it to Submitted (Simulating the Sales Rep's action)
    q_new.Status = 'Submitted';
    update q_new;

    Test.startTest();
    // 4. NOW simulate the Manager hitting 'Approve'
    q_new.Status = 'Approved';
    update q_new;
    Test.stopTest();

    // 5. Verify the results
    Quote updatedQ = [SELECT Status, RecordTypeId, Approval_Required__c FROM Quote WHERE Id = :q_new.Id];
    
    System.assertEquals('Approved', updatedQ.Status);
    System.assertEquals(approvedId, updatedQ.RecordTypeId);
    System.assertEquals(false, updatedQ.Approval_Required__c);
}
}