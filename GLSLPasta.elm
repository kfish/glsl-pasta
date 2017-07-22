module GLSLPasta
    exposing
        ( combine
        , combineWith
        , defaultTemplate
        )

{-| GLSLPasta

@docs combine, combineWith

@docs defaultTemplate

-}

import GLSLPasta.Internal as Internal exposing (..)
import GLSLPasta.Types as Types exposing (..)


logErrors : List Error -> String
logErrors errors =
    let
        s =
            String.join "\n" (List.map errorString errors)
    in
        Tuple.second ( Debug.log s "<<GLSLPasta>>", "" )



{-| Combine Components into the code for a Shader, that can be passed to WebGL.unsafeShader.
Errors are logged tot he Javascript console.
 -}
combine : List Component -> String
combine components =
    let
        result =
            combineWith defaultTemplate components
    in
        case result of
            Ok s ->
                s

            Err errors ->
                logErrors errors


{-| The default template used by combine
 -}
defaultTemplate : String
defaultTemplate =
    """
precision mediump float;

__PASTA_GLOBALS__

__PASTA_FUNCTIONS__

void main()
{
    __PASTA_SPLICES__
}

    """

{-| Combine using a given template
 -}
combineWith : String -> List Component -> Result (List Error) String
combineWith =
    Internal.combineWith
