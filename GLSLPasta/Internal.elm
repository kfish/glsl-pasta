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
                    , name ++ " is defined in " ++ c.newPartId ++ " as:"
                    , ""
                    , "\t" ++ toString c.newGlobal
                    , ""
                    , "but was already defined in " ++ String.join ", " c.oldPartIds ++ " as:"
                    , ""
                    , "\t" ++ toString c.oldGlobal
                    ]
{-
        MissingDependency m ->
            String.join "\n"
                [ "Missing dependency " ++ m.dependency ++ ", required by " ++ m.newPartId
                ]
-}



-- The global symbol table


type alias Symbols =
    Dict String ( List PartId, Global )


insertGlobal : PartId -> Global -> Symbols -> Result Error Symbols
insertGlobal part global symbols =
    case global of
        Attribute newType name ->
            case Dict.get name symbols of
                Nothing ->
                    Ok (Dict.insert name ( [ part ], global ) symbols)

                Just ( oldParts, oldGlobal ) ->
                    let
                        err what =
                            GlobalConflict
                                { what = what
                                , newPartId = part
                                , oldPartIds = oldParts
                                , newGlobal = global
                                , oldGlobal = oldGlobal
                                }
                                |> Err
                    in
                        case oldGlobal of
                            Attribute oldType _ ->
                                if oldType == newType then
                                    Ok (Dict.insert name ( part :: oldParts, global ) symbols)
                                else
                                    err "type"

                            _ ->
                                err "qualifier"

        Uniform newType name ->
            case Dict.get name symbols of
                Nothing ->
                    Ok (Dict.insert name ( [ part ], global ) symbols)

                Just ( oldParts, oldGlobal ) ->
                    let
                        err what =
                            GlobalConflict
                                { what = what
                                , newPartId = part
                                , oldPartIds = oldParts
                                , newGlobal = global
                                , oldGlobal = oldGlobal
                                }
                                |> Err
                    in
                        case oldGlobal of
                            Uniform oldType _ ->
                                if oldType == newType then
                                    Ok (Dict.insert name ( part :: oldParts, global ) symbols)
                                else
                                    err "type"

                            _ ->
                                err "qualifier"

        Varying newType name ->
            case Dict.get name symbols of
                Nothing ->
                    Ok (Dict.insert name ( [ part ], global ) symbols)

                Just ( oldParts, oldGlobal ) ->
                    let
                        err what =
                            GlobalConflict
                                { what = what
                                , newPartId = part
                                , oldPartIds = oldParts
                                , newGlobal = global
                                , oldGlobal = oldGlobal
                                }
                                |> Err
                    in
                        case oldGlobal of
                            Varying oldType _ ->
                                if oldType == newType then
                                    Ok (Dict.insert name ( part :: oldParts, global ) symbols)
                                else
                                    err "type"

                            _ ->
                                err "qualifier"

        Const newType name newValue ->
            case Dict.get name symbols of
                Nothing ->
                    Ok (Dict.insert name ( [ part ], global ) symbols)

                Just ( oldParts, oldGlobal ) ->
                    let
                        err what =
                            GlobalConflict
                                { what = what
                                , newPartId = part
                                , oldPartIds = oldParts
                                , newGlobal = global
                                , oldGlobal = oldGlobal
                                }
                                |> Err
                    in
                        case oldGlobal of
                            Const oldType _ oldValue ->
                                if oldType == newType && oldValue == newValue then
                                    Ok (Dict.insert name ( part :: oldParts, global ) symbols)
                                else if oldType == newType then
                                    err "value"
                                else
                                    err "type"

                            _ ->
                                err "qualifier"


insertGlobals : Part -> Symbols -> ( List Error, Symbols )
insertGlobals part symbols =
    let
        f : Global -> ( List Error, Symbols ) -> ( List Error, Symbols )
        f global ( oldErrors, oldSymbols ) =
            case insertGlobal part.id global oldSymbols of
                Ok newSymbols ->
                    ( oldErrors, newSymbols )

                Err newError ->
                    ( oldErrors ++ [ newError ], oldSymbols )
    in
        List.foldl f ( [], symbols ) part.globals



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

{-
checkDeps : Part -> List PartId -> ( List Error, List PartId )
checkDeps part oldDeps =
    let
        f : PartId -> List Error -> List Error
        f dep oldErrors =
            if List.member dep oldDeps then
                oldErrors
            else
                oldErrors ++ [ MissingDependency { newPartId = part.id, dependency = dep } ]

        errors =
            List.foldl f [] part.dependencies
    in
        ( errors, oldDeps ++ [ part.id ] )

checkDependencies : List Part -> Result (List Error) String
checkDependencies parts =
    let
        f : Part -> ( List Error, List PartId ) -> ( List Error, List PartId )
        f part ( oldErrors, oldDeps ) =
            let
                ( newErrors, newDeps ) =
                    checkDeps part oldDeps
            in
                ( oldErrors ++ newErrors, newDeps )

        ( errors, _ ) =
            List.foldl f ( [], [] ) parts
    in
        case errors of
            [] ->
                Ok ""

            _ ->
                Err errors
-}


expandDependencies : List Part -> List Part
expandDependencies parts =
    let
        expand : Part -> List Part
        expand part =
            case part.dependencies of
                Dependencies deps ->
                    List.concatMap expand deps ++ [ part ]

    in
        List.concatMap expand parts
        |> List.uniqueBy .id
        

combineGlobals : List Part -> Result (List Error) String
combineGlobals parts =
    let
        symbols0 : Symbols
        symbols0 =
            Dict.empty

        f : Part -> ( List Error, Symbols ) -> ( List Error, Symbols )
        f part ( oldErrors, oldSymbols ) =
            let
                ( newErrors, newSymbols ) =
                    insertGlobals part oldSymbols
            in
                ( oldErrors ++ newErrors, newSymbols )

        ( errors, symbols ) =
            List.foldl f ( [], symbols0 ) parts
    in
        case errors of
            [] ->
                Ok (symbolsGenerate symbols)

            _ ->
                Err errors


combineFunctions : List Part -> Result (List Error) String
combineFunctions parts =
    let
        functions : List Function
        functions =
            List.concatMap .functions parts
    in
        Ok (String.join "\n" functions)


combineSplices : List Part -> Result (List Error) String
combineSplices parts =
    let
        splices : List Splice
        splices =
            List.concatMap .splices parts
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


combineWith : String -> List Part -> Result (List Error) String
combineWith template parts0 =
    let
        parts =
            expandDependencies parts0

        -- dependenciesResult =
        --     checkDependencies parts

        globalsResult =
            combineGlobals parts

        functionsResult =
            combineFunctions parts

        splicesResult =
            combineSplices parts

        extractErrors : Result (List Error) String -> List Error
        extractErrors result =
            case result of
                Ok _ ->
                    []

                Err errors ->
                    errors
    in
        -- case ( dependenciesResult, globalsResult, functionsResult, splicesResult ) of
        case ( globalsResult, functionsResult, splicesResult ) of
            ( Ok globals, Ok functions, Ok splices ) ->
                Ok (templateGenerate globals functions splices template)

            _ ->
                Err
                    (List.concatMap extractErrors
                        -- [ dependenciesResult, globalsResult, functionsResult, splicesResult ]
                        [ globalsResult, functionsResult, splicesResult ]
                    )
