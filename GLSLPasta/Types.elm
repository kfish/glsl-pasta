module GLSLPasta.Types exposing (..)


{-| GLSLPasta Types

# Types

@docs Error, Function, Global, Name, Part, PartId, Splice, Type, Value

-}


{-| An identifier for a Part
  Each Part is labelled with a PartId for use in error messages.
-}
type alias PartId =
    String

{-| The name of a global
 -}
type alias Name =
    String


{-| The value of a global constant
 -}
type alias Value =
    String


{-| The type of a global
 -}
type alias Type =
    String


{-| A Global
 -}
type Global
    = Attribute Type Name
    | Uniform Type Name
    | Varying Type Name
    | Const Type Name Value


{-| Text for a function
 -}
type alias Function =
    String


{-| Text to splice into main()
 -}
type alias Splice =
    String


{-| A Part
 -}
type alias Part =
    { id : PartId -- used in error messages
    , dependencies : List PartId
    , globals : List Global
    , functions : List Function
    , splices : List Splice
    }


{-| Errors returned during combine
 -}
type Error
    = GlobalConflict
        { what : String
        , newPartId : PartId
        , oldPartIds : List PartId
        , newGlobal : Global
        , oldGlobal : Global
        }
    | MissingDependency
        { newPartId : PartId
        , dependency : PartId
        }
