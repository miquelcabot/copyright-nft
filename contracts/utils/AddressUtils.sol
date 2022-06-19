// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library AddressUtils {
    /**
     * @dev Returns whether the target address is a contract.
     * @param _addr Address to check.
     * @return bool true if _addr is a contract, false if not.
     */
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;

        /**
         * XXX Currently there is no better way to check if there is a contract in an address than to
         * check the size of the code at that address.
         * See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
         */
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}
