port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Json.Encode
import Random


type alias Model =
    { messages : List AppMessage
    }


type Msg
    = SendToJS
    | DataFromJS Json.Encode.Value


init : () -> ( Model, Cmd Msg )
init _ =
    ( { messages = []
      }
    , Cmd.none
    )


port fromJS : (Json.Encode.Value -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    fromJS DataFromJS


port sendMessage : Json.Encode.Value -> Cmd whateverwewant


decodeDataFromJs : Json.Encode.Value -> AppMessage
decodeDataFromJs x =
    case getMessageType x of
        -- case Json.Decode.decodeValue (Json.Decode.field "type" Json.Decode.string) x of
        Err err ->
            { messageType = Json.Decode.errorToString err
            }

        Ok messageType ->
            { messageType = messageType
            }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendToJS ->
            ( model
              -- TODO: Build a WS message.
            , sendMessage (Json.Encode.string "a string, stringified")
            )

        DataFromJS jsonMessage ->
            let
                decoded =
                    decodeDataFromJs jsonMessage
            in
            ( { model
                | messages = decoded :: model.messages
              }
            , Cmd.none
            )


getMessageType : Json.Encode.Value -> Result Json.Decode.Error String
getMessageType encodedValue =
    Json.Decode.decodeValue (Json.Decode.field "type" Json.Decode.string) encodedValue


ageDecoder : Json.Decode.Decoder Int
ageDecoder =
    Json.Decode.field "age" Json.Decode.int


getIntFromJson : String -> Int
getIntFromJson json =
    case Json.Decode.decodeString ageDecoder json of
        -- Maybe?
        Err err ->
            -1

        Ok int ->
            int


jsonTest : String
jsonTest =
    """
{
  "name": "Tom",
  "age": 42
}
"""


type alias AppMessage =
    { messageType : String }


renderAppMessage : AppMessage -> Html Msg
renderAppMessage m =
    li [] [ text m.messageType ]


renderMessages : List AppMessage -> Html Msg
renderMessages messages =
    ul [] (List.map renderAppMessage messages)


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick SendToJS ] [ text "SendToJS" ]
        , div [] [ text (String.fromInt (getIntFromJson jsonTest)) ]
        , renderMessages model.messages
        ]


main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
