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
                // Contract Signature
                signer = address(uint160(uint256(r)));
            } else {
                signer = ecrecover(hash, v + 27, r, s);
            }
        } else if (v > 30) {
            // ETH_SIGN
            bytes32 signed = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
            signer = ecrecover(signed, v - 4, r, s);
        } else {
            // Standard EOA
            signer = ecrecover(hash, v, r, s);
        }
    }
}
