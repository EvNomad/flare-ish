puts "Seeding Providers..."
prov1 = Provider.find_or_create_by!(email: "alice.jerusalem@example.com") { |p| p.name = "Alice"; p.tz = "Asia/Jerusalem"; p.service_type = :consultation }
prov2 = Provider.find_or_create_by!(email: "bob.jerusalem@example.com")   { |p| p.name = "Bob";   p.tz = "Asia/Jerusalem"; p.service_type = :consultation }
prov3 = Provider.find_or_create_by!(email: "carol.la@example.com")        { |p| p.name = "Carol"; p.tz = "America/Los_Angeles"; p.service_type = :review }
prov4 = Provider.find_or_create_by!(email: "dave.la@example.com")         { |p| p.name = "Dave";  p.tz = "America/Los_Angeles"; p.service_type = :review }
puts "Providers seeding done."

puts "Ensuring TimeSlots horizon for timezones..."
["Asia/Jerusalem", "America/Los_Angeles"].each do |tz|
  TimeSlots::EnsureForTimezone.call(tz: tz)
end
puts "TimeSlots generation done."

# WeeklyTemplate seeds: Mon-Fri
# Monday: 10:00-16:00
# Friday: 10:00-14:00
# Tue/Wed/Thu: 10:00-17:00

puts "Seeding WeeklyTemplate for all providers (Mon-Fri)..."
Provider.find_each do |provider|
  (1..5).each do |dow|
    start_str, end_str = case dow
    when 1 then ["10:00", "16:00"] # Monday
    when 5 then ["10:00", "14:00"] # Friday
    else         ["10:00", "17:00"] # Tue/Wed/Thu
    end

    tpl = WeeklyTemplate.find_or_initialize_by(provider_id: provider.id, dow: dow)
    tpl.start_local = start_str
    tpl.end_local   = end_str
    tpl.save! if tpl.changed?
  end
end
puts "WeeklyTemplate seeding done."