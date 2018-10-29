port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Json.Encode
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
    | DataFromJS Json.Encode.Value


port portedFunction : Json.Encode.Value -> Cmd whateverwewant


port fromJS : (Json.Encode.Value -> msg) -> Sub msg


decodeJsonString : Json.Encode.Value -> String
decodeJsonString x =
    case Json.Decode.decodeValue Json.Decode.string x of
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
            , portedFunction (Json.Encode.int newFace)
            )

        DataFromJS value ->
            ( { model | wsMessage = decodeJsonString value }
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
