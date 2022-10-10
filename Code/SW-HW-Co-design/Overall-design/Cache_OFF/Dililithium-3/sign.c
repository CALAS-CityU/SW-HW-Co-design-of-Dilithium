#include <stdint.h>
#include "params.h"
#include "sign.h"
#include "packing.h"
#include "polyvec.h"
#include "poly.h"
//#include "randombytes.h"
#include "random.h"
#include "symmetric.h"
#include "fips202.h"
#include "HW_ACC.h"
#include "platform.h"
/*************************************************
* Name:        crypto_sign_keypair
*
* Description: Generates public and private key.
*
* Arguments:   - uint8_t *pk: pointer to output public key (allocated
*                             array of CRYPTO_PUBLICKEYBYTES bytes)
*              - uint8_t *sk: pointer to output private key (allocated
*                             array of CRYPTO_SECRETKEYBYTES bytes)
*
* Returns 0 (success)
**************************************************/
int crypto_sign_keypair(uint8_t *pk, uint8_t *sk) {
  uint8_t seedbuf[3*SEEDBYTES];
  uint8_t tr[CRHBYTES];
  const uint8_t *rho, *rhoprime, *key;
  polyvecl s1, s1hat;
  polyveck mat[L], s2, t1, t0;

  /* Get randomness for rho, rhoprime and key */
  randombytes(seedbuf, SEEDBYTES);
  shake256_Hardware(seedbuf, 3*SEEDBYTES, seedbuf, SEEDBYTES);//shake256(seedbuf, 3*SEEDBYTES, seedbuf, SEEDBYTES);
  rho = seedbuf;
  rhoprime = seedbuf + SEEDBYTES;
  key = seedbuf + 2*SEEDBYTES;

  /* Expand matrix */
  polyvec_matrix_expand_Hardware_new(mat, rho);//polyvec_matrix_expand(mat, rho);

  /* Sample short vectors s1 and s2 */
  polyvecl_uniform_eta_Hardware(&s1, rhoprime, 0);//polyvecl_uniform_eta(&s1, rhoprime, 0);
  polyveck_uniform_eta_Hardware(&s2, rhoprime, L);//polyveck_uniform_eta(&s2, rhoprime, L);

  /* Matrix-vector multiplication */
  s1hat = s1;

  polyvecl_ntt_Hardware(&s1hat);
  polyvec_matrix_PWM_Hardware_new(mat, &s1hat);
  polyvec_matrix_add_Hardware(&t1, mat);
  polyveck_invntt_Hardware(&t1);/*polyvecl_ntt(&s1hat);polyvec_matrix_pointwise_montgomery(&t1, mat, &s1hat);polyveck_reduce(&t1);polyveck_invntt_tomont(&t1);*/

  /* Add error vector s2 */
  polyveck_add_Hardware(&t1, &t1, &s2);//polyveck_add(&t1, &t1, &s2);

  /* Extract t1 and write public key */
  //polyveck_caddq(&t1);
  polyveck_power2round(&t1, &t0, &t1);
  pack_pk(pk, rho, &t1);

  /* Compute CRH(rho, t1) and write secret key */
  shake256_Hardware(tr, CRHBYTES, pk, CRYPTO_PUBLICKEYBYTES);//crh(tr, pk, CRYPTO_PUBLICKEYBYTES);
  pack_sk(sk, rho, tr, key, &t0, &s1, &s2);

  return 0;
}

