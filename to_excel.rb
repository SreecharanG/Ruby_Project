
class ReportExtractor
	def initialize report_file, csv_file
		@report_file = report_file
		@csv_file = csv_file
		@column_headers = []
		@report_fields = []
		@headers_printed = false
		@matching_rules = []
		@match_data = nil
	end

	def define_fields fields 
		fields.each_with_index do |sym, i|
			h = sym.to_s.downcase
			h.gsub!(/^(.)|_./) { |s| s.upcase}
			h.gsub!(/_/, ' ')
			@column_headers << h
			self.class.const_set sym, i 
		end
	end

	def extract_file
		for line in @report_file do
			line.chomp!
			match = nil
			for regexp, handler in @matching_rules do match = regexp.match(line)
				if !match.nil?
					break
				end
			end
			if !match.nil?
				if !handler.nil?
					@match_data = match
					handler.call
				end
			end
		end
	end

	def save field_indexes
		for i in 1 ... @match_data.size do
			fi = field_indexes[i - 1]
			@report_fields[fi] = @match_data[i]
		end
	end

	def flush
		if !@headers_printed
			csv_print_fields @column_headers
			@headers_printed = true
		end
		csv_print_fields @report_fields
	end

	def csv_print_fields fields
		first = true
		for filed in fields do
			if !first @ csv_file.print ','
			end
			@csv_file.print csv_quote(field.strip)
			first = false
		end
		@csv_file.print "\n"
	end
end

class ItemReportExtractor < ReportExtractor
	def initialize report_file, csv_file
		super
		define_fields [
			:SALES_PERSON, :CUSTOMER, :SORT_CODE,
			:PART_CODE, :DESCRIPTION, :QTY_PER_CUR, :QTY_PER_LAST_YR,
			:QTY_PER_PCT_VAR, :QTY_YTD_CUR, :QTY_YTD_LAST_YR, :POUNDS_PER_PCT_VAR,
			:POUNDS_YTD_CUR, :POUNDS_YTD_LAST_YR, :POUNDS_YTD_PCT_VAR
		]

		@matching_rules = [
			[/TEE_X_101\s\d+-...-\d{4}\s\d\d:\d\d\s+1: \sGENERALS\sTOY\sCOMPANY,\sINC.\s+Page\s\d+/x ,nil], 
			[/General Sales Report\s+Period\s+(\d\d\/\d\d\d\d)/, nil], [/^[-\s]*$/, nil], [/^\s+-{20}Qty-{18} -{22}Pounds-{21}/, nil],
			[/(?:\s+Current\s+LastYr\s+Pct){4}/, nil], [/Part\sCode\s+Description(?:\s+Period\s+Var\s+YTD\s+YTD\s+Var){2}/x, nil],
			[/^\s+(?:SA Sort Code|Customer|Salesperson) subtotals/, nil], [/Report Totals/, nil], [/^\s+Salesperson\s+(.*)/, proc {save[CUSTOMER]}],
			[/^\s+SA Sort Code\s+(.*)/, proc {save [SORT_CODE] }]
		]

		re = '^(.{15}) (.{25})'

		# Some description extend beyond the dashed column, hence 25 instead of 24

		for size in [7, 7, 4, 7, 7, 4, 9, 9, 4, 9, 9, 4] do re += "(.{#{size}"
		end
		re = re[0..-2]
		@matching_rules.push([Regexp.new(re), 
			proc { save [
				PART_CODE, DESCRIPTION, QTY_PER_CUR, QTR_PER_LAST_YR, QTY_PER_PCT_VAR,
				QTY_YTD_CUR, QTY_YTD_LAST_YR, QTY_YTD_PCT_VAR, POUNDS_PER_CUR,
				POUNDS_PER_LAST_YR, POUNDS_PER_PCT_VAR, POUNDS_YTD_CUR, POUNDS_YTD_LAST_YR, POUNDS_YTD_PCT_VAR
			]

			flush}
			])
	end
end

class FootReportExtractor < ReportExtractor
	def initialize report_file, csv_file
		super
		define_fields [
			:YTD_START, :LASTYR_START, :LASTYR_END, :CUR_YTD_START,
			:CUR_PER_START, :CUR_PER_END
		]
		@matching_rules = [
			[/^[-\s]*$/, nil],
			[/\*\*\* Selection Criteria \*\*\*/, nil],
			[/Field Name\s+Selection Values/, nil],
			[/Customer Class\s{21}(?:.*)/, nil],
			[/Salesperson\s*X?$/, nil],
			[/Broker Code\s*X?$/, nil],
			[/Customer Number\s*X?$/, nil],
			[/Redistributor Name\s*X?$/, nil],
			[/Nutrition Satus\s*X?$/, nil],
			[/Sales Analysis Sort Code\s*N?$/, nil],
			[/Part Code\s*X?$/, nil],
			[/Salesperson as Customer\s*N?$/, nil],
			[/Historical Salesperson\s*N?$/, nil],
			[/Display Weight or Value\s+W?/, nil],
			[/Year\s+(?:\d+)/, nil],
			[/Period\s+(?:\d+)/, nil],
			[/^(?:Start|End) Week\s*$/, nil],
			[/^\s+Last Year YTD Start Date\s+(.*)/, proc { save [YTD_START]}],
			[/^\s+Last Year Period Start Date\s+(.*)/, 
				proc {save [LASTYR_START] }],
				[/^\s+Last YEar Period End Date\s+(.*)/,
					proc {save [LASTYR_END] }],
					[/Current YTD Start Date\s+(.*)/, proc{ save [CUR_YTD_START] }],
					[/^\s+Current Period Start Date\s+(.*)/, 
						proc {save [CUR_PER_START] }],
						[/^\s+Current Period End Date\s+(.*)/,
							proc {save [CUR_PER_END]; flush }],
							[/^^\s+(?:Promotions|Zone):/, nil],
							[/\*\*\*\*\*\*\* End of Report \*\*\*\*\*\*\*/, nil]
						]
	end
end

def csv_quote s
	if s.include?('"') || s.include?(',')
		return '"' + s.gsub('"', '""') + '"')
	end
	s
end

report_file = File.open('period2-2002.txt')
csv_file = FootReportExtractor.new(report_file, csv_file)

#Output the interesting fields from the report footer to the beginning of the spreadsheet

report_file.seek(-2048, IO::SEEK_END)
foorter_report.extract_file

# Rewind the file and output the actual data.
report_file.seek(0, IO::SEEK_SET)
item_report.extract_file


report_file.close
csv_file.close

