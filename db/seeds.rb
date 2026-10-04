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

track = album.tracks.find_or_create_by!(file_key: "Skrillex,Damian Marley - Make It Bun Dem.mp3") do |t|
  t.title = "Make It Bun Dem"
  t.duration = 213
  t.track_number = 1
end
puts "Sample track ready: #{track.title} (id: #{track.id})"
puts "== Seeding Complete! =="
