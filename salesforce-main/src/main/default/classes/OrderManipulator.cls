/*
* Who Patrick Duncan <patrick.duncan@weare4c.com> 
* What Class for calculating backdates for new orders
* When 6/8/20
*/
public class OrderManipulator {
    
    //Map for determining the size of a billing frequency in months
    public static final Map<String,Integer> frequencyToMonthDifference = new Map<String,Integer>{'Monthly' => 1, 'Quarterly' => 3, 'Semiannual' => 6, 'Annual' => 12};
    
    public List<OrderWrapper> orderWrappers;
    
    public OrderManipulator(List<Order> orders){
        this.orderWrappers = new List<OrderWrapper>();
        for(Order order:orders){
            this.orderWrappers.add(new OrderWrapper(order));
        }
    }
    
    /*
    * Description -  Main method for calculating order backdates
    */
    public void backDateOrders(){
        addAccountsToWrappers();
        setStartDatesOnOrders();
        updateOrders();
    }
    
    /*
    * Description -  Method for finding the account for each order and adding to wrapper
    */
    public void addAccountsToWrappers(){
        Set<Id> accountIds = getAccountIds();
        Map<Id,Account> accountMap = queryAccounts(accountIds);
        setAccountsOnWrappers(accountMap);
    }
    
    /*
    * Description -  Method for setting calculated date on each order
    */
    public void setStartDatesOnOrders(){
        List<OrderWrapper> updatedOrderWrappers = new List<OrderWrapper>();
        for(OrderWrapper orderWrapper:this.orderWrappers){
            orderWrapper.setOrderStartDate(updatedOrderWrappers);
        }
        this.orderWrappers = updatedOrderWrappers;
    }
    
    /*
    * Description -  Method for updating orders
    */
    public void updateOrders(){
        List<Order> orders = new List<Order>();
        for(OrderWrapper orderWrapper:this.orderWrappers){
            orders.add(orderWrapper.order);
        }
        update orders;
	}
    
    /*
    * Description -  Method for creating a map of order id to account id
    * Return      - Map of order id -> account id
    */
    public Set<Id> getAccountIds(){
        Set<Id> accountIds = new Set<Id>();
        for(OrderWrapper orderWrapper:this.orderWrappers){
            accountIds.add(orderWrapper.order.AccountId);
        }
        return accountIds;
    }
    
    /*
    * Description -  Method for querying account as a map using account ids
    * Param       -  accountids - Ids of the accounts to query
    * Return      -  Map of Id -> Account
    */
    public Map<Id,Account> queryAccounts(Set<Id> accountIds){
        return new Map<Id,Account>([SELECT Billing_Frequency__c, Billing_Cycle_Start_Month__c, Billing_Type__c FROM Account WHERE Id IN :accountIds]);
    }
    
    /*
    * Description -  Method for decorating the order wrapper with it's parent account
    * Param       -  accountMap - Map of Id -> Account
    */
    public void setAccountsOnWrappers(Map<Id,Account> accountMap){
        for(OrderWrapper orderWrapper:this.orderWrappers){
            orderWrapper.account = accountMap.get(orderWrapper.order.AccountId);
		}
    }
    
    /*
    * Description -  Wrapper class enacpulating an order and it's related objects
    */    
    public class OrderWrapper{
    	 public Order order;
        public Account account;
        
        public OrderWrapper(Order order){
            this.order = order;
        }
        
        /*
        * Description -  Method for calculating the start of the billing cycle that this order falls into by looking at the cylce start month and the interval size
        */ 
        public Date getCurrentCycleStart(){
            //If the mocked creation date is not null, this is running in a test method
            Date orderStartDate = OrderCreatedDateMock.mockCreationDate == null ? this.order.EffectiveDate : OrderCreatedDateMock.mockCreationDate;
            System.debug(orderStartDate);
            Integer day = 1;
            Integer year = orderStartDate.year();

            //If Billing_Cycle_Start_Month__c is null, cycleStartMonth = Current Month
            Integer cycleStartMonth = this.account.Billing_Cycle_Start_Month__c != null 
                                        ? Integer.valueOf(this.account.Billing_Cycle_Start_Month__c) 
                                        : orderStartDate.month();

            Integer billingFrequencyIntervalMonth = OrderManipulator.frequencyToMonthDifference.get(this.account.Billing_Frequency__c);

            Date currentYearCycleStart = Date.newInstance(year, cycleStartMonth, day);
            Date intervalStart;
            Date intervalEnd;

            if(this.order.Billing_Type__c == 'In Advance'){
                return orderStartDate.toStartOfMonth();
            }
            else if(cycleStartMonth == orderStartDate.month()){
                return currentYearCycleStart;
            }
            else if(billingFrequencyIntervalMonth == 1){
                return Date.newInstance(year, orderStartDate.month(), day);
            }
            else if(cycleStartMonth < orderStartDate.month()){
                // Created date is greater than start date e.g Start = Feb & Created = May  
                // Move interval window by size interval until created date is inside window
                intervalStart = currentYearCycleStart;
                intervalEnd = currentYearCycleStart.addMonths(billingFrequencyIntervalMonth);

                while(!(orderStartDate >= intervalStart && orderStartDate <= intervalEnd)){
                    intervalStart = intervalStart.addMonths(billingFrequencyIntervalMonth);
                    intervalEnd = intervalEnd.addMonths(billingFrequencyIntervalMonth);
                }
                return intervalStart;
            }
            else{
                // Created date is less than start date e.g Start = May & Created = Feb
                // Move interval window by size interval until created date is inside window
                intervalEnd = currentYearCycleStart;
                intervalStart = currentYearCycleStart.addMonths(-billingFrequencyIntervalMonth);

                while(!(orderStartDate >= intervalStart && orderStartDate <= intervalEnd)){
                    intervalStart = intervalStart.addMonths(-billingFrequencyIntervalMonth);
                    intervalEnd =  intervalEnd.addMonths(-billingFrequencyIntervalMonth);
                }
                return intervalStart;
            }
        }

        public void setOrderStartDate(List<OrderWrapper> updatedOrderWrappers){
            if(this.account.Billing_Frequency__c != null/* && this.account.Billing_Frequency__c != 'Invoice Plan'*/){
                this.order = this.order.clone(true);
                this.order.EffectiveDate = this.getCurrentCycleStart();
                this.order.blng__BillingDayOfMonth__c = '1';
                updatedOrderWrappers.add(this);
            }    
        }
        
        
    }

}