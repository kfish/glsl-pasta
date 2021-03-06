module GLSLPasta
    exposing
        ( combine
        , combineUsingTemplate
        , defaultTemplate
        , empty
        )

{-|

@docs combine, combineUsingTemplate

@docs defaultTemplate

@docs empty

-}

import GLSLPasta.Core as Core
import GLSLPasta.Internal as Internal exposing (..)
import GLSLPasta.Types as Types exposing (..)


{-| Combine Components into the code for a Shader, that can be passed to WebGL.unsafeShader.
Errors are logged to the Javascript console.
-}
combine : ComponentId -> List Component -> String
combine parent components =
    combineUsingTemplate defaultTemplate parent components


{-| The default template used by combine
-}
defaultTemplate : Template
defaultTemplate =
    { id = "defaultTemplate"
    , globals = []
    , template = """
precision mediump float;

__PASTA_GLOBALS__

__PASTA_FUNCTIONS__

void main()
{
    __PASTA_SPLICES__
}
"""
    }


{-| Combine Components into the code for a Shader, that can be passed to WebGL.unsafeShader.
Errors are logged to the Javascript console.

The template is specified as a string containing placeholders `__PASTA_GLOBALS__`,
`__PASTA_FUNCTIONS__` and `__PASTA_SPLICES__`. For a concrete example, see the definition
of `defaultTemplate`.

-}
combineUsingTemplate : Template -> ComponentId -> List Component -> String
combineUsingTemplate template parent components =
    let
        result =
            Internal.combineWith template parent components
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


{-| An empty Component
-}
empty : Component
empty =
    Core.empty
