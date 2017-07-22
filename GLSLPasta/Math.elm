module GLSLPasta.Math exposing (..)


{-| Math parts

@docs transposeMat3
-}

import GLSLPasta.Core exposing (empty)
import GLSLPasta.Types exposing (..)


{-| mat3 transpose
 -}
transposeMat3 : Part
transposeMat3 =
    { empty | id = "math.transposeMat3"
            , functions =
                [ """
mat3 transpose(mat3 m) {
    return mat3(m[0][0], m[1][0], m[2][0],
                m[0][1], m[1][1], m[2][1],
                m[0][2], m[1][2], m[2][2]);
}
"""
                ]
    }
    

