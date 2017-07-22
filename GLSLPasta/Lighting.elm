module GLSLPasta.Lighting exposing (..)

import GLSLPasta exposing (..)
import GLSLPasta.Types exposing (..)

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
        [
            """
            vec4 vertex4 = mvMat * vec4(position, 1.0);
            gl_Position = camera * vertex4;
            """
        ]
    }


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
        [
            """
            vNormal = vec3(mvMat * vec4(normal, 0.0));
            vec3 nm_z = normalize(vec3(vertex4));
            vec3 nm_x = cross(nm_z, vec3(0.0, 1.0, 0.0));
            vec3 nm_y = cross(nm_x, nm_z);
            vNormal = vec3(dot(vNormal, nm_x), dot(vNormal, nm_y), dot(vNormal, nm_z));
            """
        ]
    }
