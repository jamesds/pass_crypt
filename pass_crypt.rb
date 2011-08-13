require "openssl"

class PassCrypt
	CIPHER = "aes256"

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

end
