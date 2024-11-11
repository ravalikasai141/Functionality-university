public class DateUtil {

    // Determine if day is weekend
	public static Boolean isWeekendDay(Date dateParam){
		boolean result = false; 
		
		//Recover the day of the week
		DateTime dateT = DateTime.newInstance(dateParam, Time.newInstance(0, 0, 0, 0));
		Date startOfWeek = dateParam.toStartOfWeek();
		Integer dayOfWeek = (dateParam.day() < startOfWeek.day()) ? (dateParam.day() + date.daysInMonth(dateParam.year(), dateParam.month() == 1 ? 12 : dateParam.month() - 1)) - startOfWeek.day() : dateParam.day() - startOfWeek.day();  
		
		result = (dateT.format('E') == 'Sat' || dateT.format('E') == 'Sun') ? true : false;
		return result;
	}
	
	// Add or decrease business days 
	public static Date addBusinessDays(Date startDate, integer businessDaysToAdd)
	{
		Date finalDate = startDate;
		Integer direction = businessDaysToAdd < 0 ? -1 : 1;
		
		while (businessDaysToAdd != 0) {
			finalDate = finalDate.addDays(direction);
			if (!isWeekendDay(finalDate)) {
				businessDaysToAdd -= direction;
			}
		}
		
		return finalDate;
	}
}