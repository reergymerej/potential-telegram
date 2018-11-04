port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Json.Encode
import Random


type alias AppMessage =
    { messageType : String }


type alias Model =
    { messages : List AppMessage
    , fromJs : Maybe Int
    , decodeError : Maybe String
    }


type Msg
    = SendToJS
    | DataFromJS Json.Encode.Value


init : () -> ( Model, Cmd Msg )
init _ =
    ( { messages = []
      , fromJs = Maybe.Nothing
      , decodeError = Maybe.Nothing
      }
    , Cmd.none
    )


port fromJS : (Json.Encode.Value -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    fromJS DataFromJS


port sendMessage : Json.Encode.Value -> Cmd whateverwewant



-- This should return the decoded value OR an error


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

        DataFromJS encodedValue ->
            -- We've got some data.  We need to return a Model and Cmd Msg.
            -- If we can decode it, update the model to show the new message.
            -- If there is a decode problem, add it to the model so we can see it.
            -- Try to decode, get a Result.
            -- Handle cases for the Result.
            case Json.Decode.decodeValue Json.Decode.int encodedValue of
                Result.Err decodeError ->
                    ( { model
                        | decodeError =
                            Just
                                (Json.Decode.errorToString
                                    decodeError
                                )
                      }
                    , Cmd.none
                    )

                Result.Ok decoded ->
                    ( { model
                        | decodeError = Nothing

                        -- , messages = decoded :: model.messages
                        , messages = { messageType = "dummy" } :: model.messages
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


renderAppMessage : AppMessage -> Html Msg
renderAppMessage m =
    li [] [ text m.messageType ]


renderMessages : List AppMessage -> Html Msg
renderMessages messages =
    div []
        [ ul [] (List.map renderAppMessage messages)
        , div [] [ text ("messages: " ++ String.fromInt (List.length messages)) ]
        ]


renderDecodeError : Maybe String -> Html Msg
renderDecodeError maybe =
    case maybe of
        Nothing ->
            div [] []

        Just err ->
            div [] [ text err ]


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick SendToJS ] [ text "SendToJS" ]
        , div [] [ text (String.fromInt (getIntFromJson jsonTest)) ]
        , renderMessages model.messages
        , div []
            [ h2 [] [ text "Decode Error" ]
            , renderDecodeError model.decodeError
            ]
        ]


main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
