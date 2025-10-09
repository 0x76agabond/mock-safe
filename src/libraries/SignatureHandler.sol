// SPDX-License-Identifier: MIT

/**
 * \
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * =============================================================================
 * Gnosis Safe Mock (NotSafe)
 * /*****************************************************************************
 */
pragma solidity >=0.8.0 <0.9.0;

library SignatureHandler {
    uint256 internal constant SIGNATURE_SIZE = 0x41;

    //Decodes signatures encoded as bytes, loop byte signature size
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        assembly {
            r := mload(add(signatures, add(pos, 0x20)))
            s := mload(add(signatures, add(pos, 0x40)))
            v := byte(0, mload(add(signatures, add(pos, 0x60))))
        }
    }

    function _validateSignatures(bytes memory signatures, uint256 threshold) internal pure {
        require(signatures.length >= threshold * SIGNATURE_SIZE, "Not enough signature");
        require(signatures.length % SIGNATURE_SIZE == 0, "Invalid signature format");
    }

    function _recoverSigner(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address signer) {
        if (v < 27) {
            if (s == bytes32(0) && v == 1) {
                signer = address(uint160(uint256(r)));
                return signer;
            }
            // legacy 27 offset
            signer = ecrecover(hash, v + 27, r, s);
            return signer;
        }

        // Gnosis-style ETH_SIGN: v = 31 | 32 (27/28 + 4)
        if (v > 30) {
            bytes32 digest;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000)
                mstore(add(ptr, 28), hash)
                digest := keccak256(ptr, 60)
            }
            signer = ecrecover(digest, v - 4, r, s);
        } else {
            signer = ecrecover(hash, v, r, s);
        }

        return address(0);
    }
}
