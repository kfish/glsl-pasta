module GLSLPasta.Core exposing (..)


{-| Core components

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

