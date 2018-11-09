port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Attributes
import Html.Events exposing (..)
import Json.Decode as D
import Json.Encode


type CellStatus
    = X
    | O
    | Available


type alias MessageRow =
    List String


type alias MessageBoard =
    List MessageRow


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
    , yourTurn : Maybe Bool
    , board : Maybe MessageBoard
    }


type alias Model =
    { board : Board
    , messages : List AppMessage
    , debugString : Maybe String
    , yourTurn : Bool
    , you : Maybe String
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
      , yourTurn = False
      , you = Maybe.Nothing
      }
    , Cmd.none
    )


port fromJS : (Json.Encode.Value -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    fromJS DataFromJS


port sendMessage : Json.Encode.Value -> Cmd whateverwewant


nullableString : D.Decoder String
nullableString =
    D.oneOf
        [ D.string
        , D.null "?"
        ]


rowDecoder : D.Decoder MessageRow
rowDecoder =
    D.list nullableString


boardDecoder : D.Decoder MessageBoard
boardDecoder =
    D.list rowDecoder


decodeBoardFromJson : String -> Result D.Error MessageBoard
decodeBoardFromJson json =
    D.decodeString boardDecoder json


messageTypeDecoder : D.Decoder String
messageTypeDecoder =
    D.field "type" D.string


messageTimeDecoder : D.Decoder Int
messageTimeDecoder =
    D.field "time" D.int


messageTextDecoder : D.Decoder (Maybe String)
messageTextDecoder =
    D.maybe
        (D.field "text" D.string)


messageYourTurnDecoder : D.Decoder (Maybe Bool)
messageYourTurnDecoder =
    D.maybe
        (D.field "yourTurn" D.bool)


messageBoardDecoder : D.Decoder (Maybe MessageBoard)
messageBoardDecoder =
    D.maybe
        (D.field "board" boardDecoder)


messageDecoder : D.Decoder AppMessage
messageDecoder =
    D.map5 AppMessage
        messageTypeDecoder
        messageTimeDecoder
        messageTextDecoder
        messageYourTurnDecoder
        messageBoardDecoder


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


getBoardFromMessage : AppMessage -> Board
getBoardFromMessage message =
    { rows =
        [ { index = 0
          , cells =
                [ { index = 0, status = Available }
                , { index = 1, status = X }
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


getNewModel : Model -> AppMessage -> Model
getNewModel model appMessage =
    case appMessage.messageType of
        "start-game" ->
            { model
                | debugString = Just "started the game!"
                , yourTurn = appMessage.yourTurn == Just True
            }

        "update-game" ->
            { model
                | debugString = Just "update-game happened"
                , yourTurn =
                    appMessage.yourTurn == Just True
                , board =
                    getBoardFromMessage appMessage
            }

        _ ->
            { model
                | debugString = Nothing
            }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataFromJS encodedValue ->
            case D.decodeValue messageDecoder encodedValue of
                -- If there is a decode problem, add it to the model so we can see it.
                Result.Err decodeError ->
                    ( { model
                        | debugString =
                            Just
                                (D.errorToString
                                    decodeError
                                )
                      }
                    , Cmd.none
                    )

                -- If we can decode it, update the model to include the new message.
                Result.Ok appMessage ->
                    -- Depending on what type of message this was, we may need to
                    -- update the model in different ways.
                    let
                        newModel =
                            { model
                                | debugString = Nothing
                                , messages = appMessage :: model.messages
                            }
                    in
                    ( getNewModel newModel appMessage
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
    case cell.status of
        Available ->
            Html.button [ onClick (SelectCell rowIndex cell.index) ] [ text "pick" ]

        X ->
            Html.div [] [ text "X" ]

        O ->
            Html.div [] [ text "O" ]


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
        , renderDebugString model.debugString
        , renderMessages model.messages
        ]


main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
