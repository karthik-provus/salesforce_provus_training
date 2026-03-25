@isTest
private class QuoteLineItemTriggerTest {
    
    @testSetup
static void setupData() {
    // Create Category
    Product_Category__c cat = new Product_Category__c(Name = 'Software', Max_Discount_Allowed__c = 60);
    insert cat;

    // Create Product
    Product2 prod = new Product2(Name = 'Cloud App', Product_Category__c = cat.Id, IsActive = true);
    insert prod;

    // Create ONE Pricebook Entry
    insert new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = prod.Id,
        UnitPrice = 100,
        IsActive = true
    );
}

@isTest
static void testDynamicDiscountThreshold() {
    // 1. Fetch the existing data (Don't insert new ones!)
    PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
    
    // 2. Create your Account/Opp/Quote
    Account acc = new Account(Name = 'Test'); insert acc;
    Opportunity opp = new Opportunity(Name = 'Test', StageName = 'Prospecting', CloseDate = System.today(), AccountId = acc.Id); insert opp;
    
    Quote q = new Quote(
        Name = 'Test Quote', 
        OpportunityId = opp.Id, 
        Pricebook2Id = Test.getStandardPricebookId()
    );
    insert q;

    // 3. Insert the QLI
    QuoteLineItem qli = new QuoteLineItem(
        QuoteId = q.Id,
        PricebookEntryId = pbe.Id, // Use the ID we fetched
        Quantity = 1,
        UnitPrice = 100,
        Discount = 55
    );

    Test.startTest();
    Database.SaveResult result = Database.insert(qli, false);
    Test.stopTest();

    System.assert(result.isSuccess(), 'Error: ' + (result.isSuccess() ? '' : result.getErrors()[0].getMessage()));
}
    


    
    
}