pragma solidity ^0.5.2;

// Library for secp256r1, forked from https://github.com/tls-n/tlsnutils/blob/master/contracts/ECMath.sol
contract p256Lib {

    //curve parameters secp256r1
    uint256 constant A  = 115792089210356248762697446949407573530086143415290314195533631308867097853948;
    uint256 constant B  = 41058363725152142129326129780047268409114441015993725554835256314039467401291;
    uint256 constant GX = 48439561293906451759052585252797914202762949526041747995844080717082404635286;
    uint256 constant GY = 36134250956749795798585127919587881956611106672985015071877198253568414405109;
    uint256 constant P  = 115792089210356248762697446949407573530086143415290314195533631308867097853951;
    uint256 constant N  = 115792089210356248762697446949407573529996955224135760342422259061068512044369;
    uint256 constant H  = 1;


    function verify(uint256 e, uint256 r, uint256 s, uint256 qx, uint256 qy) public returns(bool) {
        uint256 w = invmod(s, N);
        
        (uint ret1, uint ret2, uint ret3) = assemblyShamir(mulmod(e, w, N), mulmod(r, w, N), qx, qy);

        uint256 zInv2 = modexp(ret3, P - 3, P);
        uint256 x = mulmod(ret1, zInv2, P); // JtoA(comb)[0];
        return r == x;
    }


    function recover(uint256 e, uint8 v, uint256 r, uint256 s) public returns(uint256[2] memory) {
        uint256 eInv = N - e;
        uint256 rInv = invmod(r, N);
        uint256 srInv = mulmod(rInv, s, N);
        uint256 eInvrInv = mulmod(rInv, eInv, N);

        uint256 ry = decompressPoint(r, v);
        (uint r0, uint r1, uint r2) = assemblyShamir(eInvrInv, srInv, r, ry);
        uint[3] memory q = [r0, r1, r2];
        return JtoA(q);
    }

    function assemblyShamir(uint256 u1, uint256 u2, uint256 qx, uint256 qy) internal pure returns(uint r0, uint r1, uint r2) {
      assembly{
        let z0, z1 , z2 := ecAdd(48439561293906451759052585252797914202762949526041747995844080717082404635286,36134250956749795798585127919587881956611106672985015071877198253568414405109,1,qx,qy,1)

        let mask :=  exp(2,255)
        {
          let compare := or(u1, u2)
          for {} eq(and(compare, mask), 0) {} {
              mask := div(mask, 2)
          }
        } //Scope because we don&#39;t need compare long term

        switch iszero(eq(and(u1, mask), 0))
        case 1 {
            switch iszero(eq(and(u2, mask), 0))
            case 1 {
                r0 := z0
                r1 := z1
                r2 := z2
            }
            default {
                r0 := 48439561293906451759052585252797914202762949526041747995844080717082404635286
                r1 := 36134250956749795798585127919587881956611106672985015071877198253568414405109
                r2 := 1
            }
        }
        default {
            r0 := qx
            r1 := qy
            r2 := 1
        }

        mask := div(mask, 2)
        for {} iszero(eq(mask, 0)) {mask := div(mask, 2)} {

            r0,r1,r2  := double(r0,r1,r2)

            switch iszero(eq(and(u1,mask), 0))
            case 1 {
                switch iszero(eq(and(u2,mask), 0))
                case 1 {
                  r0, r1, r2 := ecAdd(z0,z1,z2,r0,r1,r2)
                }
                default {
                  r0, r1, r2 := ecAdd(48439561293906451759052585252797914202762949526041747995844080717082404635286, 36134250956749795798585127919587881956611106672985015071877198253568414405109, 1, r0, r1, r2)
                }
            }
            default {
                if iszero(eq(and(u2, mask), 0)) {
                  r0, r1, r2 := ecAdd(qx, qy, 1, r0, r1, r2)
                }
            }
        }

        function ecAdd(_p0, _p1, _p2, _q0, _q1, _q2) -> _r0, _r1, _r2 {
          let _u2 := 0
          let _u1 := 0
          {
          let _z2 := mulmod(_q2,_q2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          _u1 := mulmod(_p0, _z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          let _s1 := mulmod(_p1, mulmod(_z2, _q2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          _z2 := mulmod(_p2, _p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          _u2 := mulmod(_q0, _z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          let _s2 := mulmod(_q1, mulmod(_z2, _p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)

          switch eq(_u1, _u2)
          case 1 {
            if iszero(eq(_s1, _s2)) {
              //Return Point at infinity
              _r0 := 1
              _r1 := 1
              _r2 := 0
            }
            if eq(_s1,_s2){
              //returns the double point
              _r0,_r1,_r2 := double(_p0, _p1, _p2)
            }
          }
          default {
            _u2 := addmod(_u2, sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, _u1), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            _z2 := mulmod(_u2, _u2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let _t2 := mulmod(_u1, _z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            _z2 := mulmod(_u2, _z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            _s2 := addmod(_s2, sub(115792089210356248762697446949407573530086143415290314195533631308867097853951 , _s1) , 115792089210356248762697446949407573530086143415290314195533631308867097853951)

            // Uses s2, t2, z2
            _r0 := addmod(addmod(mulmod(_s2, _s2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, _z2) , 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(2, _t2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951)

            //Uses s2, t2, r0, s1
            _r1 := addmod(mulmod(_s2, addmod(_t2, sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, _r0), 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(_s1, _z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            //Uses u2, p2, q2,
            /* r2 :=  mulmod(u2, mulmod(p2, q2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951) */
           }
          } //We have cleared the context block so cleared the stack and avoided the inaccessable stack error
          // assembly needs a command to delete local varibles so I can manualy clear the stack
          if iszero(eq(_u1, _u2)) { //If we don&#39;t check we will overwrite the other valid case
            _r2 :=  mulmod(_u2, mulmod(_p2, _q2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          }
        }

        function double(_p0, _p1, _p2) -> _r0, _r1, _r2 {
          if eq(_p1, 0) {
              _r0 := 0x1
              _r1 := 0x1
              _r2 := 0x0
          }
          let _z2 := mulmod(_p2, _p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          let _m := addmod(mulmod(115792089210356248762697446949407573530086143415290314195533631308867097853948, mulmod(_z2, _z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), mulmod(3, mulmod(_p0, _p0, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          let _y2 := mulmod(_p1, _p1, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          let _s := mulmod(4, mulmod(_p0, _y2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)

          _r0 := addmod(mulmod(_m, _m, 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub( 115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(_s, 2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          _r2 := mulmod(2, mulmod(_p1, _p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          _r1 := addmod( mulmod(_m, addmod(_s, sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, _r0), 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(8,mulmod(_y2, _y2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
        }
      }
    }

    function getSqrY(uint256 x) private pure returns(uint256) {
        //return y^2=x^3+Ax+B
        return addmod(mulmod(x, mulmod(x, x, P), P), addmod(mulmod(A, x, P), B, P), P);
    }


    //function checks if point (x, y) is on curve, x and y affine coordinate parameters
    function isPoint(uint256 x, uint256 y) public pure returns(bool) {
        //point fulfills y^2=x^3+Ax+B?
        return mulmod(y, y, P) == getSqrY(x);
    }


    function decompressPoint(uint256 x, uint8 yBit) private returns(uint256) {
        //return sqrt(x^3+Ax+B)
        uint256 absy = modexp(getSqrY(x), 1+(P-3)/4, P);
        return yBit == 0 ? absy : -absy;
    }

    function assemblyAdd(uint[3] memory _p, uint256[3] memory _q) private pure returns(uint256[3] memory r){

      assembly{
          let p_0 := mload(_p)
          let p_1 := mload(add(_p, 0x20))
          let p_2 := mload(add(_p, 0x40))
          let q_0 := mload(_q)
          let q_1 := mload(add(_q, 0x20))
          let q_2 := mload(add(_q, 0x40))

          ecAdd(p_0, p_1, p_2, q_0, q_1, q_2, r)

          function ecAdd(p0, p1, p2, q0, q1, q2, _r) {
            let z2 := mulmod(q2,q2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let u1 := mulmod(p0, z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let s1 := mulmod(p1, mulmod(z2, q2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            z2 := mulmod(p2, p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let u2 := mulmod(q0, z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let s2 := mulmod(q1, mulmod(z2, p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)

            if eq(u1, u2) {
              if iszero(eq(s1, s2)) {
                //Return Point at infinity
                mstore(_r, 0x1)
                mstore(add(_r,0x20), 0x1)
                mstore(add(_r,0x40), 0x0)
              }
              if eq(s1,s2){
                {let x,y,z := double(p0, p1, p2)}
              }
            }

            u2 := addmod(u2, sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, u1), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            z2 := mulmod(u2, u2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let t2 := mulmod(u1, z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            z2 := mulmod(u2, z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            s2 := addmod(s2, sub(115792089210356248762697446949407573530086143415290314195533631308867097853951 ,s1) , 115792089210356248762697446949407573530086143415290314195533631308867097853951)

            let r0 := addmod(addmod(mulmod(s2, s2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, z2) , 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(2, t2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            mstore(_r, r0)
            mstore(add(_r,0x20), addmod(mulmod(s2, addmod(t2, sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, r0), 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(s1, z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951))
            mstore(add(_r,0x40), mulmod(u2, mulmod(p2, q2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951))
          }

          function double(p0, p1, p2) -> r0,r1,r2 {

            if eq(p1, 0) {
                r0 := 0x1
                r1 := 0x1
                r2 := 0x0
            }
            let P := 115792089210356248762697446949407573530086143415290314195533631308867097853951
            let A := 115792089210356248762697446949407573530086143415290314195533631308867097853948
            let z2 := mulmod(p2, p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let m := addmod(mulmod(115792089210356248762697446949407573530086143415290314195533631308867097853948, mulmod(z2, z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), mulmod(3, mulmod(p0, p0, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let y2 := mulmod(p1, p1, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let s := mulmod(4, mulmod(p0, y2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)

            r0 := addmod(mulmod(m,m, 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub( 115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(s, 2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            r2 := mulmod(2, mulmod(p1, p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            r1 := addmod( mulmod(m, addmod(s, sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, r0), 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(8,mulmod(y2, y2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
          }
        }
    }

    function assemblyDouble(uint[3] memory _p) private pure returns(uint[3] memory _r) {
        assembly{
            let p0 := mload(add(_p, 0x00))
            let p1 := mload(add(_p, 0x20))
            let p2 := mload(add(_p, 0x40))

            if eq(p1, 0) {
                mstore(add(_r,0x00), 0x1)
                mstore(add(_r,0x20), 0x1)
                mstore(add(_r,0x40), 0x0)
            }

            let P := 115792089210356248762697446949407573530086143415290314195533631308867097853951
            let A := 115792089210356248762697446949407573530086143415290314195533631308867097853948
            let z2 := mulmod(p2, p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let m := addmod(mulmod(115792089210356248762697446949407573530086143415290314195533631308867097853948, mulmod(z2, z2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), mulmod(3, mulmod(p0, p0, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let y2 := mulmod(p1, p1, 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let s := mulmod(4, mulmod(p0, y2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)

            let r0 := addmod(mulmod(m,m, 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub( 115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(s, 2, 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let r2 := mulmod(2, mulmod(p1, p2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)
            let r1 := addmod( mulmod(m, addmod(s, sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, r0), 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951), sub(115792089210356248762697446949407573530086143415290314195533631308867097853951, mulmod(8,mulmod(y2, y2, 115792089210356248762697446949407573530086143415290314195533631308867097853951), 115792089210356248762697446949407573530086143415290314195533631308867097853951)), 115792089210356248762697446949407573530086143415290314195533631308867097853951)

            mstore(add(_r,0x00), r0)
            mstore(add(_r,0x20), r1)
            mstore(add(_r,0x40), r2)
        }
    }


    //jacobian to affine coordinates transformation
    function JtoA(uint256[3] memory p) private returns(uint256[2] memory Pnew) {
        uint zInv = invmod(p[2], P);
        uint zInv2 = mulmod(zInv, zInv, P);
        Pnew[0] = mulmod(p[0], zInv2, P);
        Pnew[1] = mulmod(p[1], mulmod(zInv, zInv2, P), P);
    }


    //computing inverse by using fermat&#39;s theorem
    function invmod(uint256 _a, uint _p) internal returns(uint256 invA) {
        invA = modexp(_a, _p - 2, _p);
    }
    
    function modexp(uint256 b, uint256 e, uint256 m) internal returns(uint256 result) {
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), b)
            mstore(add(freemem,0x80), e)
            mstore(add(freemem,0xA0), m)
            // gas = 32^3 / G_quanddivsior = 327.68
            let _ := call(gas, 0x0000000000000000000000000000000000000005, 0, freemem, 0xB0, freemem, 0x20)
            result := mload(freemem)
        }
    }
    //@ Dev - The orginal code which was assemblifed
    /* //We lay out memory starting at zero 32 bytes public key X 32 bytes public
    function calcPointShamir(uint256 u1, uint256 u2, uint256 qx, uint256 qy) private pure returns(uint[3] memory R) {
        uint256[3] memory G = [GX, GY, 1];
        uint256[3] memory Q = [qx, qy, 1];
        uint256[3] memory Z = assemblyAdd(Q, G);

        uint256 mask = 2**255;

        // Skip leading zero bits
        uint256 or = u1 | u2;
        while (or & mask == 0) {
            mask = mask / 2;
        }

        // Initialize output
        if (u1 & mask != 0) {
            if (u2 & mask != 0) {
                R = Z;
            }
            else {
                R = G;
            }
        }
        else {
            R = Q;
        }

        while (true) {

            mask = mask / 2;
            if (mask == 0) {
                break;
            }

            R = ecdouble(R);

            if (u1 & mask != 0) {
                if (u2 & mask != 0) {
                    R = ecadd(Z, R);
                }
                else {
                    R = ecadd(G, R);
                }
            }
            else {
                if (u2 & mask != 0) {
                    R = ecadd(Q, R);
                }
            }
        }
    }
    // point addition for elliptic curve in jacobian coordinates
    // formula from https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates
    function ecadd(uint256[3] memory _p, uint256[3] memory _q) private pure returns(uint256[3] memory R) {

        // if (_q[0] == 0 && _q[1] == 0 && _q[2] == 0) {
        // 	return _p;
        // }

        uint256 z2 = mulmod(_q[2], _q[2], P);
        uint256 u1 = mulmod(_p[0], z2, P);
        uint256 s1 = mulmod(_p[1], mulmod(z2, _q[2], P), P);
        z2 = mulmod(_p[2], _p[2], P);
        uint256 u2 = mulmod(_q[0], z2, P);
        uint256 s2 = mulmod(_q[1], mulmod(z2, _p[2], P), P);

        if (u1 == u2) {
            if (s1 != s2) {
                //return point at infinity
                return [uint256(1), 1, 0];
            }
            else {
                return ecdouble(_p);
            }
        }

        u2 = addmod(u2, P - u1, P);
        z2 = mulmod(u2, u2, P);
        uint256 t2 = mulmod(u1, z2, P);
        z2 = mulmod(u2, z2, P);
        s2 = addmod(s2, P - s1, P);
        R[0] = addmod(addmod(mulmod(s2, s2, P), P - z2, P), P - mulmod(2, t2, P), P);
        R[1] = addmod(mulmod(s2, addmod(t2, P - R[0], P), P), P - mulmod(s1, z2, P), P);
        R[2] = mulmod(u2, mulmod(_p[2], _q[2], P), P);
    }
    //point doubling for elliptic curve in jacobian coordinates
    //formula from https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates
    function ecdouble(uint256[3] memory _p) private pure returns(uint256[3] memory R) {

        if (_p[1] == 0) {
            //return point at infinity
            return [uint256(1), 1, 0];
        }

        uint256 z2 = mulmod(_p[2], _p[2], P);
        uint256 m = addmod(mulmod(A, mulmod(z2, z2, P), P), mulmod(3, mulmod(_p[0], _p[0], P), P), P);
        uint256 y2 = mulmod(_p[1], _p[1], P);
        uint256 s = mulmod(4, mulmod(_p[0], y2, P), P);

        R[0] = addmod(mulmod(m, m, P), P - mulmod(s, 2, P), P);
        R[2] = mulmod(2, mulmod(_p[1], _p[2], P), P);	// consider R might alias _p
        R[1] = addmod(mulmod(m, addmod(s, P - R[0], P), P), P - mulmod(8, mulmod(y2, y2, P), P), P);
    }*/
}