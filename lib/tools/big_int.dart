// ignore_for_file: prefer_typing_uninitialized_variables, curly_braces_in_flow_control_structures

import 'dart:core';
import 'dart:math';

class MyBigInt {
  double trueRandom() {
    return Random().nextDouble();
  }

  bool trueIntVal(val) {
    if (val is int) {
      return val != 0;
    }
    return val != null;
  }

  var bpe; //bits stored per array element
  var mask; //AND this with an array element to chop it down to bpe bits
  var radix;

  var digitsStr;
  var one;

  var t;
  var ss; //used in mult_()
  var s0; //used in mult_mod(), square_mod()
  var s1; //used in pow_mod(), mult_mod(), square_mod()
  var s2; //used in pow_mod(), mult_mod()
  var s3; //used in pow_mod()
  var s4, s5; //used in _mod()
  var s6; //used in bigInt2str()
  var s7; //used in pow_mod()
  var T; //used in GCD_()
  var sa; //used in _mont()
  // ignore: non_constant_identifier_names
  var mr_x1,
      // ignore: non_constant_identifier_names
      mr_r,
      // ignore: non_constant_identifier_names
      mr_a; //used in millerRabin()
  // ignore: non_constant_identifier_names
  var eg_v,
      // ignore: non_constant_identifier_names
      eg_u,
      // ignore: non_constant_identifier_names
      eg_A,
      // ignore: non_constant_identifier_names
      eg_B,
      // ignore: non_constant_identifier_names
      eg_C,
      // ignore: non_constant_identifier_names
      eg_D; //used in eGCD_(), inverse_mod()
  // ignore: non_constant_identifier_names
  var md_q1,
      // ignore: non_constant_identifier_names
      md_q2,
      // ignore: non_constant_identifier_names
      md_q3,
      // ignore: non_constant_identifier_names
      md_r,
      // ignore: non_constant_identifier_names
      md_r1,
      // ignore: non_constant_identifier_names
      md_r2,
      // ignore: non_constant_identifier_names
      md_tt; //used in _mod()

  var primes,
      pows,
      // ignore: non_constant_identifier_names
      s_i,
      // ignore: non_constant_identifier_names
      s_i2,
      // ignore: non_constant_identifier_names
      s_R,
      // ignore: non_constant_identifier_names
      s_rm,
      // ignore: non_constant_identifier_names
      s_q,
      // ignore: non_constant_identifier_names
      s_n1;
  // ignore: non_constant_identifier_names
  var s_a,
      // ignore: non_constant_identifier_names
      s_r2,
      // ignore: non_constant_identifier_names
      s_n,
      // ignore: non_constant_identifier_names
      s_b,
      // ignore: non_constant_identifier_names
      s_d,
      // ignore: non_constant_identifier_names
      s_x1,
      // ignore: non_constant_identifier_names
      s_x2,
      // ignore: non_constant_identifier_names
      s_aa; //used in _randTruePrime()

