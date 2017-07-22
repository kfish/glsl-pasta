module GLSLPasta.Core exposing (..)


{-| Core parts

@docs empty
-}

import GLSLPasta.Types exposing (..)


{-| An empty Part
 -}
empty : Part
empty =
    { id = "pasta.empty"
    , dependencies = none
    , provides = []
    , requires = []
    , globals = []
    , functions = []
    , splices = []
    }

