module GLSLPasta.Internal exposing (..)

import Dict exposing (Dict)
import List.Extra as List
import GLSLPasta.Types exposing (..)


globalName : Global -> Name
globalName global =
    case global of
        Attribute _ name ->
            name

        Uniform _ name ->
            name

        Varying _ name ->
            name

        Const _ name _ ->
            name


globalGenerate : Global -> String
globalGenerate global =
    case global of
        Attribute t n ->
            "attribute " ++ t ++ " " ++ n ++ ";"

        Uniform t n ->
            "uniform " ++ t ++ " " ++ n ++ ";"

        Varying t n ->
            "varying " ++ t ++ " " ++ n ++ ";"

        Const t n v ->
            "const " ++ t ++ " " ++ n ++ " = " ++ v ++ ";"


errorString : Error -> String
errorString error =
    case error of
        GlobalConflict c ->
            let
                name =
                    globalName c.newGlobal
            in
                String.join "\n"
                    [ "Conflicting " ++ c.what ++ " for global " ++ name ++ "."
                    , name ++ " is defined in " ++ c.newComponentId ++ " as:"
                    , ""
                    , "\t" ++ toString c.newGlobal
                    , ""
                    , "but was already defined in " ++ String.join ", " c.oldComponentIds ++ " as:"
                    , ""
                    , "\t" ++ toString c.oldGlobal
                    ]

        MissingRequirement m ->
            String.join "\n"
                [ m.parentComponentId ++ ": Missing requirement " ++ m.requirement ++ ", needed by " ++ m.componentId
                ]



-- The global symbol table


type alias Symbols =
    Dict String ( List ComponentId, Global )


insertGlobal : ComponentId -> ComponentId -> Global -> Symbols -> Result Error Symbols
insertGlobal parent component global symbols =
    case global of
        Attribute newType name ->
            case Dict.get name symbols of
                Nothing ->
                    Ok (Dict.insert name ( [ component ], global ) symbols)

                Just ( oldComponents, oldGlobal ) ->
                    let
                        err what =
                            GlobalConflict
                                { what = what
                                , parentComponentId = parent
                                , newComponentId = component
                                , oldComponentIds = oldComponents
                                , newGlobal = global
                                , oldGlobal = oldGlobal
                                }
                                |> Err
                    in
                        case oldGlobal of
                            Attribute oldType _ ->
                                if oldType == newType then
                                    Ok (Dict.insert name ( component :: oldComponents, global ) symbols)
                                else
                                    err "type"

                            _ ->
                                err "qualifier"

        Uniform newType name ->
            case Dict.get name symbols of
                Nothing ->
                    Ok (Dict.insert name ( [ component ], global ) symbols)

                Just ( oldComponents, oldGlobal ) ->
                    let
                        err what =
                            GlobalConflict
                                { what = what
                                , parentComponentId = parent
                                , newComponentId = component
                                , oldComponentIds = oldComponents
                                , newGlobal = global
                                , oldGlobal = oldGlobal
                                }
                                |> Err
                    in
                        case oldGlobal of
                            Uniform oldType _ ->
                                if oldType == newType then
                                    Ok (Dict.insert name ( component :: oldComponents, global ) symbols)
                                else
                                    err "type"

                            _ ->
                                err "qualifier"

        Varying newType name ->
            case Dict.get name symbols of
                Nothing ->
                    Ok (Dict.insert name ( [ component ], global ) symbols)

                Just ( oldComponents, oldGlobal ) ->
                    let
                        err what =
                            GlobalConflict
                                { what = what
                                , parentComponentId = parent
                                , newComponentId = component
                                , oldComponentIds = oldComponents
                                , newGlobal = global
                                , oldGlobal = oldGlobal
                                }
                                |> Err
                    in
                        case oldGlobal of
                            Varying oldType _ ->
                                if oldType == newType then
                                    Ok (Dict.insert name ( component :: oldComponents, global ) symbols)
                                else
                                    err "type"

                            _ ->
                                err "qualifier"

        Const newType name newValue ->
            case Dict.get name symbols of
                Nothing ->
                    Ok (Dict.insert name ( [ component ], global ) symbols)

                Just ( oldComponents, oldGlobal ) ->
                    let
                        err what =
                            GlobalConflict
                                { what = what
                                , parentComponentId = parent
                                , newComponentId = component
                                , oldComponentIds = oldComponents
                                , newGlobal = global
                                , oldGlobal = oldGlobal
                                }
                                |> Err
                    in
                        case oldGlobal of
                            Const oldType _ oldValue ->
                                if oldType == newType && oldValue == newValue then
                                    Ok (Dict.insert name ( component :: oldComponents, global ) symbols)
                                else if oldType == newType then
                                    err "value"
                                else
                                    err "type"

                            _ ->
                                err "qualifier"


