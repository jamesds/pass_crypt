require "sqlite3"
require "openssl"

class AuthModel
	TABLE_NAME = "vault"
	DB_NAME = "crypt.db"
	CIPHER = "aes256"

	attr_accessor :db, :id, :username, :password, :passphrase_digest

	def retrieve_from_db(id)
		result = @db.execute("SELECT * FROM #{TABLE_NAME} WHERE id = ?", id).first
		return unless result

		@id = id
		@username = decrypt(result["username"], result["salt"])
		@password = decrypt(result["password"], result["salt"])
	end

	def self.get_ids
		get_db.execute("SELECT id FROM #{TABLE_NAME}").map { |r| r["id"] }
	end

	def self.delete(id)
		return false unless exists?(id)
		get_db.execute("DELETE FROM #{TABLE_NAME} WHERE id = ?", id)
	end
	
	def self.exists?(id)
		get_ids.include?(id)
	end
	
	def initialize(passphrase, id="", username="", password="")
		@id = id
		@username = username
		@password = password
		@passphrase_digest = get_digest(passphrase)
		@db = AuthModel.get_db
	end	

	def save(overwrite=true)
		salt = generate_salt
		@db.execute("INSERT INTO #{TABLE_NAME} (id, username, password, salt) VALUES (?, ?, ?, ?)",
								@id, encrypt(@username, salt), encrypt(@password, salt), salt)
	end

	def self.get_db
		db = SQLite3::Database.new(File.join(PassCrypt::USER_FOLDER, DB_NAME))
		db.results_as_hash = true

		db.execute("SELECT COUNT(*) FROM #{TABLE_NAME}")
	rescue SQLite3::SQLException
		# create table if it doesn't exist
		db.execute("CREATE TABLE #{TABLE_NAME} (id STRING PRIMARY KEY, username STRING, password STRING, salt STRING)")
	ensure
		return db
	end

	protected

	def encrypt(data, salt)
		cipher(:encrypt, data, salt)
	end

	def decrypt(data, salt)
		cipher(:decrypt, data, salt)
	end

	# Encrypts/decrypts data with the provided
	# passphrase and salt.
	#
	# operation
	#   :encrypt - encrypts the given data
	#   :decrypt - decrypts the given data
	def cipher(operation, data, salt)
		cipher = OpenSSL::Cipher.new(CIPHER)
		cipher.send(operation)
		cipher.key = @passphrase_digest
		cipher.iv = salt
		cipher.update(data) + cipher.final
	rescue OpenSSL::Cipher::CipherError
		puts "Bad Passphrase"
		exit
	end

	def generate_salt
		OpenSSL::Random.random_bytes(32)
	end

	def get_digest(data)
		Digest::SHA256.digest(data)
	end

end
