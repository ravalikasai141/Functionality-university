public class CsvReader {
	private String delim = ',';
	private List<String> buffer;
	
	public CsvReader(String data){
		this.buffer = data.split('\n'); 
	}
	
	public CsvReader(String data, String delim){
		this.buffer = data.split('\n'); 
		this.delim = delim;
	}
	
	public List<String> readLine() {
		if (buffer.size() == 0) {
			return null;
        }
		String line = this.buffer.remove(0);
		List<String> parts = new List<String>();
		while (line != '') {
			Integer next = 0;
			if (line.startsWith('"')) {
				line = line.substring(1);
				Integer quoteIndex = findQuote(line, 0);
				while (quoteIndex == -1) {
					if (buffer.size() == 0) {
						quoteIndex = line.length();
					} else {
						Integer skip = line.length();
						line += '\n' + this.buffer.remove(0);
						quoteIndex = findQuote(line, skip);
					}
				}
				next = quoteIndex + 1;
				parts.add(line.substring(0, quoteIndex).replace('""', '"'));
			} else {
				next = line.indexOf(this.delim, next);
				if (next == -1) {
					next = line.length();
                }
				parts.add(line.substring(0, next));
			}		
			if (next == line.length() - 1) {
				parts.add('');
            }
			line = next < line.length() ? line.substring(next+1) : '';
		}
		if (parts.size() == 0) {
			parts.add('');
        }
		return parts;
	}
	
	static private Pattern quotePattern = Pattern.compile('(?<!")"(?!")');
	private Integer findQuote(String line, Integer skip) {
		Matcher m = quotePattern.matcher(line);
		m.region(skip, m.regionEnd());
		if (!m.find()) {
			return -1;
        }
		return m.start();
	}
}