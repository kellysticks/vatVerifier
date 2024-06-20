public with sharing class AccountServices {
    private static final String COUNTRY_CODE_SWITZERLAND = 'CH';
    /**
     * Processes new Account records before they are inserted.
     * Calls a future method to verify EU VAT.
    */
    public static void processBeforeInsert(Account newAccount) {
        AccountServices.verifyVAT(newAccount);
    }
    /**
     * Processes Account records before they are updated.
     * Verifies EU VAT if the Tax_Vat_Id__c field has changed.
    */
    public static void processBeforeUpdate(Account newAccount, Account oldAccount){
        if(newAccount.Tax_Vat_Id__c != oldAccount.Tax_Vat_Id__c){
            AccountServices.verifyVAT(newAccount);
        }

    }
    //For EU countries, invokes VATVerificationServices future callout method
    //For non-EU countries (Switzerland), validates format only
    public static void verifyVAT(Account account){
        String countryCode = AccountServices.determineAndSelectAddress(account);
        if(!String.isBlank(countryCode)){
            if(countryCode == COUNTRY_CODE_SWITZERLAND){
                //ADD CHECK FOR SWIZTERLAND FORMAT
            } else {
                VATVerificationServices.futureMethodVerifyEUVat(countryCode, account.Tax_Vat_Id__c, account.Name, account.Id);
            }
        } else {
            System.debug('Country code not retrieved.');
        }

    }
    //Determines and selects the country code based on account address preference.
    public static String determineAndSelectAddress(Account account){
        String countryCode;
        String addressPreference = AccountServices.retrieveAddressPreference();
        switch on addressPreference{
            when 'Billing'{
                return account.BillingCountryCode;
            }
            when 'Shipping'{
                return account.ShippingCountryCode;
            }
            when else {
                System.debug('Unknown address preference');
                return null;
            }
        }
    }


    // Retrieves the address preference for VAT verification from custom metadata.
    public static String retrieveAddressPreference(){
        String addressPref;
        List<Account_Setting__mdt> accSettings = [SELECT MasterLabel, DeveloperName, VATAddressPreference__c FROM Account_Setting__mdt WHERE DeveloperName = 'Account_VAT_Address_Preference'];
        if(!accSettings.isEmpty()){
            addressPref = accSettings[0].VATAddressPreference__c;
            System.debug('Billing preference retrieved for VAT Address Preference');
        } else {
            System.debug('No setting found for VAT Address Preference');
        }
        return addressPref;
    }
}