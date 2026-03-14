require "io/console"

namespace :password do
  desc "Reset a user's password (interactive)"
  task reset: :environment do
    print "Username: "
    username = $stdin.gets.chomp

    user = User.find_by(username: username.downcase)
    abort "User '#{username}' not found." unless user

    print "New password (min 8 chars): "
    password = $stdin.noecho(&:gets).chomp
    puts

    print "Confirm password: "
    confirmation = $stdin.noecho(&:gets).chomp
    puts

    abort "Passwords do not match." unless password == confirmation

    user.password = password
    if user.save
      puts "Password updated for '#{user.username}'."
    else
      abort "Error: #{user.errors.full_messages.join(', ')}"
    end
  end
end
