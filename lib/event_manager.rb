require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

class String
  def numeric?
    Float(self) != nil rescue false
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phone_number(phone_number)
  formatted_phone_number = phone_number.to_s.split('').select {|digit| digit.numeric?}
  if formatted_phone_number.size == 10
    formatted_phone_number.join('')
  elsif formatted_phone_number.size == 11 && formatted_phone_number[0] == '1'
    formatted_phone_number[1..10].join('')
  else
    "Invalid Phone number"
  end
end

def get_peak_hour(reg_dates)
  hours = {}
  hours.default = 0
  reg_dates.each do |reg_date|
    reg_hour = Time.strptime(reg_date, "%m/%d/%Y %k:%M").hour
    hours[reg_hour]+=1
  end
  hours.select {|k,v| v == hours.values.max}.keys
end

def get_peak_day(reg_dates)
  day_of_the_week = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  day_count = {}
  day_count.default = 0
  reg_dates.each do |reg_date|
    reg_day = Time.strptime(reg_date, "%m/%d/%Y %k:%M").wday
    day_count[reg_day]+=1
  end
  day_count.select{|k,v| v == day_count.values.max}.keys.map{|key| day_of_the_week[key]}
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'you can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end



puts 'EventManager initialized'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
reg_dates = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])

  p "#{name} #{zipcode} #{phone_number}"
  reg_dates << row[:regdate]
end

p "The peak hours are: #{get_peak_hour(reg_dates).join(' ')}"
p "The peak days are: #{get_peak_day(reg_dates).join(' ')}"

