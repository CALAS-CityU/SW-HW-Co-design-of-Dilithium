#ifndef __RANDOM_H__
#define __RANDOM_H__

typedef struct {
    unsigned char   Key[32];
    unsigned char   V[16];
    int             reseed_counter;
} AES256_CTR_DRBG_struct;

// Generate random bytes and output the result to random_array
void randombytes(unsigned char *x, unsigned int xlen);

#endif
