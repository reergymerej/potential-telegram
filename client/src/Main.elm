port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Attributes
import Html.Events exposing (..)
import Json.Decode
import Json.Encode


type CellStatus
    = X
    | O
    | Available


type alias Cell =
    { index : Int
    , status : CellStatus
    }


type alias Row =
    { index : Int
    , cells : List Cell
    }


type alias Board =
    { rows : List Row
    }


type alias AppMessage =
    { messageType : String
    , time : Int
    , text : Maybe String
    }


type alias Model =
    { board : Board
    , messages : List AppMessage
    , debugString : Maybe String
    }


type Msg
    = DataFromJS Json.Encode.Value
    | SelectCell Int Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( { board =
            { rows =
                [ { index = 0
                  , cells =
                        [ { index = 0, status = Available }
                        , { index = 1, status = Available }
                        , { index = 2, status = Available }
                        ]
                  }
                , { index = 1
                  , cells =
                        [ { index = 0, status = Available }
                        , { index = 1, status = Available }
                        , { index = 2, status = Available }
                        ]
                  }
                , { index = 2
                  , cells =
                        [ { index = 0, status = Available }
                        , { index = 1, status = Available }
                        , { index = 2, status = Available }
                        ]
                  }
                ]
            }
      , messages = []
      , debugString = Maybe.Nothing
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


messageDecoder : Json.Decode.Decoder AppMessage
messageDecoder =
    Json.Decode.map3 AppMessage
        messageTypeDecoder
        messageTimeDecoder
        messageTextDecoder


getCellCoordsString : Int -> Int -> String
getCellCoordsString rowIndex cellIndex =
    String.fromInt rowIndex
        ++ String.fromInt cellIndex


getRelativeCellIndex : Int -> Int -> Int -> Int
getRelativeCellIndex rowLength rowIndex cellIndex =
    rowLength * rowIndex + cellIndex


getSelectCellMessage : Int -> Int -> Json.Encode.Value
getSelectCellMessage rowIndex cellIndex =
    let
        finalIndex =
            getRelativeCellIndex 3 rowIndex cellIndex
    in
    Json.Encode.object
        [ ( "type", Json.Encode.string "move" )
        , ( "cellIndex", Json.Encode.int finalIndex )
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataFromJS encodedValue ->
            case Json.Decode.decodeValue messageDecoder encodedValue of
                -- If there is a decode problem, add it to the model so we can see it.
                Result.Err decodeError ->
                    ( { model
                        | debugString =
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
                        | debugString = Nothing
                        , messages = decoded :: model.messages
                      }
                    , Cmd.none
                    )

        SelectCell rowIndex cellIndex ->
            ( { model
                | debugString =
                    Just (getCellCoordsString rowIndex cellIndex)
              }
            , sendMessage (getSelectCellMessage rowIndex cellIndex)
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


renderDebugString : Maybe String -> Html Msg
renderDebugString maybeDebugString =
    case maybeDebugString of
        Nothing ->
            div [] []

        Just debugString ->
            div []
                [ h2 [] [ text "Debug This!" ]
                , div [] [ text debugString ]
                ]


cellAttributeView : String -> Int -> Html Msg
cellAttributeView label index =
    div [] [ text (label ++ ": " ++ String.fromInt index) ]


cellView : Int -> Cell -> Html Msg
cellView rowIndex cell =
    div [ Html.Attributes.attribute "class" "cell" ]
        [ Html.button [ onClick (SelectCell rowIndex cell.index) ] [ text "pick" ]
        , cellAttributeView "row" rowIndex
        , cellAttributeView "cell" cell.index
        ]


rowView : Row -> Html Msg
rowView row =
    let
        cellViewForRow =
            cellView row.index
    in
    div [ Html.Attributes.attribute "class" "row" ]
        (List.map cellViewForRow row.cells)


boardView : Board -> Html.Html Msg
boardView board =
    div [] (List.map rowView board.rows)


view : Model -> Html Msg
view model =
    div []
        [ boardView model.board
        , renderMessages model.messages
        , renderDebugString model.debugString
        ]


main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
