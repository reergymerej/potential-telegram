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
    { messageType : String }


type alias Model =
    { messages : List AppMessage
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { messages = []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = SendToJS
    | DataFromJS Json.Encode.Value


port sendMessage : Json.Encode.Value -> Cmd whateverwewant


port fromJS : (Json.Encode.Value -> msg) -> Sub msg



-- This fails because we're trying to extract a field from plain JSON.
-- We need to parse the JSON into an object first.


getMessageType : Json.Encode.Value -> Result Json.Decode.Error String
getMessageType encodedValue =
    Json.Decode.decodeValue (Json.Decode.field "type" Json.Decode.string) encodedValue


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
