module GLSLPasta
    exposing
        ( combine
        , combineUsingTemplate
        , defaultTemplate
        )

{-|

@docs combine, combineUsingTemplate

@docs defaultTemplate

-}

import GLSLPasta.Internal as Internal exposing (..)
import GLSLPasta.Types as Types exposing (..)


{-| Combine Components into the code for a Shader, that can be passed to WebGL.unsafeShader.
Errors are logged to the Javascript console.
-}
combine : List Component -> String
combine components =
    combineUsingTemplate defaultTemplate components


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


{-| Combine Components into the code for a Shader, that can be passed to WebGL.unsafeShader.
Errors are logged to the Javascript console.

The template is specified as a string containing placeholders `__PASTA_GLOBALS__`,
`__PASTA_FUNCTIONS__` and `__PASTA_SPLICES__`. For a concrete example, see the definition
of `defaultTemplate`.

-}
combineUsingTemplate : String -> List Component -> String
combineUsingTemplate template components =
    let
        result =
            Internal.combineWith template components
    in
        case result of
            Ok s ->
                s

            Err errors ->
                logErrors errors


logErrors : List Error -> String
logErrors errors =
    let
        s =
            String.join "\n" (List.map errorString errors)
    in
        Tuple.second ( Debug.log s "<<GLSLPasta>>", "" )
