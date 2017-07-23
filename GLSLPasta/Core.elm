module GLSLPasta.Core exposing (..)

{-|

@docs empty

-}

import GLSLPasta.Types exposing (..)


{-| An empty Component
-}
empty : Component
empty =
    { id = "pasta.empty"
    , dependencies = none
    , provides = []
    , requires = []
    , globals = []
    , functions = []
    , splices = []
    }
