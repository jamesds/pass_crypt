require "openssl"
require "clipboard"

class PassCrypt
	CIPHER = "aes256"

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
			list_ids # change when set up model?
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

		username = read_input("Enter username: ")
		password = if opts[:clipboard]
			Clipboard.paste
		else
	 		read_input("Enter password: ", false)
		end

		enc_username = crypt(:encrypt, username, passphrase, generate_salt)
		enc_password = crypt(:encrypt, password, passphrase, generate_salt)

		puts enc_username
		puts enc_password
		# TODO store encrypted username/password with ID
	end

	def read_passphrase
		read_input("Enter your secret passphrase: ", false)
	end

	def read_input(message, echo=true)
		puts message
		system "stty -echo" unless echo
		input = STDIN.gets.chomp
		system "stty echo"
		return input
	end

	# Encrypts/decrypts data with the provided
	# passphrase and salt.
	#
	# operation
	#   :encrypt - encrypts the given data
	#   :decrypt - decrypts the given data
	def crypt(operation, data, passphrase, salt)
		cipher = OpenSSL::Cipher.new(CIPHER)
		cipher.send(operation)
		cipher.pkcs5_keyivgen(passphrase, salt)
		cipher.update(data)
		cipher.final
	end

	def generate_salt

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
