module GLSLPasta
    exposing
        ( combine
        , combineWith
        , defaultTemplate
        )

import GLSLPasta.Internal as Internal exposing (..)
import GLSLPasta.Types as Types exposing (..)


type alias PartId =
    Types.PartId


type alias Name =
    Types.Name


type alias Value =
    Types.Value


type alias Type =
    Types.Type


type alias Global =
    Types.Global


logErrors : List Error -> String
logErrors errors =
    let
        s =
            String.join "\n" (List.map errorString errors)
    in
        Tuple.second ( Debug.log s "<<GLSLPasta>>", "" )



-- | Combine Parts into the code for a Shader, that can be passed to WebGL.unsafeShader


combine : List Part -> String
combine parts =
    let
        result =
            combineWith defaultTemplate parts
    in
        case result of
            Ok s ->
                s

            Err errors ->
                logErrors errors


defaultTemplate : String
defaultTemplate =
    """
precision mediump float

__PASTA_GLOBALS__

__PASTA_FUNCTIONS__

void main()
{
    __PASTA_SPLICES__
}

    """


combineWith : String -> List Part -> Result (List Error) String
combineWith =
    Internal.combineWith