/*************************************************
* Name:        crypto_sign_signature
*
* Description: Computes signature.
*
* Arguments:   - uint8_t *sig:   pointer to output signature (of length CRYPTO_BYTES)
*              - size_t *siglen: pointer to output length of signature
*              - uint8_t *m:     pointer to message to be signed
*              - size_t mlen:    length of message
*              - uint8_t *sk:    pointer to bit-packed secret key
*
* Returns 0 (success)
**************************************************/
int crypto_sign_signature(uint8_t *sig,
                          size_t *siglen,
                          const uint8_t *m,
                          size_t mlen,
                          const uint8_t *sk)
{
  unsigned int n;
  uint8_t seedbuf[2*SEEDBYTES + 3*CRHBYTES];
  uint8_t *rho, *tr, *key, *mu, *rhoprime;
  uint16_t nonce = 0;
  polyvecl s1, y, z;
  polyveck mat[L], mat_result[L], t0, s2, w1, w0, h;
  poly cp;
  //keccak_state state;

  rho = seedbuf;
  tr = rho + SEEDBYTES;
  key = tr + CRHBYTES;
  mu = key + SEEDBYTES;
  rhoprime = mu + CRHBYTES;
  unpack_sk(rho, tr, key, &t0, &s1, &s2, sk);

  /* Compute CRH(tr, msg) */
  /*shake256_init(&state);shake256_absorb(&state, tr, CRHBYTES);shake256_absorb(&state, m, mlen);shake256_finalize(&state);shake256_squeeze(mu, CRHBYTES, &state);*/
  shake256_Dual_Hardware(mu, CRHBYTES, tr, CRHBYTES, m, mlen);

#ifdef DILITHIUM_RANDOMIZED_SIGNING
  randombytes(rhoprime, CRHBYTES);
#else
  shake256_Hardware(rhoprime, CRHBYTES, key, SEEDBYTES + CRHBYTES);//crh(rhoprime, key, SEEDBYTES + CRHBYTES);
#endif

  /* Expand matrix and transform vectors */
  polyvec_matrix_expand_Hardware_new(mat, rho);//polyvec_matrix_expand(mat, rho);
  polyvecl_ntt_Hardware(&s1);//polyvecl_ntt(&s1);
  polyveck_ntt_Hardware(&s2);//polyveck_ntt(&s2);
  polyveck_ntt_Hardware(&t0);//polyveck_ntt(&t0);

rej:
  /* Sample intermediate vector y */
  polyvecl_uniform_gamma1_Hardware(&y, rhoprime, nonce++);//polyvecl_uniform_gamma1(&y, rhoprime, nonce++);
  z = y;
  polyvecl_ntt_Hardware(&z);//polyvecl_ntt(&z);

  /* Matrix-vector multiplication */
  polyvec_matrix_PWM_Hardware_sign(mat_result, mat, &z);
  polyvec_matrix_add_Hardware(&w1, mat_result);
  polyveck_invntt_Hardware(&w1);/*polyvec_matrix_pointwise_montgomery(&w1, mat, &z);polyveck_reduce(&w1);polyveck_invntt_tomont(&w1);*/

  /* Decompose w and call the random oracle */
  //polyveck_caddq(&w1);
  polyveck_decompose(&w1, &w0, &w1);
  polyveck_pack_w1(sig, &w1);

  /*shake256_init(&state);shake256_absorb(&state, mu, CRHBYTES);shake256_absorb(&state, sig, K*POLYW1_PACKEDBYTES);shake256_finalize(&state);shake256_squeeze(sig, SEEDBYTES, &state);*/
  shake256_Dual_Hardware(sig, SEEDBYTES, mu, CRHBYTES, sig, K*POLYW1_PACKEDBYTES);
  poly_challenge(&cp, sig);
  NTT_Hardware(&cp);//poly_ntt(&cp);

  /* Compute z, reject if it reveals secret */
  polyvecl_pointwise_Hardware(&z, &cp, &s1);//polyvecl_pointwise_poly_montgomery(&z, &cp, &s1);
  polyvecl_invntt_Hardware(&z);//polyvecl_invntt_tomont(&z);
  polyvecl_add_Hardware(&z, &z, &y);//polyvecl_add(&z, &z, &y);
  polyvecl_reduce(&z);
  if(polyvecl_chknorm(&z, GAMMA1 - BETA))
    goto rej;

  /* Check that subtracting cs2 does not change high bits of w and low bits
   * do not reveal secret information */
  polyveck_pointwise_Hardware(&h, &cp, &s2);//polyveck_pointwise_poly_montgomery(&h, &cp, &s2);
  polyveck_invntt_Hardware(&h);//polyveck_invntt_tomont(&h);
  polyveck_sub_Hardware(&w0, &w0, &h);//polyveck_sub(&w0, &w0, &h);
  polyveck_reduce(&w0);
  if(polyveck_chknorm(&w0, GAMMA2 - BETA))
    goto rej;

  /* Compute hints for w1 */
  polyveck_pointwise_Hardware(&h, &cp, &t0);//polyveck_pointwise_poly_montgomery(&h, &cp, &t0);
  polyveck_invntt_Hardware(&h);//polyveck_invntt_tomont(&h);
  polyveck_reduce(&h);
  if(polyveck_chknorm(&h, GAMMA2))
    goto rej;

  polyveck_add_Hardware(&w0, &w0, &h);//polyveck_add(&w0, &w0, &h);
  //polyveck_caddq(&w0);
  n = polyveck_make_hint(&h, &w0, &w1);
  if(n > OMEGA)
    goto rej;

  /* Write signature */
  pack_sig(sig, sig, &z, &h);
  *siglen = CRYPTO_BYTES;
  return 0;
}

/*************************************************
* Name:        crypto_sign
*
* Description: Compute signed message.
*
* Arguments:   - uint8_t *sm: pointer to output signed message (allocated
*                             array with CRYPTO_BYTES + mlen bytes),
*                             can be equal to m
*              - size_t *smlen: pointer to output length of signed
*                               message
*              - const uint8_t *m: pointer to message to be signed
*              - size_t mlen: length of message
*              - const uint8_t *sk: pointer to bit-packed secret key
*
* Returns 0 (success)
**************************************************/
int crypto_sign(uint8_t *sm,
                size_t *smlen,
                const uint8_t *m,
                size_t mlen,
                const uint8_t *sk)
{
  size_t i;

  for(i = 0; i < mlen; ++i)
    sm[CRYPTO_BYTES + mlen - 1 - i] = m[mlen - 1 - i];
  crypto_sign_signature(sm, smlen, sm + CRYPTO_BYTES, mlen, sk);
  *smlen += mlen;
  return 0;
}

