#ifdef PROTOTYPE
int reverseBytes(int);
int test_reverseBytes(int);
#endif
#ifdef DECL
 {"reverseBytes", (funct_t) reverseBytes, (funct_t) test_reverseBytes, 1,
    "! ~ & ^ | + << >>", 25, 3,
  {{TMin, TMax},{TMin,TMax},{TMin,TMax}}},
#endif
#ifdef CODE
/* 
 * reverseBytes - reverse the bytes of x
 *   Example: reverseBytes(0x01020304) = 0x04030201
 *   Legal ops: ! ~ & ^ | + << >>
 *   Max ops: 25
 *   Rating: 3
 */
int reverseBytes(int x) {
#ifdef FIX
  int result = (x & 0xff) << 24;
  result |= ((x >> 8) & 0xff) << 16;
  result |= ((x >> 16) & 0xff) << 8;
  result |= ((x >> 24) & 0xff);
  return result;
#else
  return 2;
#endif
}
#endif
#ifdef TEST
int test_reverseBytes(int x)
{
    unsigned char byte0 = (x >> 0);
    unsigned char byte1 = (x >> 8);
    unsigned char byte2 = (x >> 16);
    unsigned char byte3 = (x >> 24);
    unsigned result = (byte0<<24)|(byte1<<16)|(byte2<<8)|(byte3<<0);
    return result;
}
#endif
