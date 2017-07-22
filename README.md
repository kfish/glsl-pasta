# glsl-pasta

This is a crude way of combining GLSL shaders for use with Elm
[webgl](http://package.elm-lang.org/packages/elm-community/elm-webgl/latest/WebGL)..

This library makes no pretense about being correct. It is not a GLSL parser, simply
a lexical templating mechanism.

That said, it will at least allow for multiple components operating on the same globals.
You define a part of a shader with type Part

```elm
   type alias Part =
       { id : PartId -- used in error messages
       , dependencies = List PartId
       , globals : List Global
       , functions : List Function
       , splices : List Splice
       }
```

and combine parts together using the function:

```elm
   combine : List Part -> String
```

the output of which you can pass to `WebGL.unsafeShader`.


## How it works

This simply templates. The default template is:

```elm
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
```

Here, `__PASTA_GLOBALS__` is replaced with a all the globals from all the parts (with duplicates removed),
`__PASTA_FUNCTIONS__` is replaced with all the functions from all the parts,
and `__PASTA_SPLICES__` is replaced with all the splices from all the parts, in the order the list of parts.

Note that the functions and splices are replaced as arbitrary strings, and glsl-pasta makes no
attempt to parse or sanity-check these.

