@isTest
private class OpportunityHandlerTest {
    @isTest
    static void testAutoQuoteCreation() {
        // 1. Setup Data
        Account acc = new Account(Name = 'Automation Test Ltd');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Big Deal',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(10),
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opp;

        // 2. Execute Action
        Test.startTest();
        opp.StageName = 'Proposal/Price Quote';
        update opp;
        Test.stopTest();

        // 3. Verify Result
        List<Quote> createdQuotes = [SELECT Id, Name FROM Quote WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, createdQuotes.size(), 'One quote should have been automatically created.');
        System.assert(createdQuotes[0].Name.contains('Automated Proposal'));
    }
}