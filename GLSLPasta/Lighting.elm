module GLSLPasta.Lighting exposing (..)

{-| Basic lighting

# Vertex shaders
@docs vertexPosition, vertexReflection, vertexNormal, vertexNoNormal, vertexSimple

# Fragment shaders
@docs fragmentReflection, fragmentNormal, fragmentNoNormal, fragmentSimple
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

{-| normal mapping according to:
<http://www.gamasutra.com/blogs/RobertBasler/20131122/205462/Three_Normal_Mapping_Techniques_Explained_For_the_Mathematically_Uninclined.php?print=1>
-}
vertexNormal : Part
vertexNormal =
    { id = "lighting.vertexNormal"
    , dependencies = []
    , globals =
        [ Attribute "vec3" "position"
        , Attribute "vec3" "normal"
        , Attribute "vec2" "texCoord"
        , Attribute "vec4" "tangent"
        , Varying "vec2" "vTexCoord"
        , Varying "vec3" "vLightDirection"
        , Varying "vec3" "vViewDirection"
        , Varying "vec4" "worldPosition"
        , Uniform "mat4" "modelViewProjectionMatrix"
        , Uniform "mat4" "modelMatrix"
        , Uniform "vec3" "lightPosition"
        , Uniform "vec3" "viewPosition"
        ]
    , functions =
        [ """
            mat3 transpose(mat3 m) {
                return mat3(m[0][0], m[1][0], m[2][0],
                            m[0][1], m[1][1], m[2][1],
                            m[0][2], m[1][2], m[2][2]);
            }
            """
        ]
    , splices =
        [ """
            vec4 pos = vec4(position, 1.0 );
            vec3 posWorld = (modelMatrix * pos).xyz;

            // Tangent, Bitangent, Normal space matrix TBN
            // this isn't entirely correct, it should use the normal matrix
            // http://www.lighthouse3d.com/tutorials/glsl-12-tutorial/the-normal-matrix/
            vec3 n = normalize((modelMatrix * vec4(normal, 0.0)).xyz);
            vec3 t = normalize((modelMatrix * vec4(tangent.xyz, 0.0)).xyz);
            vec3 b = normalize((modelMatrix * vec4((cross(normal, tangent.xyz) * tangent.w), 0.0)).xyz);
            mat3 tbn = transpose(mat3(t, b, n));
            vLightDirection = tbn*(lightPosition - posWorld);
            vViewDirection = tbn*(viewPosition - posWorld);
            vTexCoord = texCoord;
            gl_Position = modelViewProjectionMatrix * pos;
            worldPosition = gl_Position;
            """
        ]
    }


{-| normal mapping according to:
<http://www.gamasutra.com/blogs/RobertBasler/20131122/205462/Three_Normal_Mapping_Techniques_Explained_For_the_Mathematically_Uninclined.php?print=1>
-}
fragmentNormal : Part
fragmentNormal =
    { id = "lighting.fragmentNormal"
    , dependencies = []
    , globals =
         [ Uniform "sampler2D" "textureDiff"
         , Uniform "sampler2D" "textureNorm"
         , Varying "vec2" "vTexCoord"
         , Varying "vec3" "vLightDirection"
         , Varying "vec3" "vViewDirection"
         , Varying "vec4" "worldPosition"
         ]
    , functions = []
    , splices =
         [ """
            vec3 lightDir = normalize(vLightDirection);

            // Local normal, in tangent space
            vec3 pixelNormal = normalize(texture2D(textureNorm, vTexCoord).rgb*2.0 - 1.0);
            float lambert = max(dot(pixelNormal, lightDir), 0.0);


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

            float lightenDistance = worldPosition.w * 0.01;
            gl_FragColor *= 1.0 - lightenDistance * vec4(0.18, 0.21, 0.24, 0.15);
            """
         ]
    }


{-| same as the normal mapping shader, but without deforming normals.
-}
vertexNoNormal : Part
vertexNoNormal =
    { id = "lighting.vertexNoNormal"
    , dependencies = []
    , globals =
        [ Attribute "vec3" "position"
        , Attribute "vec3" "normal"
        , Attribute "vec2" "texCoord"
        , Varying "vec2" "vTexCoord"
        , Varying "vec3" "vLightDirection"
        , Varying "vec3" "vViewDirection"
        , Varying "vec3" "vNormal"
        , Varying "vec4" "worldPosition"
        , Uniform "mat4" "modelViewProjectionMatrix"
        , Uniform "mat4" "modelMatrix"
        , Uniform "vec3" "lightPosition"
        , Uniform "vec3" "viewPosition"
        ]
    , functions = []
    , splices =
        [ """
            vec4 pos = vec4(position, 1.0 );
            vec3 posWorld = (modelMatrix * pos).xyz;

            vLightDirection = lightPosition - posWorld;
            vViewDirection = viewPosition - posWorld;
            vTexCoord = texCoord;
            // this is incorrect, it should use the normal matrix
            vNormal = mat3(modelMatrix) * normal;
            gl_Position = modelViewProjectionMatrix * pos;
            worldPosition = gl_Position;
            """
        ]
    }


{-| same as the normal mapping shader, but without deforming normals.
-}
fragmentNoNormal : Part
fragmentNoNormal =
    { id = "lighting.fragmentNoNormal"
    , dependencies = []
    , globals =
        [ Uniform "sampler2D" "textureDiff"
        , Varying "vec2" "vTexCoord"
        , Varying "vec3" "vLightDirection"
        , Varying "vec3" "vViewDirection"
        , Varying "vec3" "vNormal"
        , Varying "vec4" "worldPosition"
        ]
    , functions = []
    , splices =
        [ """
            vec3 lightDir = normalize(vLightDirection);

            // lambert
            vec3 pixelNormal = normalize(vNormal);
            float lambert = max(dot(pixelNormal, lightDir), 0.0);

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

            float lightenDistance = worldPosition.w * 0.01;
            gl_FragColor *= 1.0 - lightenDistance * vec4(0.18, 0.21, 0.24, 0.15);
            """
        ]
    }


{-| same as above, but without any textures.
-}
vertexSimple : Part
vertexSimple =
    { id = "lighting.vertexSimple"
    , dependencies = []
    , globals =
        [ Attribute "vec3" "position"
        , Attribute "vec3" "normal"
        , Varying "vec3" "vLightDirection"
        , Varying "vec3" "vViewDirection"
        , Varying "vec3" "vNormal"
        , Varying "vec4" "worldPosition"
        , Uniform "mat4" "modelViewProjectionMatrix"
        , Uniform "mat4" "modelMatrix"
        , Uniform "vec3" "lightPosition"
        , Uniform "vec3" "viewPosition"
        ]
    , functions = []
    , splices =
        [ """
            vec4 pos = vec4(position, 1.0 );
            vec3 posWorld = (modelMatrix * pos).xyz;

            vLightDirection = lightPosition - posWorld;
            vViewDirection = viewPosition - posWorld;
            // this is incorrect, it should use the normal matrix
            vNormal = mat3(modelMatrix) * normal;
            vNormal = normal;
            gl_Position = modelViewProjectionMatrix * pos;
            worldPosition = gl_Position;
            """
        ]
    }


{-| same as above, but without any textures.
-}
fragmentSimple : Part
fragmentSimple =
    { id = "lighting.fragmentSimple"
    , dependencies = []
    , globals =
        [ Varying "vec3" "vLightDirection"
        , Varying "vec3" "vViewDirection"
        , Varying "vec3" "vNormal"
        , Varying "vec4" "worldPosition"
        ]
    , functions = []
    , splices =
        [ """
            vec3 lightDir = normalize(vLightDirection);

            // lambert
            vec3 pixelNormal = normalize(vNormal);
            float lambert = max(dot(pixelNormal, lightDir), 0.0);

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

            float lightenDistance = worldPosition.w * 0.01;
            gl_FragColor *= 1.0 - lightenDistance * vec4(0.18, 0.21, 0.24, 0.15);
            """
        ]
    }
