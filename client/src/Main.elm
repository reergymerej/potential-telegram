port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Json.Encode as E
import Random


-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { dieFace : Int
    , wsMessage : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { dieFace = 1
      , wsMessage = "not yet"
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Roll
    | NewFace Int
    | DataFromJS E.Value


port portedFunction : E.Value -> Cmd whateverwewant


port fromJS : (E.Value -> msg) -> Sub msg


decodeDataFromJS : E.Value -> String
decodeDataFromJS x =
    case D.decodeValue D.string x of
        Err err ->
            "decode error"

        Ok str ->
            str


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Roll ->
            ( model
            , Random.generate NewFace (Random.int 1 6)
            )

        NewFace newFace ->
            ( { model | dieFace = newFace }
            , portedFunction (E.int newFace)
            )

        DataFromJS value ->
            ( { model | wsMessage = decodeDataFromJS value }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    fromJS DataFromJS



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text (String.fromInt model.dieFace) ]
        , div [] [ text model.wsMessage ]
        , button [ onClick Roll ] [ text "Roll" ]
        ]
