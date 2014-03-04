/* Blowfish routines, after Bruce Schneier */
/* Written by David Madore <david.madore@ens.fr>, with code taken in
 * great part from Bruce Schneier. */
/* Public domain (1999/11/22) */

/* Note: these routines do not depend on endianness. */

/* === The header === */

/* Put this in blowfish.h if you don't like having everything in one
 * big file. */

#ifndef _DMADORE_BLOWFISH_H
#define _DMADORE_BLOWFISH_H

/* --- Basic blowfish routines --- */

#define NBROUNDS 16

struct blf_ctx {
    /* The subkeys used by the blowfish cipher */
    unsigned long P[NBROUNDS+2], S[4][256];
};

/* Encipher one 64-bit quantity (divided in two 32-bit quantities)
 * using the precalculated subkeys). */
void Blowfish_encipher (const struct blf_ctx *c,
                        unsigned long *xl, unsigned long *xr);

/* Decipher one 64-bit quantity (divided in two 32-bit quantities)
 * using the precalculated subkeys). */
void Blowfish_decipher (const struct blf_ctx *c,
                        unsigned long *xl, unsigned long *xr);

/* Initialize the cipher by calculating the subkeys from the key. */
void Blowfish_initialize (struct blf_ctx *c,
                          const unsigned char key[], int key_bytes);

/* --- Blowfish used in Electronic Code Book (ECB) mode --- */

struct blf_ecb_ctx {
    /* Whether we are encrypting (rather than decrypting) */
    char encrypt;
    /* The blowfish subkeys */
    struct blf_ctx c;
    /* The 64-bits of data being written */
    unsigned long dl, dr;
    /* Our position within the 64 bits (always between 0 and 7) */
    int b;
    /* The callback function to be called with every byte produced */
    void (* callback) (unsigned char byte, void *user_data);
    /* The user data to pass the the callback function */
    void *user_data;
};

/* Start an ECB Blowfish cipher session: specify whether we are
 * encrypting or decrypting, what key is to be used, and what callback
 * should be called for every byte produced. */
void Blowfish_ecb_start (struct blf_ecb_ctx *c, char encrypt,
                         const unsigned char key[], int key_bytes,
                         void (* callback) (unsigned char byte,
                                            void *user_data),
                         void *user_data);

/* Feed one byte to an ECB Blowfish cipher session. */
void Blowfish_ecb_feed (struct blf_ecb_ctx *c, unsigned char inb);

/* Stop an ECB Blowfish session (i.e. flush the remaining bytes). */
void Blowfish_ecb_stop (struct blf_ecb_ctx *c);

/* --- Blowfish used in Cipher Block Chaining (CBC) mode --- */

struct blf_cbc_ctx {
    /* Whether we are encrypting (rather than decrypting) */
    char encrypt;
    /* The blowfish subkeys */
    struct blf_ctx c;
    /* The 64-bits of data being written */
    unsigned long dl, dr;
    /* The last 64 bits of ciphertext */
    unsigned long ll, lr;
    /* Our position within the 64 bits (always between 0 and 7) */
    int b;
    /* The callback function to be called with every byte produced */
    void (* callback) (unsigned char byte, void *user_data);
    /* The user data to pass the the callback function */
    void *user_data;
};

/* Start a CBC Blowfish cipher session: specify whether we are
 * encrypting or decrypting, what key is to be used, and what callback
 * should be called for every byte produced. */
void Blowfish_cbc_start (struct blf_cbc_ctx *c, char encrypt,
                         const unsigned char key[], int key_bytes,
                         void (* callback) (unsigned char byte,
                                            void *user_data),
                         void *user_data);

/* Feed one byte to a CBC Blowfish cipher session. */
void Blowfish_cbc_feed (struct blf_cbc_ctx *c, unsigned char inb);

/* Stop a CBC Blowfish session (i.e. flush the remaining bytes). */
void Blowfish_cbc_stop (struct blf_cbc_ctx *c);

#endif /* not defined _DMADORE_BLOWFISH_H */