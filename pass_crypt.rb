#! /usr/bin/env ruby

require "rubygems"
require "clipboard"
require File.join(File.dirname(__FILE__), "auth_model")

class PassCrypt

	def main(args)
		print_usage_and_quit if args.empty?
		case(args.join " ")
		when /put\s+\w+\z/
			insert(format_id(args))
		when /putc\s+\w+\z/
			insert(format_id(args), :clipboard => true)
		when /get\s+\w+\z/
			retrieve(format_id(args))
		when /getp\s+\w+\z/
			retrieve(format_id(args), nil, :only_password => true)
		when /get\s+\w+\s+time\s+\d+\z/
			retrieve(format_id(args), format_time(args))
		when /getp\s+\w+\s+time\s+\d+\z/
			retrieve(format_id(args), format_time(args), :only_password => true)
		when /list/
			list_ids
		when /del\s+\w+\z/
			delete(format_id(args))
		else
			print_usage_and_quit
		end
	end

	def format_id(args)
		args[1]

	end
	
	def format_time(args)
		args[3].to_i
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

	def retrieve(id, time=nil, opts={})
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

		time ||= 10
		puts "Password: * copied to the clipboard for #{time} seconds *"
		puts "----------\n\nPress ENTER to continue"

		t = Thread.new { sleep time }
		Thread.new { STDIN.gets; t.kill }
		t.join
	ensure
		Clipboard.copy(prev_contents)
	end

	def list_ids
		AuthModel.get_ids.each do |id|
			puts id
		end
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
		puts "\ttime\tholds the password in the clipboard for the given value in seconds. Only available for get and getp"
		exit
	end
end

PassCrypt.new.main(ARGV)
