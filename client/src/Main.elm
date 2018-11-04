port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Json.Encode
import Random


type alias AppMessage =
    { messageType : String
    , time : Int
    }


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


messageTypeDecoder : Json.Decode.Decoder String
messageTypeDecoder =
    Json.Decode.field "type" Json.Decode.string


messageTimeDecoder : Json.Decode.Decoder Int
messageTimeDecoder =
    Json.Decode.field "time" Json.Decode.int



-- map2 : (a -> b -> value) -> Decoder a -> Decoder b -> Decoder value
-- (a -> b -> value) is the Record Constructor for a type alias
-- type alias Foo = { bing : Int, bang : Int }
-- Foo 1 2 returns { bing = 1, bang = 2 }
-- FooConstructor : Int -> Int -> Foo


messageDecoder : Json.Decode.Decoder AppMessage
messageDecoder =
    Json.Decode.map2 AppMessage
        messageTypeDecoder
        messageTimeDecoder


decodeDataFromJs : Json.Encode.Value -> Result Json.Decode.Error AppMessage
decodeDataFromJs encodedValue =
    case Json.Decode.decodeValue messageDecoder encodedValue of
        Result.Err decodeError ->
            Result.Err decodeError

        Result.Ok decoded ->
            Result.Ok decoded


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendToJS ->
            ( model
              -- TODO: Build a WS message.
            , sendMessage (Json.Encode.string "a string, stringified")
            )

        DataFromJS encodedValue ->
            case decodeDataFromJs encodedValue of
                -- If there is a decode problem, add it to the model so we can see it.
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

                -- If we can decode it, update the model to include the new message.
                Result.Ok decoded ->
                    ( { model
                        | decodeError = Nothing
                        , messages = decoded :: model.messages

                        -- , messages = { messageType = "dummy" } :: model.messages
                      }
                    , Cmd.none
                    )


getMessageType : Json.Encode.Value -> Result Json.Decode.Error String
getMessageType encodedValue =
    Json.Decode.decodeValue (Json.Decode.field "type" Json.Decode.string) encodedValue


renderAppMessage : AppMessage -> Html Msg
renderAppMessage m =
    li []
        [ span [] [ text (String.fromInt m.time) ]
        , span [] [ text " - " ]
        , span [] [ text m.messageType ]
        ]


renderMessages : List AppMessage -> Html Msg
renderMessages messages =
    div []
        [ div [] [ text ("messages: " ++ String.fromInt (List.length messages)) ]
        , ul [] (List.map renderAppMessage messages)
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
