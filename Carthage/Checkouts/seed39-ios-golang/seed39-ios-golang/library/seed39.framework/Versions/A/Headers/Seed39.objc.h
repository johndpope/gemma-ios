// Objective-C API for talking to git.coding.net/bobxuyang/bip32-39-golang-lib Go package.
//   gobind -lang=objc git.coding.net/bobxuyang/bip32-39-golang-lib
//
// File is generated by gobind. Do not edit.

#ifndef __Seed39_H__
#define __Seed39_H__

@import Foundation;
#include "Universe.objc.h"


/**
 * CheckMnemonic exported
 */
FOUNDATION_EXPORT BOOL Seed39CheckMnemonic(NSString* mnemonic);

/**
 * DeriveRaw exported
 */
FOUNDATION_EXPORT NSString* Seed39DeriveRaw(NSString* seed, NSString* path);

/**
 * DeriveWIF exported
 */
FOUNDATION_EXPORT NSString* Seed39DeriveWIF(NSString* seed, NSString* path, BOOL compressed);

/**
 * Derivepath exported
 */
FOUNDATION_EXPORT NSString* Seed39Derivepath(NSString* seed, NSString* path);

FOUNDATION_EXPORT void Seed39GenAddress(void);

FOUNDATION_EXPORT NSString* Seed39GetEthereumAddressFromPrivateKey(NSString* priKey);

FOUNDATION_EXPORT NSString* Seed39GetEthereumPublicKeyFromPrivateKey(NSString* priKey);

FOUNDATION_EXPORT void Seed39GetPublicKey(void);

/**
 * KeyDecrypt exported
 */
FOUNDATION_EXPORT NSString* Seed39KeyDecrypt(NSString* keyStr, NSString* cryptoText);

/**
 * KeyEncrypt exported
 */
FOUNDATION_EXPORT NSString* Seed39KeyEncrypt(NSString* keyStr, NSString* cryptoText);

FOUNDATION_EXPORT void Seed39Main(void);

/**
 * NewMnemonic exported
 */
FOUNDATION_EXPORT NSString* Seed39NewMnemonic(void);

/**
 * SeedByMnemonic exported
 */
FOUNDATION_EXPORT NSString* Seed39SeedByMnemonic(NSString* mnemonic);

FOUNDATION_EXPORT void Seed39SignERC20(void);

FOUNDATION_EXPORT void Seed39SignEth(void);

FOUNDATION_EXPORT NSString* Seed39SignEthereumTx(NSString* chainId, NSString* fromPriKey, NSString* toAdd, NSString* amount, NSString* nonce, NSString* gasLimit, NSString* gasPrice, NSString* tokenAdd);

#endif