/*************************************************
* Name:        crypto_sign_verify
*
* Description: Verifies signature.
*
* Arguments:   - uint8_t *m: pointer to input signature
*              - size_t siglen: length of signature
*              - const uint8_t *m: pointer to message
*              - size_t mlen: length of message
*              - const uint8_t *pk: pointer to bit-packed public key
*
* Returns 0 if signature could be verified correctly and -1 otherwise
**************************************************/
int crypto_sign_verify(const uint8_t *sig,
                       size_t siglen,
                       const uint8_t *m,
                       size_t mlen,
                       const uint8_t *pk)
{
  unsigned int i;
  uint8_t buf[K*POLYW1_PACKEDBYTES];
  uint8_t rho[SEEDBYTES];
  uint8_t mu[CRHBYTES];
  uint8_t c[SEEDBYTES];
  uint8_t c2[SEEDBYTES];
  poly cp;
  polyvecl z;
  polyveck mat[L], t1, w1, h;
  keccak_state state;

  if(siglen != CRYPTO_BYTES)
    return -1;

  unpack_pk(rho, &t1, pk);
  if(unpack_sig(c, &z, &h, sig))
    return -1;
  if(polyvecl_chknorm(&z, GAMMA1 - BETA))
    return -1;

  /* Compute CRH(CRH(rho, t1), msg) */
  shake256_Hardware(mu, CRHBYTES, pk, CRYPTO_PUBLICKEYBYTES);//crh(mu, pk, CRYPTO_PUBLICKEYBYTES);
  shake256_Dual_Hardware(mu, CRHBYTES, mu, CRHBYTES, m, mlen);
  /*crh(mu, pk, CRYPTO_PUBLICKEYBYTES);shake256_init(&state);shake256_absorb(&state, mu, CRHBYTES);shake256_absorb(&state, m, mlen);shake256_finalize(&state);shake256_squeeze(mu, CRHBYTES, &state);*/

  /* Matrix-vector multiplication; compute Az - c2^dt1 */
  poly_challenge(&cp, c);
  polyvec_matrix_expand_Hardware_new(mat, rho);//polyvec_matrix_expand(mat, rho);

  polyvecl_ntt_Hardware(&z);//polyvecl_ntt(&z);
  polyvec_matrix_PWM_Hardware_new(mat, &z);
  polyvec_matrix_add_Hardware(&w1, mat);//polyvec_matrix_pointwise_montgomery(&w1, mat, &z);

  NTT_Hardware(&cp);//poly_ntt(&cp);
  polyveck_shiftl(&t1);
  polyveck_ntt_Hardware(&t1);//polyveck_ntt(&t1);
  polyveck_pointwise_Hardware(&t1, &cp, &t1);//polyveck_pointwise_poly_montgomery(&t1, &cp, &t1);

  polyveck_sub_Hardware(&w1, &w1, &t1);//polyveck_sub(&w1, &w1, &t1);polyveck_reduce(&w1);
  polyveck_invntt_Hardware(&w1);//polyveck_invntt_tomont(&w1);

  /* Reconstruct w1 */
  //polyveck_caddq(&w1);
  polyveck_use_hint(&w1, &w1, &h);
  polyveck_pack_w1(buf, &w1);

  /* Call random oracle and verify challenge */
  shake256_Dual_Hardware(c2, SEEDBYTES, mu, CRHBYTES, buf, K*POLYW1_PACKEDBYTES);
  /*shake256_init(&state);shake256_absorb(&state, mu, CRHBYTES);shake256_absorb(&state, buf, K*POLYW1_PACKEDBYTES);shake256_finalize(&state);shake256_squeeze(c2, SEEDBYTES, &state);*/

  for(i = 0; i < SEEDBYTES; ++i)
    if(c[i] != c2[i])
      return -1;

  return 0;
}

/*************************************************
* Name:        crypto_sign_open
*
* Description: Verify signed message.
*
* Arguments:   - uint8_t *m: pointer to output message (allocated
*                            array with smlen bytes), can be equal to sm
*              - size_t *mlen: pointer to output length of message
*              - const uint8_t *sm: pointer to signed message
*              - size_t smlen: length of signed message
*              - const uint8_t *pk: pointer to bit-packed public key
*
* Returns 0 if signed message could be verified correctly and -1 otherwise
**************************************************/
int crypto_sign_open(uint8_t *m,
                     size_t *mlen,
                     const uint8_t *sm,
                     size_t smlen,
                     const uint8_t *pk)
{
  size_t i;

  if(smlen < CRYPTO_BYTES)
    goto badsig;

  *mlen = smlen - CRYPTO_BYTES;
  if(crypto_sign_verify(sm, CRYPTO_BYTES, sm + CRYPTO_BYTES, *mlen, pk))
    goto badsig;
  else {
    /* All good, copy msg, return 0 */
    for(i = 0; i < *mlen; ++i)
      m[i] = sm[CRYPTO_BYTES + i];
    return 0;
  }

badsig:
  /* Signature verification failed */
  *mlen = -1;
  for(i = 0; i < smlen; ++i)
    m[i] = 0;

  return -1;
}
