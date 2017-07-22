module GLSLPasta.Lighting exposing (..)

{-| Basic lighting

# Vertex shaders
@docs vertexPosition, vertexReflection

# Fragment shaders
@docs fragmentReflection
-}

import GLSLPasta exposing (..)
import GLSLPasta.Types exposing (..)


{-| Generates gl_Position
 -}
vertexPosition : Part
vertexPosition =
    { id = "lighting.vertexPosition"
    , dependencies = []
    , globals =
        [ Attribute "vec3" "position"
        , Uniform "mat4" "camera"
        , Uniform "mat4" "mvMat"
        ]
    , functions = []
    , splices =
        [ """
            vec4 vertex4 = mvMat * vec4(position, 1.0);
            gl_Position = camera * vertex4;
            """
        ]
    }


{-| This shader uses Spherical Environment Mapping (SEM).
Here are some relevant links:
* [very cool demo](https://www.clicktorelease.com/code/spherical-normal-mapping/#)
* <https://www.clicktorelease.com/blog/creating-spherical-environment-mapping-shader>
* <http://www.ozone3d.net/tutorials/glsl_texturing_p04.php>

Generates vNormal
-}
vertexReflection : Part
vertexReflection =
    { id = "lighting.vertexReflection"
    , dependencies = [ "lighting.vertexPosition" ]
    , globals =
        [ Attribute "vec3" "normal"
        , Uniform "mat4" "mvMat"
        , Varying "vec3" "vNormal"
        ]
    , functions = []
    , splices =
        [ """
            vNormal = vec3(mvMat * vec4(normal, 0.0));
            vec3 nm_z = normalize(vec3(vertex4));
            vec3 nm_x = cross(nm_z, vec3(0.0, 1.0, 0.0));
            vec3 nm_y = cross(nm_x, nm_z);
            vNormal = vec3(dot(vNormal, nm_x), dot(vNormal, nm_y), dot(vNormal, nm_z));
            """
        ]
    }


{-| This shader uses Spherical Environment Mapping (SEM).
Here are some relevant links:
* [very cool demo](https://www.clicktorelease.com/code/spherical-normal-mapping/#)
* <https://www.clicktorelease.com/blog/creating-spherical-environment-mapping-shader>
* <http://www.ozone3d.net/tutorials/glsl_texturing_p04.php>
-}
fragmentReflection : Part
fragmentReflection =
    { id = "lighting.fragmentReflection"
    , dependencies = []
    , globals =
        [ Uniform "sampler2D" "texture"
        , Varying "vec3" "vNormal"
        ]
    , functions = []
    , splices =
        [ """
            vec2 texCoord = vec2(0.5 * vNormal.x + 0.5, - 0.5 * vNormal.y - 0.5);
            vec4 fragColor = texture2D(texture, texCoord);
            fragColor.a = 1.0;

            gl_FragColor = fragColor;
            """
        ]
    }
