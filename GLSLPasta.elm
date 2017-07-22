module GLSLPasta
    exposing
        ( combine
        , combineWith
        , defaultTemplate
        )

import GLSLPasta.Internal as Internal exposing (..)
import GLSLPasta.Types as Types exposing (..)


{-

   This library makes no pretense about being correct. It is not a GLSL parser, simply
   a lexical templating mechanism.

   That said, it will at least allow for multiple components operating on the same globals.
   You define a part of a shader with type Part

       type alias Part =
           { id : PartId -- used in error messages
           , dependencies = List PartId
           , globals : List Global
           , functions : List Function
           , splices : List Splice
           }

   and combine parts together using the function:

       combine : List Part -> String

   the output of which you can pass to WebGL.unsafeShader.


   How it works

   This simply templates. The default template is:

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

   Here, __PASTA_GLOBALS__ is replaced with a all the globals from all the parts (with duplicates removed),
   __PASTA_FUNCTIONS__ is replaced with all the functions from all the parts,
   and __PASTA_SPLICES__ is replaced with all the splices from all the parts, in the order the list of parts.

   Note that the functions and splices are replaced as arbitrary strings, and glsl-pasta makes no
   attempt to parse or sanity-check these.

-}


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
