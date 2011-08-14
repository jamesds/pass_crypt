require "sqlite3"

class AuthModel
	TABLE_NAME = "vault"
	DB_NAME = "crypt.db"
	CIPHER = "aes256"

	attr_accessor :db, :id, :username, :password, :passphrase

	def retrieve_from_db(id)
		result = @db.execute("SELECT * FROM #{TABLE_NAME} WHERE id = ?", id)
		
		@id = id
		@username = crypt(:decrypt, result['username'], result['salt'])
		@password = crypt(:decrypt, result[:password], result[:salt])
	end

	def self.get_ids
		get_db.execute("SELECT id FROM #{TABLE_NAME}").map(&:id)
	end
	
	def initialize(id="", username="", password="", passphrase)
		@id = id
		@username = username
		@password = password
		@passphrase = passphrase
		@db = get_db
	end	

	def save
		salt = generate_salt
		enc_username = crypt(:encrypt, username, salt)
		enc_password = crypt(:encrypt, password, salt)
		@db.execute("INSERT INTO #{TABLE_NAME} VALUES (?, ?, ?, ?)", id, enc_username, enc_password, salt)
	end

	protected

	def get_db
		db = SQLite3::Database.new(DB_NAME)
		db.results_as_hash = true

		db.execute("SELECT COUNT(*) FROM #{TABLE_NAME}")
	rescue SQLite3::SQLException
		# create table if it doesn't exist
		db.execute("CREATE TABLE #{TABLE_NAME} (id STRING, username STRING, password STRING, salt STRING)")
	ensure
		return db
	end

	# Encrypts/decrypts data with the provided
	# passphrase and salt.
	#
	# operation
	#   :encrypt - encrypts the given data
	#   :decrypt - decrypts the given data
	def crypt(operation, data, salt)
		cipher = OpenSSL::Cipher.new(CIPHER)
		cipher.send(operation)
		cipher.pkcs5_keyivgen(@passphrase, salt)
		cipher.update(data)
		cipher.final
	end

	def generate_salt

	end

end
