#! /usr/bin/env ruby

require "rubygems"
require "clipboard"
require File.join(File.dirname(__FILE__), "auth_model")

class PassCrypt
	DEFAULT_PASSWORD_DISPLAY_TIME = 10 # seconds

	def main(args)
		print_usage_and_quit if args.empty?
		case args.join(" ")
		when /^put(c)? (\w+)$/
			insert($2, :clipboard => $1)
		when /^get(p)? (\w+)(?: -t (\d+))?$/
			retrieve($2, :password_time => $3.to_i, :only_password => $1)
		when /^(list|ls)$/
			list_ids
		when /^del (\w+)$/
			delete($1)
		else
			print_usage_and_quit
		end
	end

	def insert(id, opts={})
		passphrase = read_passphrase
		
		username = read_input("Enter username: ")
		password = if opts[:clipboard]
			puts "Password taken from clipboard"
			Clipboard.paste
		else
	 		read_input("Enter password: ", true)
		end

		if AuthModel.exists?(id)
			overwrite = read_input("Already exists - overwrite? [Y/n]: ")
			exit unless overwrite == "y" || overwrite == "Y" || overwrite == ""
			AuthModel.delete(id)
		end

		auth = AuthModel.new(passphrase, id, username, password)
		auth.save

		puts "Stored!"
	end

	def retrieve(id, opts={})
		user_delay = opts[:password_time].to_i
		time = user_delay > 0 ? user_delay : DEFAULT_PASSWORD_DISPLAY_TIME

		if not AuthModel.exists?(id)
			puts "Invalid entry" 
			exit
		end
		
		passphrase = read_passphrase

		auth = AuthModel.new(passphrase)
		auth.retrieve_from_db(id)

		puts "\n----------"
		puts "Username: #{auth.username}" unless opts[:only_password]

		prev_contents = Clipboard.paste
		Clipboard.copy(auth.password)

		puts "Password: * copied to the clipboard for #{time} seconds *"
		puts "----------\n\nPress ENTER to continue"

		t = Thread.new { sleep time }
		Thread.new { STDIN.gets; t.kill }
		t.join
	ensure
		Clipboard.copy(prev_contents)
	end

	def list_ids
		puts AuthModel.get_ids.sort.join("\n")
	end

	def delete(id)
		if AuthModel.delete(id)
			puts "Deleted entry '#{id}'"
		else
			puts "Invalid entry"
		end
	end

	def read_passphrase
		read_input("Enter your secret passphrase: ", true)
	end

	def read_input(message, secret=false)
		puts message
		system "stty -echo" if secret
		STDIN.gets.chomp
	ensure
		system "stty echo"
	end

	def print_usage_and_quit
		puts "Usage: pass_crypt OPERATION [ID] [OPTION VALUE]"
		puts "\nOperations:"
		puts "\tget\tfetches the authentication details identified by ID"
		puts "\tgetp\tfetches only the password identified by ID"
		puts "\tput\tstores a username and password"
		puts "\tputc\tsame as 'put', but takes password from the clipboard"
		puts "\tdel\tdeletes an entry"

		puts "\n\tThe following require no ID parameter:"
		puts "\tlist\tdisplays the IDs of the stored authentication data"
		puts "\thelp\tdisplays this usage message"
		puts "\nOption:"
		puts "\t-t\tholds the password in the clipboard for the given time in seconds. Only available for get and getp"
		exit
	end
end

PassCrypt.new.main(ARGV)
