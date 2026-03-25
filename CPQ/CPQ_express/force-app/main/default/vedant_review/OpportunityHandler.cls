public class OpportunityHandler {
    public static void handleAfterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        List<Quote> quotesToCreate = new List<Quote>();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMap.get(opp.Id);

            // Condition: Stage changed specifically to 'Proposal/Price Quote'
            if (opp.StageName == 'Proposal/Price Quote' && oldOpp.StageName != 'Proposal/Price Quote') {
                quotesToCreate.add(new Quote(
                    Name = opp.Name + ' - Automated Proposal',
                    OpportunityId = opp.Id,
                    Pricebook2Id = opp.Pricebook2Id, // Syncs the Pricebook context
                    Status = 'Draft',
                    ExpirationDate = System.today().addDays(30) // Set a 30-day window
                ));
            }
        }

        if (!quotesToCreate.isEmpty()) {
            insert quotesToCreate;
        }
    }
}