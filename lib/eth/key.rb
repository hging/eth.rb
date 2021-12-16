# Copyright (c) 2016-2022 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rbsecp256k1'
require 'securerandom'

module Eth

  # The `Eth::Key` class to handle Secp256k1 private/public key-pairs.
  class Key

    # The `Secp256k1::PrivateKey` of the `Eth::Key` pair.
    attr_reader :private_key

    # The `Secp256k1::PublicKey` of the `Eth::Key` pair.
    attr_reader :public_key

    # Constructor of the `Eth::Key` class. Creates a new random key-pair
    # if no `priv` key is provided.
    #
    # @param priv [String] binary string of private key data (optional).
    def initialize priv: nil

      # Creates a new, randomized libsecp256k1 context.
      ctx = Secp256k1::Context.new context_randomization_bytes: SecureRandom.random_bytes(32)

      # Creates a new random key pair (public, private).
      key = ctx.generate_key_pair

      unless priv.nil?

        # Converts hex private keys to binary strings.
        priv = Util.hex_to_bin priv if Util.is_hex? priv

        # Creates a keypair from existing private key data.
        key = ctx.key_pair_from_private_key priv
      end

      # Sets the attributes.
      @private_key = key.private_key
      @public_key = key.public_key
    end

    # Prefixes a message with "\x19Ethereum Signed Message:" and signs
    # it in the common way used by many web3 wallets. Complies with
    # EIP-191 prefix 0x19 and version byte 0x45 (E).
    #
    # @param message [String] the message string to be prefixed and signed.
    # @param chain_id [Integer] the chain id the signature should be generated on.
    # @return [String] an EIP-191 conform, hexa-decimal signature.
    def personal_sign message, chain_id = Chain::ETHEREUM
      context = Secp256k1::Context.new
      prefixed_message = Signature.prefix_message message
      hashed_message = Util.keccak256 prefixed_message
      compact, recovery_id = context.sign_recoverable(@private_key, hashed_message).compact
      signature = compact.bytes
      v = Chain.to_v recovery_id, chain_id
      signature = signature.append v
      Util.bin_to_hex signature.pack 'c*'
    end

    # Converts the private key data into a hexa-decimal string.
    #
    # @return [String] private key as hexa-decimal string.
    def private_hex
      Util.bin_to_hex @private_key.data
    end

    # Exports the private key bytes in a wrapper function to maintain
    # backward-compatibility with older versions of `Eth::Key`.
    #
    # @return [String] private key as packed byte-string.
    def private_bytes
      @private_key.data
    end

    # Converts the public key data into an uncompressed
    # hexa-decimal string.
    #
    # @return [String] public key as uncompressed hexa-decimal string.
    def public_hex
      Util.bin_to_hex @public_key.uncompressed
    end

    # Converts the public key data into an compressed
    # hexa-decimal string.
    #
    # @return [String] public key as compressed hexa-decimal string.
    def public_hex_compressed
      Util.bin_to_hex @public_key.compressed
    end

    # Exports the uncompressed public key bytes in a wrapper function to
    # maintain backward-compatibility with older versions of `Eth::Key`.
    #
    # @return [String] uncompressed public key as packed byte-string.
    def public_bytes
      @public_key.uncompressed
    end

    # Exports the compressed public key bytes.
    #
    # @return [String] compressed public key as packed byte-string.
    def public_bytes_compressed
      @public_key.compressed
    end

    # Exports the checksummed public address.
    #
    # @return [Eth::Address] compressed address as packed hex prefixed string.
    def address
      Util.public_key_to_address public_bytes
    end
  end
end