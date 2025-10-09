// SPDX-License-Identifier: MIT

/**
 * \
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x17agabond
 * =============================================================================
 * Diamond Testing via OOP (DTO)
 * /*****************************************************************************
 */
pragma solidity ^0.8.26;

/**
 * @title Enum - Collection of enums used in Safe Smart Account contracts.
 * @author @safe-global/safe-protocol
 */
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }

    enum Admin {
        Sys,
        Trans,
        Boss
    }

    enum TransferType {
        Inbound,
        Outbound
    }
}
