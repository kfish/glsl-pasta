module GLSLPasta.Types exposing (..)

{-|

# Types

@docs Feature, Error, Function, Global, Name, Component, ComponentId, Splice, Type, Value, Template

@docs Dependencies, none

-}


{-| An identifier for a Component
Each Component is labelled with a ComponentId for use in error messages.
-}
type alias ComponentId =
    String


{-| An abstract feature provided by a Component, often the name of a
variable.

For example, a shader that initially sets gl_FragColor might specify

    provides =
        [ "gl_FragColor" ]

and another shader that modifies gl_FragColor might specify

    requires =
        [ "gl_FragColor" ]

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


{-| A Component
-}
type alias Component =
    { id : ComponentId -- used in error messages
    , dependencies : Dependencies
    , provides : List Feature
    , requires : List Feature
    , globals : List Global
    , functions : List Function
    , splices : List Splice
    }


{-| Dependencies
-}
type Dependencies
    = Dependencies (List Component)


{-| Shorthand for no dependencies
-}
none : Dependencies
none =
    Dependencies []


{-| A Template
-}
type alias Template =
    { id : ComponentId
    , globals : List Global
    , template : String
    }


{-| Errors returned during combine
-}
type Error
    = GlobalConflict
        { what : String
        , parentComponentId : ComponentId
        , newComponentId : ComponentId
        , oldComponentIds : List ComponentId
        , newGlobal : Global
        , oldGlobal : Global
        }
    | MissingRequirement
        { parentComponentId : ComponentId
        , componentId : ComponentId
        , requirement : Feature
        }
