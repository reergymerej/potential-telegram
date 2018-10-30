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


type alias AppMessage =
    String


type alias Model =
    { dieFace : Int
    , wsMessage : AppMessage
    , messages : List AppMessage
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { dieFace = 1
      , wsMessage = "not yet"
      , messages = []
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


testMessage =
    Json.Encode.object
        [ ( "type", Json.Encode.string "test" )
        ]


getMessage : String
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
            let
                decoded =
                    decodeJsonString value
            in
            ( { model
                | wsMessage = decoded
                , messages = decoded :: model.messages
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    fromJS DataFromJS


jsonTest : String
jsonTest =
    """
{
  "name": "Tom",
  "age": 42
}
"""



-- This is the decoder.  It only says what the field name type is.


ageDecoder : Json.Decode.Decoder Int
ageDecoder =
    Json.Decode.field "age" Json.Decode.int



-- This is the function that actually pulls the value, using the decoder.


getIntFromJson : String -> Int
getIntFromJson json =
    case Json.Decode.decodeString ageDecoder json of
        -- TODO: Figure out the right way to handle failures here.
        -- Maybe?
        Err err ->
            -1

        Ok int ->
            int



-- VIEW


appMessage : AppMessage -> Html Msg
appMessage m =
    li [] [ text m ]


renderMessages : List AppMessage -> Html Msg
renderMessages messages =
    ul [] (List.map appMessage messages)


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text (String.fromInt model.dieFace) ]
        , button [ onClick Roll ] [ text "Roll" ]
        , div [] [ text (String.fromInt (getIntFromJson jsonTest)) ]
        , renderMessages model.messages
        ]
