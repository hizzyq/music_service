# db/seeds.rb
# Idempotent seed data for development and demonstration

puts "== Seeding Users =="
admin = User.find_or_create_by!(email: "admin@test.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :admin
end
puts "Admin ready: #{admin.email} (id: #{admin.id}, role: #{admin.role})"

listener = User.find_or_create_by!(email: "listener@test.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :listener
end
puts "Listener ready: #{listener.email} (id: #{listener.id}, role: #{listener.role})"

puts "== Seeding Initial Catalog =="
artist = Artist.find_or_create_by!(name: "Skrillex") do |a|
  a.bio = "American electronic music producer, DJ, singer and songwriter."
end

album = artist.albums.find_or_create_by!(title: "Make It Bun Dem After Hours") do |al|
  al.release_year = 2012
end

sample_waveform = Array.new(100) do |i|
  case i
  when 0..10   then 0.10 + (i * 0.02)
  when 11..25  then 0.30 + (Math.sin(i * 0.8) * 0.15).abs
  when 26..35  then 0.40 + ((i - 26) * 0.05)
  when 36..55  then 0.70 + (Math.sin(i * 0.9) * 0.28).abs
  when 56..68  then 0.20 + (Math.sin(i * 0.6) * 0.12).abs
  when 69..88  then 0.75 + (Math.sin(i * 0.85) * 0.24).abs
  else              [0.60 - ((i - 88) * 0.04), 0.08].max
  end.round(3)
end

track = album.tracks.find_or_create_by!(file_key: "Skrillex,Damian Marley - Make It Bun Dem.mp3") do |t|
  t.title = "Make It Bun Dem"
  t.duration = 213
  t.track_number = 1
  t.waveform = sample_waveform
end
track.update!(waveform: sample_waveform) if track.waveform.blank? || track.waveform.all? { |v| v >= 0.9 }
puts "Sample track ready: #{track.title} (id: #{track.id})"
puts "== Seeding Complete! =="
