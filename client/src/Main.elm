port module Main exposing (Board, Cell, CellStatus(..), Model, Msg(..), Row, cellView, init, main, rowView, update, view)

import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes
import Html.Events exposing (onClick)
import Json.Encode as E


main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


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


type alias Model =
    { board : Board
    , buttonClicks: Int
    }


init : Model
init =
  { board =
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
    , buttonClicks = 0
  }



-- UPDATE


type Msg
    = Increment
    | SendTestMessage


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            model
        SendTestMessage ->
          { model | buttonClicks = model.buttonClicks + 1 }




-- VIEW


cellView : Cell -> Html Msg
cellView model =
    div [ Html.Attributes.attribute "class" "cell" ] []


rowView : Row -> Html Msg
rowView model =
    div [ Html.Attributes.attribute "class" "row" ]
        (List.map cellView model.cells)


view : Model -> Html Msg
view model =
  div []
  [ div []
        (List.map rowView model.board.rows)
        , button [ onClick SendTestMessage ] [ text "test" ]
        , div [] [text (String.fromInt model.buttonClicks)]
        ]

port messages : E.Value -> Cmd msg
