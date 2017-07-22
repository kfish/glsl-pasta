module GLSLPasta.Lighting exposing (..)

{-| Basic lighting

# Complete vertex shaders
@docs vertexReflection, vertexNormal, vertexNoNormal, vertexSimple

# Vertex shader components
@docs vertex_position4, vertex_gl_Position, vertex_vTexCoord, vertex_SphericalEnvironmentMapping, vertexTBN, vertexNoTangent

# Complete fragment shaders
@docs fragmentReflection, fragmentNormal, fragmentNoNormal, fragmentSimple

# Fragment shader components
@docs fragment_lightDir, fragment_textureNormal, fragment_interpolatedNormal, fragment_lambert

@docs vertex_clipPosition, lightenDistance
-}

import GLSLPasta.Core exposing (..)
import GLSLPasta.Math exposing (transposeMat3)
import GLSLPasta.Types exposing (..)


{-| Generates position4
 -}
vertex_position4 : Component
vertex_position4 =
    { empty
        | id = "lighting.vertex_position4"
    , provides =
        [ "position4"
        ]
    , globals =
        [ Attribute "vec3" "position"
        ]
    , splices =
        [ """
            vec4 position4 = vec4(position, 1.0);
            """
        ]
    }


{-| Generates gl_Position
 -}
vertex_gl_Position : Component
vertex_gl_Position =
    { empty
        | id = "lighting.vertex_gl_Position"
        , dependencies =
            Dependencies
                [ vertex_position4
                ]
        , provides =
            [ "gl_Position"
            ]
        , globals =
            [ Uniform "mat4" "modelViewProjectionMatrix"
            ]
        , splices =
            [ """
            gl_Position = modelViewProjectionMatrix * position4;
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
vertex_SphericalEnvironmentMapping : Component
vertex_SphericalEnvironmentMapping =
    { id = "lighting.vertex_SphericalEnvironmentMapping"
    , dependencies =
        Dependencies
            [ vertex_position4
            ]
    , provides = [ "vNormal" ]
    , requires = []
    , globals =
        [ Attribute "vec3" "normal"
        , Uniform "mat4" "mvMat"
        , Varying "vec3" "vNormal"
        ]
    , functions = []
    , splices =
        [ """
            vNormal = vec3(mvMat * vec4(normal, 0.0));
            vec3 nm_z = normalize(vec3(position4));
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
vertexReflection : Component
vertexReflection =
    { empty
        | id = "lighting.vertexReflection"
        , dependencies =
            Dependencies
                [ vertex_gl_Position
                , vertex_SphericalEnvironmentMapping
                ]
    }


{-| This shader uses Spherical Environment Mapping (SEM).
Here are some relevant links:
* [very cool demo](https://www.clicktorelease.com/code/spherical-normal-mapping/#)
* <https://www.clicktorelease.com/blog/creating-spherical-environment-mapping-shader>
* <http://www.ozone3d.net/tutorials/glsl_texturing_p04.php>
-}
fragmentReflection : Component
fragmentReflection =
    { id = "lighting.fragmentReflection"
    , dependencies = none
    , provides = [ "gl_FragColor" ]
    , requires = []
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


{-| Forward the texture coordinate to the fragment shader, as vTexCoord
-}
vertex_vTexCoord : Component
vertex_vTexCoord =
    { id = "lighting.worldPosition"
    , dependencies = none
    , provides = []
    , requires = []
    , globals =
        [ Attribute "vec2" "texCoord"
        , Varying "vec2" "vTexCoord"
        ]
    , functions = []
    , splices =
        [ """
            vTexCoord = texCoord;
            """
        ]
    }


{-| normal mapping according to:
<http://www.gamasutra.com/blogs/RobertBasler/20131122/205462/Three_Normal_Mapping_Techniques_Explained_For_the_Mathematically_Uninclined.php?print=1>
-}
vertexTBN : Component
vertexTBN =
    { empty
        | id = "lighting.vertexTBN"
        , dependencies =
            Dependencies
                [ vertex_position4
                , transposeMat3
                ]
        , provides =
                [ "vLightDirection"
                , "vViewDirection" 
                ]
        , globals =
            [ Attribute "vec3" "normal"
            , Attribute "vec4" "tangent"
            , Varying "vec3" "vLightDirection"
            , Varying "vec3" "vViewDirection"
            , Uniform "mat4" "modelMatrix"
            , Uniform "vec3" "lightPosition"
            , Uniform "vec3" "viewPosition"
            ]
        , splices =
            [ """
            vec3 posWorld = (modelMatrix * position4).xyz;

            // Tangent, Bitangent, Normal space matrix TBN
            // this isn't entirely correct, it should use the normal matrix
            // http://www.lighthouse3d.com/tutorials/glsl-12-tutorial/the-normal-matrix/
            vec3 n = normalize((modelMatrix * vec4(normal, 0.0)).xyz);
            vec3 t = normalize((modelMatrix * vec4(tangent.xyz, 0.0)).xyz);
            vec3 b = normalize((modelMatrix * vec4((cross(normal, tangent.xyz) * tangent.w), 0.0)).xyz);
            mat3 tbn = transpose(mat3(t, b, n));
            vLightDirection = tbn*(lightPosition - posWorld);
            vViewDirection = tbn*(viewPosition - posWorld);
"""
            ]
    }


{-| normal mapping according to:
<http://www.gamasutra.com/blogs/RobertBasler/20131122/205462/Three_Normal_Mapping_Techniques_Explained_For_the_Mathematically_Uninclined.php?print=1>
-}
vertexNormal : Component
vertexNormal =
    { empty
        | id = "lighting.vertexNormal"
        , dependencies =
            Dependencies
                [ vertex_gl_Position
                , vertex_vTexCoord
                , vertexTBN
                ]
    }


{-| Forward the position in clip space (ie. gl_Position) to the fragment shader, as clipPosition
-}
vertex_clipPosition : Component
vertex_clipPosition =
    { empty
        | id = "lighting.vertex_clipPosition"
        , requires = [ "gl_Position" ]
        , globals =
            [ Varying "vec4" "clipPosition"
            ]
        , splices =
            [ """
            clipPosition = gl_Position;
"""
            ]
    }


{-| Red-shift, and lighten far objects
-}
lightenDistance : Component
lightenDistance =
    { empty
        | id = "lighting.lightenDistance"
        , requires = [ "gl_FragColor" ]
        , globals =
            [ Varying "vec4" "clipPosition"
            ] 
        , splices =
            [ """
            float lightenDistance = clipPosition.w * 0.01;
            gl_FragColor *= 1.0 - lightenDistance * vec4(0.18, 0.21, 0.24, 0.15);
"""
            ]
    }


{-| Provides lightDir
 -}
fragment_lightDir : Component
fragment_lightDir =
    { empty
        | id = "lighting.fragment_lightDir"
        , provides = [ "lightDir" ]
        , globals =
            [ Varying "vec3" "vLightDirection"
            ] 
        , splices =
            [ """
            vec3 lightDir = normalize(vLightDirection);
"""
            ]
    }

{-| Provides pixelNormal given by an input normal texture
 -}
fragment_textureNormal : Component
fragment_textureNormal =
    { empty
        | id = "lighting.fragment_textureNormal"
        , provides = [ "pixelNormal" ]
        , globals =
            [ Uniform "sampler2D" "textureNorm"
            , Varying "vec2" "vTexCoord"
            ] 
        , splices =
            [ """
            // Local normal, in tangent space
            vec3 pixelNormal = normalize(texture2D(textureNorm, vTexCoord).rgb*2.0 - 1.0);
"""
            ]
    }


{-| Provides pixelNormal by interpolating vertex normals
 -}
fragment_interpolatedNormal : Component
fragment_interpolatedNormal =
    { empty
        | id = "lighting.fragment_interpolatedNormal"
        , provides = [ "pixelNormal" ]
        , globals =
            [ Varying "vec3" "vNormal"
            ] 
        , splices =
            [ """
            vec3 pixelNormal = normalize(vNormal);
"""
            ]
    }


{-| Provides lambert, given some pixelNormal
 -}
fragment_lambert : Component
fragment_lambert =
    { empty
        | id = "lighting.fragment_lambert"
        , dependencies =
            Dependencies
                [ fragment_lightDir
                ]
        , provides = [ "lambert" ]
        , requires = [ "pixelNormal" ]
        , globals = []
        , splices =
            [ """
            float lambert = max(dot(pixelNormal, lightDir), 0.0);
"""
            ]
    }


{-| normal mapping according to:
<http://www.gamasutra.com/blogs/RobertBasler/20131122/205462/Three_Normal_Mapping_Techniques_Explained_For_the_Mathematically_Uninclined.php?print=1>
-}
fragmentNormal : Component
fragmentNormal =
    { id = "lighting.fragmentNormal"
    , dependencies =
        Dependencies
            [ fragment_lightDir
            , fragment_textureNormal
            , fragment_lambert
            ]
    , provides = [ "gl_FragColor" ]
    , requires = []
    , globals =
         [ Uniform "sampler2D" "textureDiff"
         , Varying "vec2" "vTexCoord"
         , Varying "vec3" "vLightDirection"
         , Varying "vec3" "vViewDirection"
         ]
    , functions = []
    , splices =
         [ """
            // diffuse + lambert
            vec3 lightIntensities = vec3(1.5, 1.0, 1.0);
            vec3 diffuseColor = texture2D(textureDiff, vTexCoord).rgb;
            vec3 diffuse = lambert * diffuseColor * lightIntensities;

            // ambient
            vec3 ambient = 0.3 * diffuseColor;

            // specular
            float shininess = 32.0;
            vec3 viewDir = normalize(vViewDirection);
            vec3 reflectDir = reflect(-lightDir, pixelNormal);
            vec3 halfwayDir = normalize(lightDir + viewDir);
            float spec = pow(max(dot(pixelNormal, halfwayDir), 0.0), shininess);
            vec3 specular = vec3(0.2) * spec * lightIntensities;

            // attenuation
            float lightAttenuation = 0.3;
            float attenuation = 1.0 / (1.0 + lightAttenuation * pow(length(vLightDirection), 2.0));

            vec3 final_color = ambient + (diffuse + specular) * attenuation;

            gl_FragColor = vec4(final_color, 1.0);
            """
         ]
    }


{-| same as the normal mapping shader, but without deforming normals.
-}
vertexNoTangent : Component
vertexNoTangent =
    { empty
        | id = "lighting.vertexNoTangent"
        , dependencies =
            Dependencies
                [ vertex_position4
                ]
        , provides =
                [ "vLightDirection"
                , "vViewDirection" 
                , "vNormal"
                ]
    , requires = []
    , globals =
        [ Attribute "vec3" "normal"
        , Varying "vec3" "vLightDirection"
        , Varying "vec3" "vViewDirection"
        , Varying "vec3" "vNormal"
        , Uniform "mat4" "modelMatrix"
        , Uniform "vec3" "lightPosition"
        , Uniform "vec3" "viewPosition"
        ]
    , functions = []
    , splices =
        [ """
            vec3 posWorld = (modelMatrix * position4).xyz;

            vLightDirection = lightPosition - posWorld;
            vViewDirection = viewPosition - posWorld;
            // this is incorrect, it should use the normal matrix
            vNormal = mat3(modelMatrix) * normal;
            """
        ]
    }


{-| same as the normal mapping shader, but without deforming normals.
-}
vertexNoNormal : Component
vertexNoNormal =
    { empty
        | id = "lighting.vertexNoNormal"
        , dependencies =
            Dependencies
                [ vertex_gl_Position
                , vertex_vTexCoord
                , vertexNoTangent
                ]
    }


{-| same as the normal mapping shader, but without deforming normals.
-}
fragmentNoNormal : Component
fragmentNoNormal =
    { id = "lighting.fragmentNoNormal"
    , dependencies =
        Dependencies
            [ fragment_lightDir
            , fragment_interpolatedNormal
            , fragment_lambert
            ]
    , provides = [ "gl_FragColor" ]
    , requires = []
    , globals =
        [ Uniform "sampler2D" "textureDiff"
        , Varying "vec2" "vTexCoord"
        , Varying "vec3" "vLightDirection"
        , Varying "vec3" "vViewDirection"
        , Varying "vec3" "vNormal"
        ]
    , functions = []
    , splices =
        [ """
            // diffuse + lambert
            vec3 lightIntensities = vec3(1.5, 1.0, 1.0);
            vec3 diffuseColor = texture2D(textureDiff, vTexCoord).rgb;
            vec3 diffuse = lambert * diffuseColor * lightIntensities;

            // ambient
            vec3 ambient = 0.3 * diffuseColor;

            // specular
            float shininess = 32.0;
            vec3 viewDir = normalize(vViewDirection);
            vec3 reflectDir = reflect(-lightDir, pixelNormal);
            vec3 halfwayDir = normalize(lightDir + viewDir);
            float spec = pow(max(dot(pixelNormal, halfwayDir), 0.0), shininess);
            vec3 specular = vec3(0.2) * spec * lightIntensities;

            // attenuation
            float lightAttenuation = 0.3;
            float attenuation = 1.0 / (1.0 + lightAttenuation * pow(length(vLightDirection), 2.0));

            vec3 final_color = ambient + (diffuse + specular) * attenuation;

            gl_FragColor = vec4(final_color, 1.0);
            """
        ]
    }


{-| same as above, but without any textures.
-}
vertexSimple : Component
vertexSimple =
    { empty
        | id = "lighting.vertexSimple"
        , dependencies =
            Dependencies
                [ vertex_gl_Position
                , vertexNoTangent
                ]
    }


{-| same as above, but without any textures.
-}
fragmentSimple : Component
fragmentSimple =
    { id = "lighting.fragmentSimple"
    , dependencies =
        Dependencies
            [ fragment_lightDir
            , fragment_interpolatedNormal
            , fragment_lambert
            ]
    , provides = [ "gl_FragColor" ]
    , requires = []
    , globals =
        [ Varying "vec3" "vLightDirection"
        , Varying "vec3" "vViewDirection"
        , Varying "vec3" "vNormal"
        ]
    , functions = []
    , splices =
        [ """
            // diffuse + lambert
            vec3 lightIntensities = vec3(1.5, 1.0, 1.0);
            vec3 diffuseColor = vec3(0.3, 0.2, 0.95);
            vec3 diffuse = lambert * diffuseColor * lightIntensities;

            // ambient
            vec3 ambient = 0.2 * diffuseColor;

            // specular
            float shininess = 32.0;
            vec3 viewDir = normalize(vViewDirection);
            vec3 reflectDir = reflect(-lightDir, pixelNormal);
            vec3 halfwayDir = normalize(lightDir + viewDir);
            float spec = pow(max(dot(pixelNormal, halfwayDir), 0.0), shininess);
            vec3 specular = vec3(0.2) * spec * lightIntensities;

            // attenuation
            float lightAttenuation = 0.3;
            float attenuation = 1.0 / (1.0 + lightAttenuation * pow(length(vLightDirection), 2.0));

            vec3 final_color = ambient + (diffuse + specular) * attenuation;
            gl_FragColor = vec4(final_color, 1.0);
            """
        ]
    }