  var rpprb =
      List.empty(); //used in randProbPrimeRounds() (which also uses "primes")
  MyBigInt() {
    bpe = 15;
    mask = 32767;
    radix = mask + 1;
    digitsStr =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_=!@#\$%^&*()[]{}|;:,.<>/?`~ \\\'"+-';

    one = int2bigInt(1, 1, 1); //constant used in pow_mod()

    t = List.empty();
    ss = t; //used in mult_()
    s0 = t; //used in multMod_(); squareMod_()
    s1 = t; //used in powMod_(); multMod_(); squareMod_()
    s2 = t; //used in powMod_(); multMod_()
    s3 = t; //used in powMod_()
    s4 = t;
    s5 = t; //used in mod_()
    s6 = t; //used in bigInt2str()
    s7 = t; //used in powMod_()
    T = t; //used in GCD_()
    sa = t; //used in mont_()
    mr_x1 = t;
    mr_r = t;
    mr_a = t; //used in millerRabin()
    eg_v = t;
    eg_u = t;
    eg_A = t;
    eg_B = t;
    eg_C = t;
    eg_D = t; //used in eGCD_(); inverseMod_()
    md_q1 = t;
    md_q2 = t;
    md_q3 = t;
    md_r = t;
    md_r1 = t;
    md_r2 = t;
    md_tt = t; //used in mod_()

    primes = t;
    pows = t;
    s_i = t;
    s_i2 = t;
    s_R = t;
    s_rm = t;
    s_q = t;
    s_n1 = t;
    s_a = t;
    s_r2 = t;
    s_n = t;
    s_b = t;
    s_d = t;
    s_x1 = t;
    s_x2 = t;
    s_aa = t; //used in randTruePrime_()

    rpprb = t;
  }
  //return array of all primes less than integer n
  findPrimes(n) {
    var i, s, p, ans;
    s = List.filled(n, 0);
    for (i = 0; i < n; i++) s[i] = 0;
    s[0] = 2;
    p = 0; //first p elements of s are primes, the rest are a sieve
    for (; s[p] < n;) {
      //s[p] is the pth prime
      for (i = s[p] * s[p]; i < n; i += s[p]) //mark multiples of s[p]
        s[i] = 1;
      p++;
      s[p] = s[p - 1] + 1;
      for (;
          s[p] < n && trueIntVal(s[s[p]]);
          s[p]++) {} //find next prime (where s[p]==0)
    }
    ans = List.filled(p, 0);
    for (i = 0; i < p; i++) ans[i] = s[i];
    return ans;
  }

//does a single round of Miller-Rabin base b consider x to be a possible prime?
//x is a bigInt, and b is an integer, with b<x
  millerRabinInt(x, b) {
    if (mr_x1.length != x.length) {
      mr_x1 = dup(x);
      mr_r = dup(x);
      mr_a = dup(x);
    }

    copyInt_(mr_a, b);
    return millerRabin(x, mr_a);
  }

//does a single round of Miller-Rabin base b consider x to be a possible prime?
//x and b are bigInts with b<x
  millerRabin(x, b) {
    var i, j, k, s;

    if (mr_x1.length != x.length) {
      mr_x1 = dup(x);
      mr_r = dup(x);
      mr_a = dup(x);
    }

    copy_(mr_a, b);
    copy_(mr_r, x);
    copy_(mr_x1, x);

    addInt_(mr_r, -1);
    addInt_(mr_x1, -1);

    //s=the highest power of two that divides mr_r
    k = 0;
    for (i = 0; i < mr_r.length; i++)
      for (j = 1; j < mask; j <<= 1)
        if (trueIntVal(x[i] & j)) {
          s = (k < mr_r.length + bpe ? k : 0);
          i = mr_r.length;
          j = mask;
        } else
          k++;

    if (trueIntVal(s)) rightShift_(mr_r, s);

    pow_mod(mr_a, mr_r, x);

    if (!trueIntVal(equalsInt(mr_a, 1)) && !trueIntVal(equals(mr_a, mr_x1))) {
      j = 1;
      while (j <= s - 1 && !trueIntVal(equals(mr_a, mr_x1))) {
        square_mod(mr_a, x);
        if (trueIntVal(equalsInt(mr_a, 1))) {
          return 0;
        }
        j++;
      }
      if (!trueIntVal(equals(mr_a, mr_x1))) {
        return 0;
      }
    }
    return 1;
  }

//returns how many bits long the bigInt is, not counting leading zeros.
  bitSize(x) {
    var j, z, w;
    for (j = x.length - 1; (x[j] == 0) && (j > 0); j--) {}
    z = 0;
    w = x[j];
    // ignore: unnecessary_statements
    for (; w; trueIntVal((w >>= 1)), z++) {}
    z += bpe * j;
    return z;
  }

//return a copy of x with at least n elements, adding leading zeros if needed
  expand(x, n) {
    var ans = int2bigInt(0, (x.length > n ? x.length : n) * bpe, 0);
    copy_(ans, x);
    return ans;
  }

//return a k-bit true random prime using Maurer's algorithm.
  randTruePrime(k) {
    var ans = int2bigInt(0, k, 0);
    _randTruePrime(ans, k);
    return trim(ans, 1);
  }

//return a k-bit random probable prime with probability of error < 2^-80
  randProbPrime(k) {
    if (k >= 600) return randProbPrimeRounds(k, 2); //numbers from HAC table 4.3
    if (k >= 550) return randProbPrimeRounds(k, 4);
    if (k >= 500) return randProbPrimeRounds(k, 5);
    if (k >= 400) return randProbPrimeRounds(k, 6);
    if (k >= 350) return randProbPrimeRounds(k, 7);
    if (k >= 300) return randProbPrimeRounds(k, 9);
    if (k >= 250)
      return randProbPrimeRounds(k, 12); //numbers from HAC table 4.4
    if (k >= 200) return randProbPrimeRounds(k, 15);
    if (k >= 150) return randProbPrimeRounds(k, 18);
    if (k >= 100) return randProbPrimeRounds(k, 27);
    return randProbPrimeRounds(
        k, 40); //number from HAC remark 4.26 (only an estimate)
  }

//return a k-bit probable random prime using n rounds of Miller Rabin (after trial division with small primes)
  randProbPrimeRounds(k, n) {
    var ans, i, divisible, B;
    B = 30000; //B is largest prime to use in trial division
    ans = int2bigInt(0, k, 0);

    //optimization: try larger and smaller B to find the best limit.

    if (primes.length == 0)
      primes = findPrimes(30000); //check for divisibility by primes <=30000

    if (rpprb.length != ans.length) rpprb = dup(ans);

    for (;;) {
      //keep trying random values for ans until one appears to be prime
      //optimization: pick a random number times L=2*3*5*...*p, plus a
      //   random element of the list of all numbers in [0,L) not divisible by any prime up to p.
      //   This can reduce the amount of random number generation.

      _randBigInt(ans, k, 0); //ans = a random odd number to check
      ans[0] |= 1;
      divisible = 0;

      //check ans for divisibility by small primes up to B
      for (i = 0; (i < primes.length) && (primes[i] <= B); i++)
        if (modInt(ans, primes[i]) == 0 &&
            !trueIntVal(equalsInt(ans, primes[i]))) {
          divisible = 1;
          break;
        }

      //optimization: change millerRabin so the base can be bigger than the number being checked, then eliminate the while here.

      //do n rounds of Miller Rabin, with random bases less than ans
      for (i = 0; i < n && !trueIntVal(divisible); i++) {
        _randBigInt(rpprb, k, 0);
        while (
            !trueIntVal(greater(ans, rpprb))) //pick a random rpprb that's < ans
          _randBigInt(rpprb, k, 0);
        if (!trueIntVal(millerRabin(ans, rpprb))) divisible = 1;
      }

      if (!trueIntVal(divisible)) return ans;
    }
  }

//return a new bigInt equal to (x mod n) for bigInts x and n.
  mod(x, n) {
    var ans = dup(x);
    _mod(ans, n);
    return trim(ans, 1);
  }

//return (x+n) where x is a bigInt and n is an integer.
  addInt(x, n) {
    var ans = expand(x, x.length + 1);
    addInt_(ans, n);
    return trim(ans, 1);
  }

//return x*y for bigInts x and y. This is faster when y<x.
  mult(x, y) {
    var ans = expand(x, x.length + y.length);
    mult_(ans, y);
    return trim(ans, 1);
  }

//return (x**y mod n) where x,y,n are bigInts and ** is exponentiation.  0**0=1. Faster for odd n.
  powMod(x, y, n) {
    var ans = expand(x, n.length);
    pow_mod(ans, trim(y, 2),
        trim(n, 2)); //this should work without the trim, but doesn't
    return trim(ans, 1);
  }

//return (x-y) for bigInts x and y.  Negative answers will be 2s complement
  sub(x, y) {
    var ans = expand(x, (x.length > y.length ? x.length + 1 : y.length + 1));
    sub_(ans, y);
    return trim(ans, 1);
  }

//return (x+y) for bigInts x and y.
  add(x, y) {
    var ans = expand(x, (x.length > y.length ? x.length + 1 : y.length + 1));
    add_(ans, y);
    return trim(ans, 1);
  }

//return (x**(-1) mod n) for bigInts x and n.  If no inverse exists, it returns null
  inverseMod(x, n) {
    var ans = expand(x, n.length);
    var s;
    s = inverse_mod(ans, n);
    return s ? trim(ans, 1) : null;
  }

//return (x*y mod n) for bigInts x,y,n.  For greater speed, let y<x.
  multMod(x, y, n) {
    var ans = expand(x, n.length);
    mult_mod(ans, y, n);
    return trim(ans, 1);
  }

//generate a k-bit true random prime using Maurer's algorithm,
//and put it into ans.  The bigInt ans must be large enough to hold it.
  _randTruePrime(ans, k) {
    var c, m, pm, dd, j, r, B, divisible, z, zz, recSize;

    if (primes.length == 0)
      primes = findPrimes(30000); //check for divisibility by primes <=30000

    if (pows.length == 0) {
      pows = List.filled(512, 0);
      for (j = 0; j < 512; j++) {
        pows[j] = pow(2, j / 511.0 - 1.0);
      }
    }

    //c and m should be tuned for a particular machine and value of k, to maximize speed
    c = 0.1; //c=0.1 in HAC
    m = 20; //generate this k-bit number by first recursively generating a number that has between k/2 and k-m bits
    var recLimit =
        20; //stop recursion when k <=recLimit.  Must have recLimit >= 2

    if (s_i2.length != ans.length) {
      s_i2 = dup(ans);
      s_R = dup(ans);
      s_n1 = dup(ans);
      s_r2 = dup(ans);
      s_d = dup(ans);
      s_x1 = dup(ans);
      s_x2 = dup(ans);
      s_b = dup(ans);
      s_n = dup(ans);
      s_i = dup(ans);
      s_rm = dup(ans);
      s_q = dup(ans);
      s_a = dup(ans);
      s_aa = dup(ans);
    }

    if (k <= recLimit) {
      //generate small random primes by trial division up to its square root
      pm = (1 << ((k + 2) >> 1)) -
          1; //pm is binary number with all ones, just over sqrt(2^k)
      copyInt_(ans, 0);
      for (dd = 1; trueIntVal(dd);) {
        dd = 0;
        ans[0] = 1 |
            (1 << (k - 1)) |
            (trueRandom() * (1 << k))
                .floor(); //random, k-bit, odd integer, with msb 1
        for (j = 1;
            (j < primes.length) && ((primes[j] & pm) == primes[j]);
            j++) {
          //trial division by all primes 3...sqrt(2^k)
          if (0 == (ans[0] % primes[j])) {
            dd = 1;
            break;
          }
        }
      }
      carry_(ans);
      return;
    }

    B = c *
        k *
        k; //try small primes up to B (or all the primes[] array if the largest is less than B).
    if (k >
        2 * m) //generate this k-bit number by first recursively generating a number that has between k/2 and k-m bits
      for (r = 1; k - k * r <= m;)
        r = pows[(trueRandom() * 512).floor()]; //r=Math.pow(2,Math.random()-1);
    else
      r = .5;

    //simulation suggests the more complex algorithm using r=.333 is only slightly faster.

    recSize = (r * k).floor() + 1;

    _randTruePrime(s_q, recSize);
    copyInt_(s_i2, 0);
    s_i2[((k - 2) / bpe)] |= (1 << ((k - 2) % bpe)).floor(); //s_i2=2^(k-2)
    divide_(s_i2, s_q, s_i, s_rm); //s_i=floor((2^(k-1))/(2q))

    z = bitSize(s_i);

    for (;;) {
      for (;;) {
        //generate z-bit numbers until one falls in the range [0,s_i-1]
        _randBigInt(s_R, z, 0);
        if (trueIntVal(greater(s_i, s_R))) break;
      } //now s_R is in the range [0,s_i-1]
      addInt_(s_R, 1); //now s_R is in the range [1,s_i]
      add_(s_R, s_i); //now s_R is in the range [s_i+1,2*s_i]

      copy_(s_n, s_q);
      mult_(s_n, s_R);
      multInt_(s_n, 2);
      addInt_(s_n, 1); //s_n=2*s_R*s_q+1

      copy_(s_r2, s_R);
      multInt_(s_r2, 2); //s_r2=2*s_R

      divisible = 0;
      j = 0;
      //check s_n for divisibility by small primes up to B
      for (; (j < primes.length) && (primes[j] < B); j++)
        if (modInt(s_n, primes[j]) == 0 &&
            !trueIntVal(equalsInt(s_n, primes[j]))) {
          divisible = 1;
          break;
        }

      if (!trueIntVal(
          divisible)) //if it passes small primes check, then try a single Miller-Rabin base 2
      if (!trueIntVal(millerRabinInt(s_n,
          2))) //this line represents 75% of the total runtime for _randTruePrime
        divisible = 1;

      if (!trueIntVal(divisible)) {
        //if it passes that test, continue checking s_n
        addInt_(s_n, -3);
        for (j = s_n.length - 1;
            (s_n[j] == 0) && (j > 0);
            j--) {} //strip leading zeros

        zz = 0;
        var w = s_n[j];
        // ignore: unnecessary_statements
        for (; w; trueIntVal((w >>= 1)), zz++) {}
        zz += bpe * j; //zz=number of bits in s_n, ignoring leading zeros
        for (;;) {
          //generate z-bit numbers until one falls in the range [0,s_n-1]
          _randBigInt(s_a, zz, 0);
          if (trueIntVal(greater(s_n, s_a))) break;
        } //now s_a is in the range [0,s_n-1]
        addInt_(s_n, 3); //now s_a is in the range [0,s_n-4]
        addInt_(s_a, 2); //now s_a is in the range [2,s_n-2]
        copy_(s_b, s_a);
        copy_(s_n1, s_n);
        addInt_(s_n1, -1);
        pow_mod(s_b, s_n1, s_n); //s_b=s_a^(s_n-1) modulo s_n
        addInt_(s_b, -1);
        if (trueIntVal(isZero(s_b))) {
          copy_(s_b, s_a);
          pow_mod(s_b, s_r2, s_n);
          addInt_(s_b, -1);
          copy_(s_aa, s_n);
          copy_(s_d, s_b);
          GCD_(s_d,
              s_n); //if s_b and s_n are relatively prime, then s_n is a prime
          if (trueIntVal(equalsInt(s_d, 1))) {
            copy_(ans, s_aa);
            return; //if we've made it this far, then s_n is absolutely guaranteed to be prime
          }
        }
      }
    }
  }

//Return an n-bit random BigInt (n>=1).  If s=1, then the most significant of those n bits is set to 1.
  randBigInt(n, s) {
    var a, b;
    a = ((n - 1) / bpe).floor() +
        2; //# array elements to hold the BigInt with a leading 0 element
    b = int2bigInt(0, 0, a);
    _randBigInt(b, n, s);
    return b;
  }

//Set b to an n-bit random BigInt.  If s=1, then the most significant of those n bits is set to 1.
//Array b must be big enough to hold the result. Must have n>=1
  _randBigInt(b, n, s) {
    var i, a;
    for (i = 0; i < b.length; i++) b[i] = 0;
    a = ((n - 1) / bpe).floor() + 1; //# array elements to hold the BigInt
    for (i = 0; i < a; i++) {
      b[i] = (trueRandom() * (1 << (bpe - 1))).floor();
    }
    b[a - 1] &= (2 << ((n - 1) % bpe)) - 1;
    if (s == 1) b[a - 1] |= (1 << ((n - 1) % bpe));
  }

//Return the greatest common divisor of bigInts x and y (each with same number of elements).
// ignore: non_constant_identifier_names
  GCD(x, y) {
    var xc, yc;
    xc = dup(x);
    yc = dup(y);
    GCD_(xc, yc);
    return xc;
  }

//set x to the greatest common divisor of bigInts x and y (each with same number of elements).
//y is destroyed.
// ignore: non_constant_identifier_names
  GCD_(x, y) {
    var i, xp, yp, A, B, C, D, q, sing;
    if (T.length != x.length) T = dup(x);

    sing = 1;
    while (trueIntVal(sing)) {
      //while y has nonzero elements other than y[0]
      sing = 0;
      for (i = 1;
          i < y.length;
          i++) //check if y has nonzero elements other than 0
        if (trueIntVal(y[i])) {
          sing = 1;
          break;
        }
      if (!trueIntVal(sing))
        break; //quit when y all zero elements except possibly y[0]

      for (i = x.length;
          !trueIntVal(x[i]) && i >= 0;
          i--) {} //find most significant element of x
      xp = x[i];
      yp = y[i];
      A = 1;
      B = 0;
      C = 0;
      D = 1;
      while (trueIntVal((yp + C) && (yp + D))) {
        q = ((xp + A) / (yp + C)).floor();
        var qp = ((xp + B) / (yp + D)).floor();
        if (q != qp) break;
        t = A - q * C;
        A = C;
        C = t; //  do (A,B,xp, C,D,yp) = (C,D,yp, A,B,xp) - q*(0,0,0, C,D,yp)
        t = B - q * D;
        B = D;
        D = t;
        t = xp - q * yp;
        xp = yp;
        yp = t;
      }
      if (trueIntVal(B)) {
        copy_(T, x);
        linComb_(x, y, A, B); //x=A*x+B*y
        linComb_(y, T, D, C); //y=D*y+C*T
      } else {
        _mod(x, y);
        copy_(T, x);
        copy_(x, y);
        copy_(y, T);
      }
    }
    if (y[0] == 0) return;
    t = modInt(x, y[0]);
    copyInt_(x, y[0]);
    y[0] = t;
    while (trueIntVal(y[0])) {
      x[0] %= y[0];
      t = x[0];
      x[0] = y[0];
      y[0] = t;
    }
  }

//do x=x**(-1) mod n, for bigInts x and n.
//If no inverse exists, it sets x to zero and returns 0, else it returns 1.
//The x array must be at least as large as the n array.
// ignore: non_constant_identifier_names
  inverse_mod(x, n) {
    var k = 1 + 2 * max(x.length, n.length);

    if (!trueIntVal(x[0] & 1) && !trueIntVal(n[0] & 1)) {
      //if both inputs are even, then inverse doesn't exist
      copyInt_(x, 0);
      return 0;
    }

    if (eg_u.length != k) {
      eg_u = List.filled(k.toInt(), 0);
      eg_v = List.filled(k.toInt(), 0);
      eg_A = List.filled(k.toInt(), 0);
      eg_B = List.filled(k.toInt(), 0);
      eg_C = List.filled(k.toInt(), 0);
      eg_D = List.filled(k.toInt(), 0);
    }

    copy_(eg_u, x);
    copy_(eg_v, n);
    copyInt_(eg_A, 1);
    copyInt_(eg_B, 0);
    copyInt_(eg_C, 0);
    copyInt_(eg_D, 1);
    for (;;) {
      while (!trueIntVal(eg_u[0] & 1)) {
        //while eg_u is even
        halve_(eg_u);
        if (!trueIntVal(eg_A[0] & 1) && !trueIntVal(eg_B[0] & 1)) {
          //if eg_A==eg_B==0 mod 2
          halve_(eg_A);
          halve_(eg_B);
        } else {
          add_(eg_A, n);
          halve_(eg_A);
          sub_(eg_B, x);
          halve_(eg_B);
        }
      }

      while (!trueIntVal(eg_v[0] & 1)) {
        //while eg_v is even
        halve_(eg_v);
        if (!trueIntVal(eg_C[0] & 1) && !trueIntVal(eg_D[0] & 1)) {
          //if eg_C==eg_D==0 mod 2
          halve_(eg_C);
          halve_(eg_D);
        } else {
          add_(eg_C, n);
          halve_(eg_C);
          sub_(eg_D, x);
          halve_(eg_D);
        }
      }

      if (!trueIntVal(greater(eg_v, eg_u))) {
        //eg_v <= eg_u
        sub_(eg_u, eg_v);
        sub_(eg_A, eg_C);
        sub_(eg_B, eg_D);
      } else {
        //eg_v > eg_u
        sub_(eg_v, eg_u);
        sub_(eg_C, eg_A);
        sub_(eg_D, eg_B);
      }

      if (trueIntVal(equalsInt(eg_u, 0))) {
        while (trueIntVal(negative(eg_C))) //make sure answer is nonnegative
          add_(eg_C, n);
        copy_(x, eg_C);

        if (!trueIntVal(equalsInt(eg_v, 1))) {
          //if GCD_(x,n)!=1, then there is no inverse
          copyInt_(x, 0);
          return 0;
        }
        return 1;
      }
    }
  }

//return x**(-1) mod n, for integers x and n.  Return 0 if there is no inverse
  inverseModInt(x, n) {
    var a = 1, b = 0;
    for (;;) {
      if (x == 1) return a;
      if (x == 0) return 0;
      b -= (a * (n / x).floor()).toInt();
      n %= x;

      if (n == 1)
        return b; //to avoid negatives, change this b to n-b, and each -= to +=
      if (n == 0) return 0;
      a -= (b * (x / n).floor()).toInt();
      x %= n;
    }
  }

//this deprecated is for backward compatibility only.
// ignore: non_constant_identifier_names
  inverseModInt_(x, n) {
    return inverseModInt(x, n);
  }

//Given positive bigInts x and y, change the bigints v, a, and b to positive bigInts such that:
//     v = GCD_(x,y) = a*x-b*y
//The bigInts v, a, b, must have exactly as many elements as the larger of x and y.
// ignore: non_constant_identifier_names
  eGCD_(x, y, v, a, b) {
    var g = 0;
    var k = max(x.length as int, y.length as int);
    if (eg_u.length != k) {
      eg_u = List.filled(k.toInt(), 0);
      eg_A = List.filled(k.toInt(), 0);
      eg_B = List.filled(k.toInt(), 0);
      eg_C = List.filled(k.toInt(), 0);
      eg_D = List.filled(k.toInt(), 0);
    }
    while (!trueIntVal(x[0] & 1) && !trueIntVal(y[0] & 1)) {
      //while x and y both even
      halve_(x);
      halve_(y);
      g++;
    }
    copy_(eg_u, x);
    copy_(v, y);
    copyInt_(eg_A, 1);
    copyInt_(eg_B, 0);
    copyInt_(eg_C, 0);
    copyInt_(eg_D, 1);
    for (;;) {
      while (!trueIntVal(eg_u[0] & 1)) {
        //while u is even
        halve_(eg_u);
        if (!trueIntVal(eg_A[0] & 1) && !trueIntVal(eg_B[0] & 1)) {
          //if A==B==0 mod 2
          halve_(eg_A);
          halve_(eg_B);
        } else {
          add_(eg_A, y);
          halve_(eg_A);
          sub_(eg_B, x);
          halve_(eg_B);
        }
      }

      while (!trueIntVal(v[0] & 1)) {
        //while v is even
        halve_(v);
        if (!trueIntVal(eg_C[0] & 1) && !trueIntVal(eg_D[0] & 1)) {
          //if C==D==0 mod 2
          halve_(eg_C);
          halve_(eg_D);
        } else {
          add_(eg_C, y);
          halve_(eg_C);
          sub_(eg_D, x);
          halve_(eg_D);
        }
      }

      if (!trueIntVal(greater(v, eg_u))) {
        //v<=u
        sub_(eg_u, v);
        sub_(eg_A, eg_C);
        sub_(eg_B, eg_D);
      } else {
        //v>u
        sub_(v, eg_u);
        sub_(eg_C, eg_A);
        sub_(eg_D, eg_B);
      }
      if (trueIntVal(equalsInt(eg_u, 0))) {
        while (trueIntVal(negative(eg_C))) {
          //make sure a (C) is nonnegative
          add_(eg_C, y);
          sub_(eg_D, x);
        }
        multInt_(eg_D, -1);

        ///make sure b (D) is nonnegative
        copy_(a, eg_C);
        copy_(b, eg_D);
        leftShift_(v, g);
        return;
      }
    }
  }

//is bigInt x negative?
  negative(x) {
    return ((x[x.length - 1] >> (bpe - 1)) & 1);
  }

//is (x << (shift*bpe)) > y?
//x and y are nonnegative bigInts
//shift is a nonnegative integer
  greaterShift(x, y, shift) {
    var i, kx = x.length, ky = y.length;
    var k = ((kx + shift) < ky) ? (kx + shift) : ky;
    for (i = ky - 1 - shift; i < kx && i >= 0; i++)
      if (x[i] > 0)
        return 1; //if there are nonzeros in x to the left of the first column of y, then x is bigger
    for (i = kx - 1 + shift; i < ky; i++)
      if (y[i] > 0)
        return 0; //if there are nonzeros in y to the left of the first column of x, then x is not bigger
    for (i = k - 1; i >= shift; i--)
      if (x[i - shift] > y[i])
        return 1;
      else if (x[i - shift] < y[i]) return 0;
    return 0;
  }

//is x > y? (x and y both nonnegative)
  greater(x, y) {
    var i;
    var k = (x.length < y.length) ? x.length : y.length;

    for (i = x.length; i < y.length; i++)
      if (trueIntVal(y[i])) return 0; //y has more digits

    for (i = y.length; i < x.length; i++)
      if (trueIntVal(x[i])) return 1; //x has more digits

    for (i = k - 1; i >= 0; i--)
      if (x[i] > y[i])
        return 1;
      else if (x[i] < y[i]) return 0;
    return 0;
  }

//divide x by y giving quotient q and remainder r.  (q=floor(x/y),  r=x mod y).  All 4 are bigints.
//x must have at least one leading zero element.
//y must be nonzero.
//q and r must be arrays that are exactly the same length as x. (Or q can have more).
//Must have x.length >= y.length >= 2.
// ignore: non_constant_identifier_names
  divide_(x, y, q, r) {
    var kx, ky;
    var i, y1, y2, c, a, b;
    copy_(r, x);
    for (ky = y.length;
        y[ky - 1] == 0;
        ky--) {} //ky is number of elements in y, not including leading zeros

    //normalize: ensure the most significant element of y has its highest bit set
    b = y[ky - 1];
    for (a = 0; trueIntVal(b); a++) b >>= 1;
    a = bpe -
        a; //a is how many bits to shift so that the high order bit of y is leftmost in its array element
    leftShift_(
        y, a); //multiply both by 1<<a now, then divide both by that at the end
    leftShift_(r, a);

    //Rob Visser discovered a bug: the following line was originally just before the normalization.
    for (kx = r.length;
        r[kx - 1] == 0 && kx > ky;
        kx--) {} //kx is number of elements in normalized x, not including leading zeros

    copyInt_(q, 0); // q=0
    while (!trueIntVal(greaterShift(y, r, kx - ky))) {
      // while (leftShift_(y,kx-ky) <= r) {
      subShift_(r, y, kx - ky); //   r=r-leftShift_(y,kx-ky)
      q[kx - ky]++; //   q[kx-ky]++;
    } // }

    for (i = kx - 1; i >= ky; i--) {
      if (r[i] == y[ky - 1])
        q[i - ky] = mask;
      else
        q[i - ky] = ((r[i] * radix + r[i - 1]) / y[ky - 1]).floor();

      //The following for(;;) loop is equivalent to the commented while loop,
      //except that the uncommented version avoids overflow.
      //The commented loop comes from HAC, which assumes r[-1]==y[-1]==0
      //  while (q[i-ky]*(y[ky-1]*radix+y[ky-2]) > r[i]*radix*radix+r[i-1]*radix+r[i-2])
      //    q[i-ky]--;
      for (;;) {
        y2 = (ky > 1 ? y[ky - 2] : 0) * q[i - ky];
        c = y2 >> bpe;
        y2 = y2 & mask;
        y1 = c + q[i - ky] * y[ky - 1];
        c = y1 >> bpe;
        y1 = y1 & mask;

        if (c == r[i]
            ? y1 == r[i - 1]
                ? y2 > (i > 1 ? r[i - 2] : 0)
                : y1 > r[i - 1]
            : c > r[i])
          q[i - ky]--;
        else
          break;
      }

      _linCombShift(r, y, -q[i - ky], i - ky); //r=r-q[i-ky]*leftShift_(y,i-ky)
      if (trueIntVal(negative(r))) {
        addShift_(r, y, i - ky); //r=r+leftShift_(y,i-ky)
        q[i - ky]--;
      }
    }

    rightShift_(y, a); //undo the normalization step
    rightShift_(r, a); //undo the normalization step
  }

//do carries and borrows so each element of the bigInt x fits in bpe bits.
// ignore: non_constant_identifier_names
  carry_(x) {
    var i, k, c, b;
    k = x.length;
    c = 0;
    for (i = 0; i < k; i++) {
      c += x[i];
      b = 0;
      if (c < 0) {
        b = -(c >> bpe);
        c += b * radix;
      }
      x[i] = c & mask;
      c = (c >> bpe) - b;
    }
  }

//return x mod n for bigInt x and integer n.
  modInt(x, n) {
    var i, c = 0;
    for (i = x.length - 1; i >= 0; i--) c = ((c * radix + x[i]) % n).toInt();
    return c;
  }

//convert the integer t into a bigInt with at least the given number of bits.
//the returned array stores the bigInt in bpe-bit chunks, little endian (buff[0] is least significant word)
//Pad the array with leading zeros so that it has at least minSize elements.
//There will always be at least one leading 0 element.
  int2bigInt(t, bits, minSize) {
    var k;
    k = (bits / bpe).ceil() + 1;
    k = minSize > k ? minSize : k;
    var buff = List.filled(k.toInt(), 0);
    copyInt_(buff, t);
    return buff;
  }

//return the bigInt given a string representation in a given base.
//Pad the array with leading zeros so that it has at least minSize elements.
//If base=-1, then it reads in a space-separated list of array elements in decimal.
//The array will always have at least one leading zero, unless base=-1.
  str2bigInt(s, b, minSize) {
    var d, i, base, str, x, y, kk;
    if (b is String) {
      base = b.length;
      str = b;
    } else {
      base = b;
      str = digitsStr;
    }
    var k = s.length;
    if (base == -1) {
      //comma-separated list of array elements in decimal
      x = List.empty();
      for (;;) {
        y = List.filled(x.length + 1, 0);
        for (i = 0; i < x.length; i++) y[i + 1] = x[i];
        y[0] = int.parse(s);
        x = y;
        d = s.indexOf(',', 0);
        if (d < 1) break;
        s = s.substring(d + 1);
        if (s.length == 0) break;
      }
      if (x.length < minSize) {
        y = List.filled(minSize, 0);
        copy_(y, x);
        return y;
      }
      return x;
    }

    x = int2bigInt(0, base * k, 0);
    for (i = 0; i < k; i++) {
      d = str.indexOf(s.substring(i, i + 1), 0);
      if (base <= 36 && d >= 36) {
        //convert lowercase to uppercase if base<=36
        d -= 26;
      }
      if (d >= base || d < 0) {
        //ignore illegal characters
        continue;
      }
      multInt_(x, base);
      addInt_(x, d);
    }

    for (k = x.length;
        k > 0 && !trueIntVal(x[k - 1]);
        k--) {} //strip off leading zeros
    k = minSize > k + 1 ? minSize : k + 1;
    y = List.filled(k, 0);
    kk = k < x.length ? k : x.length;
    for (i = 0; i < kk; i++) y[i] = x[i];
    for (; i < k; i++) y[i] = 0;
    return y;
  }

//is bigint x equal to integer y?
//y must have less than bpe bits
  equalsInt(x, y) {
    var i;
    if (x[0] != y) return 0;
    for (i = 1; i < x.length; i++) if (trueIntVal(x[i])) return 0;
    return 1;
  }

//are bigints x and y equal?
//this works even if x and y are different lengths and have arbitrarily many leading zeros
  equals(x, y) {
    var i;
    var k = x.length < y.length ? x.length : y.length;
    for (i = 0; i < k; i++) if (x[i] != y[i]) return 0;
    if (x.length > y.length) {
      for (; i < x.length; i++) if (trueIntVal(x[i])) return 0;
    } else {
      for (; i < y.length; i++) if (trueIntVal(y[i])) return 0;
    }
    return 1;
  }

//is the bigInt x equal to zero?
  isZero(x) {
    var i;
    for (i = 0; i < x.length; i++) if (trueIntVal(x[i])) return 0;
    return 1;
  }

//convert a bigInt into a string in a given base, from base 2 up to base 95.
//Base -1 prints the contents of the array representing the number.
  bigInt2str(x, b) {
    var i, t, base, str, s = "";
    if (b is String) {
      base = b.length;
      str = b;
    } else {
      base = b;
      str = digitsStr;
    }

    if (s6.length != x.length)
      s6 = dup(x);
    else
      copy_(s6, x);

    if (base == -1) {
      //return the list of array contents
      for (i = x.length - 1; i > 0; i--) s += x[i] + ',';
      s += x[0];
    } else {
      //return it in the given base
      while (!trueIntVal(isZero(s6))) {
        t = divInt_(s6, base); //t=s6 % base; s6=floor(s6/base);
        s = str.substring(t, t + 1) + s;
      }
    }
    if (s.isEmpty) s = str[0];
    return s;
  }

//returns a duplicate of bigInt x
  dup(x) {
    var buff = List.filled(x.length, 0);
    copy_(buff, x);
    return buff;
  }

//do x=y on bigInts x and y.  x must be an array at least as big as y (not counting the leading zeros in y).
// ignore: non_constant_identifier_names
  copy_(x, y) {
    var i;
    var k = x.length < y.length ? x.length : y.length;
    for (i = 0; i < k; i++) x[i] = y[i];
    for (i = k; i < x.length; i++) x[i] = 0;
  }

//do x=y on bigInt x and integer y.
// ignore: non_constant_identifier_names
  copyInt_(x, n) {
    var i = 0, c = n;
    for (; i < x.length; i++) {
      x[i] = c & mask;
      c >>= bpe;
    }
  }

//do x=x+n where x is a bigInt and n is an integer.
//x must be large enough to hold the result.
// ignore: non_constant_identifier_names
  addInt_(x, n) {
    var i, k, c, b;
    x[0] += n;
    k = x.length;
    c = 0;
    for (i = 0; i < k; i++) {
      c += x[i];
      b = 0;
      if (c < 0) {
        b = -(c >> bpe);
        c += b * radix;
      }
      x[i] = c & mask;
      c = (c >> bpe) - b;
      if (!trueIntVal(c)) return; //stop carrying as soon as the carry is zero
    }
  }

//right shift bigInt x by n bits.  0 <= n < bpe.
// ignore: non_constant_identifier_names
  rightShift_(x, n) {
    var i;
    var k = (n / bpe).floor();
    if (trueIntVal(k)) {
      for (i = 0; i < x.length - k; i++) //right shift x by k elements
        x[i] = x[i + k];
      for (; i < x.length; i++) x[i] = 0;
      n %= bpe;
    }
    for (i = 0; i < x.length - 1; i++) {
      x[i] = mask & ((x[i + 1] << (bpe - n)) | (x[i] >> n));
    }
    x[i] >>= n;
  }

//do x=floor(|x|/2)*sgn(x) for bigInt x in 2's complement
// ignore: non_constant_identifier_names
  halve_(x) {
    var i;
    for (i = 0; i < x.length - 1; i++) {
      x[i] = mask & ((x[i + 1] << (bpe - 1)) | (x[i] >> 1));
    }
    x[i] = (x[i] >> 1) |
        (x[i] & (radix >> 1)); //most significant bit stays the same
  }

//left shift bigInt x by n bits.
// ignore: non_constant_identifier_names
  leftShift_(x, n) {
    var i;
    var k = (n / bpe).floor();
    if (trueIntVal(k)) {
      for (i = x.length; i >= k; i--) //left shift x by k elements
        x[i] = x[i - k];
      for (; i >= 0; i--) x[i] = 0;
      n %= bpe;
    }
    if (!trueIntVal(n)) return;
    for (i = x.length - 1; i > 0; i--) {
      x[i] = mask & ((x[i] << n) | (x[i - 1] >> (bpe - n)));
    }
    x[i] = mask & (x[i] << n);
  }

//do x=x*n where x is a bigInt and n is an integer.
//x must be large enough to hold the result.
// ignore: non_constant_identifier_names
  multInt_(x, n) {
    var i, k, c, b;
    if (n == 0) return;
    k = x.length;
    c = 0;
    for (i = 0; i < k; i++) {
      c += x[i] * n;
      b = 0;
      if (c < 0) {
        b = -(c >> bpe);
        c += b * radix;
      }
      x[i] = c & mask;
      c = (c >> bpe) - b;
    }
  }

//do x=floor(x/n) for bigInt x and integer n, and return the remainder
// ignore: non_constant_identifier_names
  divInt_(x, n) {
    var i, r = 0, s;
    for (i = x.length - 1; i >= 0; i--) {
      s = r * radix + x[i];
      x[i] = (s / n).floor();
      r = s % n;
    }
    return r;
  }

//do the linear combination x=a*x+b*y for bigInts x and y, and integers a and b.
//x must be large enough to hold the answer.
// ignore: non_constant_identifier_names
  linComb_(x, y, a, b) {
    var i = 0, c = 0, k, kk;
    k = x.length < y.length ? x.length : y.length;
    kk = x.length;
    for (; i < k; i++) {
      c += (a * x[i] + b * y[i]) as int;
      x[i] = c & mask;
      c >>= bpe;
    }
    for (i = k; i < kk; i++) {
      c += (a * x[i]) as int;
      x[i] = c & mask;
      c >>= bpe;
    }
  }

//do the linear combination x=a*x+b*(y<<(ys*bpe)) for bigInts x and y, and integers a, b and ys.
//x must be large enough to hold the answer.
  _linCombShift(x, y, b, ys) {
    var i = ys, c = 0, k, kk;
    k = x.length < ys + y.length ? x.length : ys + y.length;
    kk = x.length;
    for (; i < k; i++) {
      c += (x[i] + b * y[i - ys]) as int;
      x[i] = c & mask;
      c >>= bpe;
    }
    for (i = k; c != 0 && i < kk; i++) {
      c += x[i] as int;
      x[i] = c & mask;
      c >>= bpe;
    }
  }

//do x=x+(y<<(ys*bpe)) for bigInts x and y, and integer ys.
//x must be large enough to hold the answer.
// ignore: non_constant_identifier_names
  addShift_(x, y, ys) {
    var i = ys, c = 0, k, kk;
    k = x.length < ys + y.length ? x.length : ys + y.length;
    kk = x.length;
    for (; i < k; i++) {
      c += (x[i] + y[i - ys]) as int;
      x[i] = c & mask;
      c >>= bpe;
    }
    for (i = k; c != 0 && i < kk; i++) {
      c += x[i] as int;
      x[i] = c & mask;
      c >>= bpe;
    }
  }

//do x=x-(y<<(ys*bpe)) for bigInts x and y, and integer ys.
//x must be large enough to hold the answer.
// ignore: non_constant_identifier_names
  subShift_(x, y, ys) {
    var i = ys, c = 0, k, kk;
    k = x.length < ys + y.length ? x.length : ys + y.length;
    kk = x.length;
    for (; i < k; i++) {
      c += (x[i] - y[i - ys]) as int;
      x[i] = c & mask;
      c >>= bpe;
    }
    for (i = k; c != 0 && i < kk; i++) {
      c += x[i] as int;
      x[i] = c & mask;
      c >>= bpe;
    }
  }

//do x=x-y for bigInts x and y.
//x must be large enough to hold the answer.
//negative answers will be 2s complement
// ignore: non_constant_identifier_names
  sub_(x, y) {
    var i = 0, c = 0, k;
    k = x.length < y.length ? x.length : y.length;
    for (; i < k; i++) {
      c += (x[i] - y[i]) as int;
      x[i] = c & mask;
      c >>= bpe;
    }
    for (i = k; c != 0 && i < x.length; i++) {
      c += x[i] as int;
      x[i] = c & mask;
      c >>= bpe;
    }
  }

//do x=x+y for bigInts x and y.
//x must be large enough to hold the answer.
// ignore: non_constant_identifier_names
  add_(x, y) {
    var i = 0, c = 0, k;
    k = x.length < y.length ? x.length : y.length;
    for (; i < k; i++) {
      c += (x[i] + y[i]) as int;
      x[i] = c & mask;
      c >>= bpe;
    }
    for (i = k; c != 0 && i < x.length; i++) {
      c += x[i] as int;
      x[i] = c & mask;
      c >>= bpe;
    }
  }

//do x=x*y for bigInts x and y.  This is faster when y<x.
// ignore: non_constant_identifier_names
  mult_(x, y) {
    var i;
    if (ss.length != 2 * x.length) ss = List.filled((2 * x.length).toInt(), 0);
    copyInt_(ss, 0);
    for (i = 0; i < y.length; i++)
      if (trueIntVal(y[i]))
        _linCombShift(ss, x, y[i], i); //ss=1*ss+y[i]*(x<<(i*bpe))
    copy_(x, ss);
  }

//do x=x mod n for bigInts x and n.
  _mod(x, n) {
    if (s4.length != x.length)
      s4 = dup(x);
    else
      copy_(s4, x);
    if (s5.length != x.length) s5 = dup(x);
    divide_(s4, n, s5, x); //x = remainder of s4 / n
  }

//do x=x*y mod n for bigInts x,y,n.
//for greater speed, let y<x.
// ignore: non_constant_identifier_names
  mult_mod(x, y, n) {
    var i;
    if (s0.length != 2 * x.length) s0 = List.filled((2 * x.length).toInt(), 0);
    copyInt_(s0, 0);
    for (i = 0; i < y.length; i++)
      if (trueIntVal(y[i]))
        _linCombShift(s0, x, y[i], i); //s0=1*s0+y[i]*(x<<(i*bpe))
    _mod(s0, n);
    copy_(x, s0);
  }

//do x=x*x mod n for bigInts x,n.
// ignore: non_constant_identifier_names
  square_mod(x, n) {
    var i, j, c, kx, k;
    for (kx = x.length;
        kx > 0 && !trueIntVal(x[kx - 1]);
        kx--) {} //ignore leading zeros in x
    k = kx > n.length
        ? 2 * kx
        : 2 *
            n.length; //k=# elements in the product, which is twice the elements in the larger of x and n
    if (s0.length != k) s0 = List.filled(k, 0);
    copyInt_(s0, 0);
    for (i = 0; i < kx; i++) {
      c = s0[2 * i as int] + x[i] * x[i];
      s0[2 * i as int] = c & mask;
      c >>= bpe;
      for (j = i + 1; j < kx; j++) {
        c = s0[i + j] + 2 * x[i] * x[j] + c;
        s0[i + j] = (c & mask);
        c >>= bpe;
      }
      s0[i + kx] = c;
    }
    _mod(s0, n);
    copy_(x, s0);
  }

//return x with exactly k leading zero elements
  trim(x, k) {
    var i, y;
    for (i = x.length; i > 0 && !trueIntVal(x[i - 1]); i--) {}
    y = List.filled(i + k, 0);
    copy_(y, x);
    return y;
  }

//do x=x**y mod n, where x,y,n are bigInts and ** is exponentiation.  0**0=1.
//this is faster when n is odd.  x usually needs to have as many elements as n.
// ignore: non_constant_identifier_names
  pow_mod(x, y, n) {
    var k1, k2, kn, np;
    if (s7.length != n.length) s7 = dup(n);

    //for even modulus, use a simple square-and-multiply algorithm,
    //rather than using the more complex Montgomery algorithm.
    if ((n[0] & 1) == 0) {
      copy_(s7, x);
      copyInt_(x, 1);
      while (!trueIntVal(equalsInt(y, 0))) {
        if (trueIntVal(y[0] & 1)) mult_mod(x, s7, n);
        divInt_(y, 2);
        square_mod(s7, n);
      }
      return;
    }

    //calculate np from n for the Montgomery multiplications
    copyInt_(s7, 0);
    for (kn = n.length; kn > 0 && !trueIntVal(n[kn - 1]); kn--) {}
    np = radix - inverseModInt(modInt(n, radix), radix);
    s7[kn] = 1;
    mult_mod(x, s7, n); // x = x * 2**(kn*bp) mod n

    if (s3.length != x.length)
      s3 = dup(x);
    else
      copy_(s3, x);

    for (k1 = y.length - 1;
        k1 > 0 && trueIntVal(k1 > 0 & (trueIntVal(y[k1]) ? 1 : 0));
        k1--) {} //k1=first nonzero element of y
    if (y[k1] == 0) {
      //anything to the 0th power is 1
      copyInt_(x, 1);
      return;
    }
    for (k2 = 1 << (bpe - 1);
        trueIntVal(k2) && !trueIntVal((y[k1] & k2));
        k2 >>= 1) {} //k2=position of first 1 bit in y[k1]
    for (;;) {
      if (!trueIntVal((k2 >>= 1))) {
        //look at next bit of y
        k1--;
        if (k1 < 0) {
          _mont(x, one, n, np);
          return;
        }
        k2 = 1 << (bpe - 1);
      }
      _mont(x, x, n, np);

      if (trueIntVal(k2 & y[k1])) //if next bit is a 1
        _mont(x, s3, n, np);
    }
  }

//do x=x*y*Ri mod n for bigInts x,y,n,
//  where Ri = 2**(-kn*bpe) mod n, and kn is the
//  number of elements in the n array, not
//  counting leading zeros.
//x array must have at least as many elemnts as the n array
//It's OK if x and y are the same variable.
//must have:
//  x,y < n
//  n is odd
//  np = -(n^(-1)) mod radix
  _mont(x, y, n, np) {
    var i, j, c, ui, t, ks;
    var kn = n.length;
    var ky = y.length;

    if (sa.length != kn) sa = List.filled(kn, 0);

    copyInt_(sa, 0);

    for (; kn > 0 && n[kn - 1] == 0; kn--) {} //ignore leading zeros of n
    for (; ky > 0 && y[ky - 1] == 0; ky--) {} //ignore leading zeros of y
    ks = sa.length -
        1; //sa will never have more than this many nonzero elements.

    //the following loop consumes 95% of the runtime for _randTruePrime() and pow_mod() for large numbers
    for (i = 0; i < kn; i++) {
      t = sa[0] + x[i] * y[0];
      ui = ((t & mask) * np) &
          mask; //the inner "& mask" was needed on Safari (but not MSIE) at one time
      c = (t + ui * n[0]) >> bpe;
      t = x[i];

      //do sa=(sa+x[i]*y+ui*n)/b   where b=2**bpe.  Loop is unrolled 5-fold for speed
      j = 1;
      for (; j < ky - 4;) {
        c += sa[j] + ui * n[j] + t * y[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
        c += sa[j] + ui * n[j] + t * y[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
        c += sa[j] + ui * n[j] + t * y[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
        c += sa[j] + ui * n[j] + t * y[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
        c += sa[j] + ui * n[j] + t * y[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
      }
      for (; j < ky;) {
        c += sa[j] + ui * n[j] + t * y[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
      }
      for (; j < kn - 4;) {
        c += sa[j] + ui * n[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
        c += sa[j] + ui * n[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
        c += sa[j] + ui * n[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
        c += sa[j] + ui * n[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
        c += sa[j] + ui * n[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
      }
      for (; j < kn;) {
        c += sa[j] + ui * n[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
      }
      for (; j < ks;) {
        c += sa[j];
        sa[j - 1] = c & mask;
        c >>= bpe;
        j++;
      }
      sa[j - 1] = c & mask;
    }

    if (!trueIntVal(greater(n, sa))) sub_(sa, n);
    copy_(x, sa);
  }
}
