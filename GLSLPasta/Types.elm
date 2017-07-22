module GLSLPasta.Types exposing (..)


-- Each Part is labelled with a PartId for use in error messages.
type alias PartId = String

type alias Name = String

type alias Value = String

type alias Type = String

type Global
    = Attribute Type Name
    | Uniform Type Name
    | Varying Type Name
    | Const Type Name Value

type alias Function = String

-- if this is problematic, we could considder tracking the vars each splice affects, and
-- sorting in dependency order (rather than just whatever order the Parts are given)
type alias Splice = String


type alias Part =
    { id : PartId -- used in error messages
    , dependencies : List PartId
    , globals : List Global
    , functions : List Function
    , splices : List Splice
    }

type Error
    = GlobalConflict
        { what : String
        , newPartId : PartId
        , oldPartIds : List PartId
        , newGlobal : Global
        , oldGlobal : Global
        }

