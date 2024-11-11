global class OrderPlugin implements SBQQ.OrderManagementPlugin {
    public Date getOrderStartDate(Id quoteId) {
        SBQQ__Quote__c quote = [
            SELECT Id, SBQQ__Account__r.Billing_Cycle_Start_Month__c, SBQQ__Account__r.Billing_Frequency__c, SBQQ__Account__r.Billing_Type__c
            FROM SBQQ__Quote__c WHERE Id = :quoteId LIMIT 1
        ];
        
        Date todaysDate = (!Test.isRunningTest() ? Date.valueOf(System.today()) : Date.newInstance(2022, 4, 4));
        String billingFrequency = quote.SBQQ__Account__r.Billing_Frequency__c;
        String billingType = quote.SBQQ__Account__r.Billing_Type__c;
        Integer bcsm = (quote.SBQQ__Account__r.Billing_Cycle_Start_Month__c != null ? Integer.valueOf(quote.SBQQ__Account__r.Billing_Cycle_Start_Month__c) : null);
        Integer billingCycleStartMonth = (bcsm != null ? bcsm : !Test.isRunningTest() ? todaysDate.month() : 4);
        Date orderStart = setDate(todaysDate, billingCycleStartMonth, billingFrequency, billingType);
        System.debug(orderStart);
        return(orderStart);
    }
    
    public static Date setDate(Date todaysDate, Integer billingCycleStartMonth, String billingFrequency, String billingType) {
        Date setDate;
        if (billingType == 'In Advance') {
            setDate = todaysDate;
        } else {
            if (billingFrequency == 'Monthly' || billingFrequency == 'Annual') {
                Integer adjustedYear = adjustYear(todaysDate, billingCycleStartMonth);
                setDate = Date.newInstance(adjustedYear, billingCycleStartMonth, 1);
            } else if (billingFrequency == 'Quarterly' || billingFrequency == 'Semiannual') {
                List<Integer> periods = generatePeriods(billingCycleStartMonth, billingFrequency);
                Integer selectedPeriod = selectPeriod(periods, todaysDate, billingFrequency);
                Integer adjustedYear = adjustYear(todaysDate, selectedPeriod);
                setDate = Date.newInstance(adjustedYear, selectedPeriod, 1);
            }
        }
        return setDate;
    }

    public static List<Integer> generatePeriods(Integer billingCycleStartMonth, String method) {
        List<Integer> periods = new List<Integer>();
        periods.add(billingCycleStartMonth);
        if (method == 'Quarterly') {
            for (Integer i = 0; i < 3; i++) {
                for (Integer j = 0; j < 3; j++) {
                    billingCycleStartMonth += 1;
                    if (billingCycleStartMonth > 12) {
                        billingCycleStartMonth = 1;
                    }
                }
                periods.add(billingCycleStartMonth);
            }
        } else if (method == 'Semiannual') {
            for (Integer j = 0; j < 6; j++) {
                billingCycleStartMonth += 1;
                if (billingCycleStartMonth > 12) {
                    billingCycleStartMonth = 1;
                }
            }
            periods.add(billingCycleStartMonth);
        }
        System.debug('@OrderPlugin generatePeriods periods: ' + periods);
        return periods;
    }

    public static Integer selectPeriod(List<Integer> periods, Date todaysDate, String method) {
        Integer currentMonth = todaysDate.month();
        Integer selectedPeriod;
        for (Integer period : periods) {
            if (currentMonth == period) {
                selectedPeriod = period;
            } else {
                Integer incrementPeriod = period;
                if (method == 'Quarterly') {
                    for (Integer i = 0; i < 2; i++) {
                        incrementPeriod++;
                        if (incrementPeriod > 12) {
                            incrementPeriod = 1;
                        }
                        if (currentMonth == incrementPeriod) {
                            selectedPeriod = period;
                        }
                    }
                } else if (method == 'Semiannual') {
                    for (Integer i = 0; i < 5; i++) {
                        incrementPeriod++;
                        if (incrementPeriod > 12) {
                            incrementPeriod = 1;
                        }
                        if (currentMonth == incrementPeriod) {
                            selectedPeriod = period;
                        }
                    }
                }
            }
            if (selectedPeriod != null) {
                break;
            }
        }
        System.debug('@OrderPlugin selectPeriod selectedPeriod: ' + selectedPeriod);
        return selectedPeriod;
    }

    public static Integer adjustYear(Date todaysDate, Integer selectedPeriod) {
        return (selectedPeriod > todaysDate.month() ? todaysDate.year() - 1 : todaysDate.year());
    }
}