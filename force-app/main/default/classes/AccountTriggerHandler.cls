public class AccountTriggerHandler {
    public void beforeInsert(List<Account> newAccounts){
        for(Account newAccount: newAccounts){
            AccountServices.processBeforeInsert(newAccount);

        }
    }
    public void beforeUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountMap){
        for(Account newAccount: newAccounts){
            Account oldAccount = oldAccountMap.get(newAccount.Id);
            AccountServices.processBeforeUpdate(newAccount, oldAccount);

        }
    }
}