insertGlobals : ComponentId -> { a | id : ComponentId, globals : List Global } -> Symbols -> ( List Error, Symbols )
insertGlobals parent component symbols =
    let
        f : Global -> ( List Error, Symbols ) -> ( List Error, Symbols )
        f global ( oldErrors, oldSymbols ) =
            case insertGlobal parent component.id global oldSymbols of
                Ok newSymbols ->
                    ( oldErrors, newSymbols )

                Err newError ->
                    ( oldErrors ++ [ newError ], oldSymbols )
    in
        List.foldl f ( [], symbols ) component.globals



-- Ordering to sort by qualifier, then name


globalOrder : Global -> ( Int, Name )
globalOrder global =
    case global of
        Attribute t n ->
            ( 1, n )

        Uniform t n ->
            ( 2, n )

        Varying t n ->
            ( 3, n )

        Const t n v ->
            ( 4, n )


symbolsGenerate : Symbols -> String
symbolsGenerate symbols =
    Dict.values symbols
        |> List.map Tuple.second
        |> List.sortBy globalOrder
        |> List.map globalGenerate
        |> String.join "\n"


checkReqs : ComponentId -> Component -> List Feature -> ( List Error, List Feature )
checkReqs parent component oldFeatures =
    let
        f : Feature -> List Error -> List Error
        f feature oldErrors =
            if List.member feature oldFeatures then
                oldErrors
            else
                oldErrors ++ [ MissingRequirement { parentComponentId = parent, componentId = component.id, requirement = feature } ]

        errors =
            List.foldl f [] component.requires
    in
        ( errors, oldFeatures ++ component.provides )


checkRequirements : ComponentId -> List Component -> Result (List Error) String
checkRequirements parent components =
    let
        f : Component -> ( List Error, List Feature ) -> ( List Error, List Feature )
        f component ( oldErrors, oldFeatures ) =
            let
                ( newErrors, newFeatures ) =
                    checkReqs parent component oldFeatures
            in
                ( oldErrors ++ newErrors, newFeatures )

        ( errors, _ ) =
            List.foldl f ( [], [] ) components
    in
        case errors of
            [] ->
                Ok ""

            _ ->
                Err errors


expandDependencies : List Component -> List Component
expandDependencies components =
    let
        expand : Component -> List Component
        expand component =
            case component.dependencies of
                Dependencies deps ->
                    List.concatMap expand deps ++ [ component ]
    in
        List.concatMap expand components
            |> List.uniqueBy .id


combineGlobals : ComponentId -> Template -> List Component -> Result (List Error) String
combineGlobals parent template components =
    let
        (errors0, symbols0) =
            insertGlobals parent template Dict.empty

        f : Component -> ( List Error, Symbols ) -> ( List Error, Symbols )
        f component ( oldErrors, oldSymbols ) =
            let
                ( newErrors, newSymbols ) =
                    insertGlobals parent component oldSymbols
            in
                ( oldErrors ++ newErrors, newSymbols )

        ( errors, symbols ) =
            List.foldl f ( errors0, symbols0 ) components
    in
        case errors of
            [] ->
                Ok (symbolsGenerate symbols)

            _ ->
                Err errors


combineFunctions : List Component -> Result (List Error) String
combineFunctions components =
    let
        functions : List Function
        functions =
            List.concatMap .functions components
    in
        Ok (String.join "\n" functions)


combineSplices : List Component -> Result (List Error) String
combineSplices components =
    let
        splices : List Splice
        splices =
            List.concatMap .splices components
    in
        Ok (String.join "\n" splices)


templateGenerate : String -> String -> String -> String -> String
templateGenerate globals functions splices template =
    let
        replace : String -> String -> String -> String
        replace old new s =
            String.split old s
                |> String.join new
    in
        template
            |> replace "__PASTA_GLOBALS__" globals
            |> replace "__PASTA_FUNCTIONS__" functions
            |> replace "__PASTA_SPLICES__" splices



--


combineWith : Template -> ComponentId -> List Component -> Result (List Error) String
combineWith template parent components0 =
    let
        components =
            expandDependencies components0

        requirementsResult =
            checkRequirements parent components

        globalsResult =
            combineGlobals parent template components

        functionsResult =
            combineFunctions components

        splicesResult =
            combineSplices components

        extractErrors : Result (List Error) String -> List Error
        extractErrors result =
            case result of
                Ok _ ->
                    []

                Err errors ->
                    errors
    in
        case ( requirementsResult, globalsResult, functionsResult, splicesResult ) of
            ( Ok _, Ok globals, Ok functions, Ok splices ) ->
                Ok (templateGenerate globals functions splices template.template)

            _ ->
                Err
                    (List.concatMap extractErrors
                        [ requirementsResult, globalsResult, functionsResult, splicesResult ]
                    )
