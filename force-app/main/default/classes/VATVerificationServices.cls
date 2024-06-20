public class VATVerificationServices {
    private static final String COUNTRY_CODE_SWITZERLAND = 'CH';
    private static final String VAT_VALID = 'Valid';
    private static final String VAT_INVALID = 'Invalid';
    private static final String SWITZERLAND_REGEX = System.Label.Switzerland_Regex;
    private static final String EU_REGEX = System.Label.EU_Regex;
    private static final Pattern swissVatPattern = Pattern.compile(SWITZERLAND_REGEX);
    private static final Pattern euVatPattern = Pattern.compile(EU_REGEX);

    //For EU countries, validates and verifies Vat number
    //For non-EU countries (Switzerland), validates Vat number
    @InvocableMethod(label='Check VAT Verification in Flow')
    public static List<ReturnVariables> invokedMethod(List<InputVariables> inputs){
        //Get input variables
        String countryCode = inputs.get(0).countryCode;
        String vatNumber = inputs.get(0).vatNumber;

        //Set output variables
        Boolean vatFormatIsValid = false;
        Boolean vatIsVerified = false;

        //Validate vatNumber format
        vatFormatIsValid = validateVatNumber(countryCode, vatNumber);

        //If country is not Switzerland and vatNumber is valid, verify vatNumber (call VEIS Verification)
        if(vatFormatIsValid && countryCode != COUNTRY_CODE_SWITZERLAND){
            //Remove countryCode from vatNumber if included so VEIS API will execute
            String replacement = '';
            String updatedVatNumber = vatNumber.replace(countryCode, replacement);
            String vatResponse = VATVerificationServices.verifyEUVat(countryCode, updatedVatNumber);
            vatIsVerified = vatResponse == VAT_VALID ? true : false;
        }
        //Assign return variables
        List<ReturnVariables> returnVarsList = new List<ReturnVariables>();
        ReturnVariables returnVars = new ReturnVariables();
        returnVars.vatFormatIsValid = vatFormatIsValid;
        returnVars.vatIsVerified = vatIsVerified;
        returnVarsList.add(returnVars);
        return returnVarsList;

    }

    public class InputVariables{
        @InvocableVariable
        public String countryCode;

        @InvocableVariable 
        public String vatNumber;
    }

    public class ReturnVariables{
        @InvocableVariable
        public Boolean vatFormatIsValid;

        @InvocableVariable
        public Boolean vatIsVerified;
    }

    //Verify the vat number is verified with the VIES API
    public static String verifyEUVat(String countryCode, String vatNumber){
        //Create service instance
        ecEuropaEuTaxudViesServicesCheckva.checkVatPort service = new ecEuropaEuTaxudViesServicesCheckva.checkVatPort();
        //Call service and get response
        ecEuropaEuTaxudViesServicesCheckva.checkVatResponse_element response;
        try{
            response = service.checkVat(countryCode, vatNumber);
            if(response.valid){
                return VAT_VALID;
            } else {
                return VAT_INVALID;
            }
        }
        catch(Exception e){ 
            //Log error for debugging
            System.debug('Error: ' + e.getMessage());
            return 'An error occurred: ' + e.getMessage();
        }
    }

    //Validate that the vat number is a valid format
    public static Boolean validateVatNumber(String countryCode, String vatNumber){
        String vatRegex;
        String finalVatNumber;
        //Set regex pattern for non-EU countries (Switzerland)
        if(countryCode == COUNTRY_CODE_SWITZERLAND){
            vatRegex = String.valueOf(SWITZERLAND_REGEX);
            finalVatNumber = vatNumber;
        } 
        //Set regex pattern for EU countries
        else {
        //Remove special characters to account for different country VAT formats
        vatRegex = String.valueOf(EU_REGEX);
        finalVatNumber = VATVerificationServices.prepareVatNumber(countryCode, vatNumber);
        }
        
        Pattern pattern = Pattern.compile(vatRegex);
        Matcher matcher = pattern.matcher(finalVatNumber);
        
        return matcher.matches();

    }

    private static String prepareVatNumber(String countryCode, String vatNumber){
        String strippedVatNumber = VATVerificationServices.stripSpecialCharacters(vatNumber);
        //Handle scenario where vatNumber doesn't include country code so regex pattern can be evaluated
        if(!strippedVatNumber.contains(countryCode)){
            strippedVatNumber = countryCode + strippedVatNumber;
        }

        return strippedVatNumber;
    }

    //Strip special characters from Vat Number for regex check
    private static String stripSpecialCharacters(String vatNumber){
        //Create regex to remove punctuation
        String regex = '[-.●]';
        String replacement = '';

        //Remove punctuation from vatNumber for further validation
        String strippedNum = vatNumber.replaceAll(regex,replacement);
        return strippedNum;
    }

    @future(callout=true)
    public static void futureMethodVerifyEUVat(String countryCode, string vatNumber, String accountName, String accountId){
        //Create service instance
        ecEuropaEuTaxudViesServicesCheckva.checkVatPort service = new ecEuropaEuTaxudViesServicesCheckva.checkVatPort();
        //Call service and get response
        ecEuropaEuTaxudViesServicesCheckva.checkVatResponse_element response;
        try{
            response = service.checkVat(countryCode, vatNumber);
            if(!response.valid){
                Error_Log__c log = new Error_Log__c();
                log.Error_Body__c = 'Vat Verification: ' + response.valid + ' Vat Number: ' + vatNumber;
                log.Error_Field__c = 'Tax_Vat_Id__c';
                log.Error_Object__c = 'Account';
                log.Error_Record_Name__c = accountName;
                log.Error_Record_Id__c = accountId;
                insert log;
            } 
        }
        catch(Exception e){ 
            //Log error for debugging
            System.debug('Error: ' + e.getMessage());
        }
    }
}

