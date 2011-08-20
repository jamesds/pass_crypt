#! /usr/bin/env ruby

require "rubygems"
require "openssl"
require "clipboard"
require_relative "auth_model"

class PassCrypt

	def main(args)
		print_usage_and_quit if args.empty?

		case(args.shift)
		when "put"
			insert(args)
		when "putc"
			insert(args, :clipboard => true)
		when "get"
			retrieve(args)
		when "getp"
			retrieve(args, :only_password => true)
		when "list"
			list_ids
		when "del"
			delete(args)
		when "set"
			set_configs(args)
		else
			print_usage_and_quit
		end
	end

	def insert(args, opts={})
		print_usage_and_quit if args.empty?
		passphrase = read_passphrase
		id = args.first

		username = read_input("Enter username: ")
		password = if opts[:clipboard]
			Clipboard.paste
			puts "Password taken from clipboard"
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

	def retrieve(args, opts={})
		print_usage_and_quit if args.empty?
		if not AuthModel.exists?(args.first)
			puts "Invalid entry"
			exit
		end

		passphrase = read_passphrase

		auth = AuthModel.new(passphrase)
		auth.retrieve_from_db(args.first)

		puts "\n----------"
		puts "Username: #{auth.username}"

		prev_contents = Clipboard.paste
		Clipboard.copy(auth.password)
		puts "Password: * copied to the clipboard for 10 seconds *"
		puts "----------\n\nPress ENTER to continue"

		t = Thread.new { sleep 10 }
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

	def delete(args)
		print_usage_and_quit if args.empty?

		if AuthModel.delete(args.first)
			puts "Deleted entry '#{args.first}'"
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
		puts "Usage: pass_crypt <operation> (<id>)"
		puts "\nOperations:"
		puts "\tlist - displays the IDs of the stored authentication data"

		puts "\thelp - displays this usage message"
		exit
	end
end

PassCrypt.new.main(ARGV)
