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


port sendMessage : Json.Encode.Value -> Cmd whateverwewant


port fromJS : (Json.Encode.Value -> msg) -> Sub msg


decodeJsonString : Json.Encode.Value -> String
decodeJsonString x =
    case Json.Decode.decodeValue Json.Decode.string x of
        Err err ->
            "decode error"

        Ok str ->
            str

testMessage = Json.Encode.object [
  ("type", Json.Encode.string "test")
  ]

getMessage: String
getMessage =
  Json.Encode.encode 2 testMessage

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Roll ->
            ( model
            , Random.generate NewFace (Random.int 1 6)
            )

        NewFace newFace ->
            ( { model | dieFace = newFace }
            -- TODO: Build a WS message.
            , sendMessage (Json.Encode.string "a string, stringified")
            -- , sendMessage (Json.Encode.string "a string, stringified")
            )

        DataFromJS value ->
            ( { model | wsMessage = decodeJsonString value }
            , Cmd.none
            )


jsonTest : String
jsonTest = """
{
  "name": "Tom",
  "age": 42
}
"""

ageDecoder: Json.Decode.Decoder Int
ageDecoder =
  Json.Decode.field "age" Json.Decode.int

-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text (String.fromInt model.dieFace) ]
        , div [] [ text model.wsMessage ]
        , button [ onClick Roll ] [ text "Roll" ]
        , div [] [text (String.fromInt (ageDecoder jsonTest) )]
        ]

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    fromJS DataFromJS


