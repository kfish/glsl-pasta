module GLSLPasta.Types exposing (..)


{-| GLSLPasta Types

# Types

@docs Feature, Error, Function, Global, Name, Part, PartId, Splice, Type, Value

@docs Dependencies, none

-}


{-| An identifier for a Part
  Each Part is labelled with a PartId for use in error messages.
-}
type alias PartId =
    String

{-| An abstract feature provided by a Part, often the name of a
variable.

For example, a shader that initially sets gl_FragColor might specify

    provides = [ "gl_FragColor" ]

and another shader that modifies gl_FragColor might specify

    requires = [ "gl_FragColor" ]

-}
type alias Feature =
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
    , dependencies : Dependencies
    , provides : List Feature
    , requires : List Feature
    , globals : List Global
    , functions : List Function
    , splices : List Splice
    }

{-| Dependencies
-}
type Dependencies =
    Dependencies (List Part)

{-| Shorthand for no dependencies
-}
none : Dependencies
none = Dependencies []

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
    | MissingRequirement
        { partId : PartId
        , requirement : Feature
        }
