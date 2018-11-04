port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Json.Encode


type alias AppMessage =
    { messageType : String
    , time : Int
    , text : Maybe String
    }


type alias Model =
    { messages : List AppMessage
    , decodeError : Maybe String
    }


type Msg
    = SendToJS
    | DataFromJS Json.Encode.Value


init : () -> ( Model, Cmd Msg )
init _ =
    ( { messages = []
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


messageTextDecoder : Json.Decode.Decoder (Maybe String)
messageTextDecoder =
    Json.Decode.maybe
        (Json.Decode.field "text" Json.Decode.string)



-- type alias Foo = { bing : Int, bang : Int }
-- implicitly creates
-- Foo : Int -> Int -> Foo
-- so you can
-- Foo 1 2 returns { bing = 1, bang = 2 }
--
-- This is a Record Constructor.  It can be expressed as
-- (a -> b -> value)
--
-- So in
-- map2 : (a -> b -> value) -> Decoder a -> Decoder b -> Decoder value
-- the first arg is/can be a type.


messageDecoder : Json.Decode.Decoder AppMessage
messageDecoder =
    Json.Decode.map3 AppMessage
        messageTypeDecoder
        messageTimeDecoder
        messageTextDecoder


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendToJS ->
            ( model
              -- TODO: Build a WS message.
            , sendMessage (Json.Encode.string "a string, stringified")
            )

        DataFromJS encodedValue ->
            case Json.Decode.decodeValue messageDecoder encodedValue of
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
                      }
                    , Cmd.none
                    )


renderMessageText : Maybe String -> Html Msg
renderMessageText maybeText =
    case maybeText of
        Nothing ->
            span [] []

        Just messageText ->
            span [] [ text messageText ]


renderAppMessage : AppMessage -> Html Msg
renderAppMessage m =
    li []
        [ span [] [ text (String.fromInt m.time) ]
        , span [] [ text " - " ]
        , span [] [ text m.messageType ]
        , span [] [ text " - " ]
        , renderMessageText m.text
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
