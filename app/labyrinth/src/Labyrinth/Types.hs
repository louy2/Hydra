{-# LANGUAGE DeriveAnyClass #-}

module Labyrinth.Types where


import           Labyrinth.Prelude          as L
import           Labyrinth.Domain

type HasTreasure = Bool

data InventoryState = InventoryState
  { _treasure :: StateVar Bool
  }

data GameState
  = GameStart
  | GameFinished
  | PlayerMove
  | PlayerIsAboutLeaving HasTreasure
  | PlayerIsAboutLossLeavingConfirmation
  deriving (Show, Eq)

data AppState = AppState
  { _labyrinth            :: StateVar Labyrinth
  , _labBounds            :: StateVar Bounds
  , _labRenderTemplate    :: StateVar LabRender
  , _labRenderVar         :: StateVar LabRender
  , _labWormholes         :: StateVar Wormholes
  , _playerPos            :: StateVar Pos
  , _playerHP             :: StateVar Int
  , _bearPos              :: StateVar Pos
  , _playerInventory      :: InventoryState
  , _gameState            :: StateVar GameState
  , _gameMessages         :: StateVar [String]
  }

data AppException
  = NotImplemented String
  | NotSupported String
  | InvalidOperation String
  | GenerationError String
  deriving (Show, Read, Eq, Ord, Generic, ToJSON, FromJSON, Exception)

data GameInfo = GameInfo
  { giLab             :: Labyrinth
  , giPlayerPos       :: Pos
  , giPlayerHP        :: Int
  , giPlayerInventory :: Inventory
  , giBearPos         :: Pos
  }
  deriving (Show, Read, Eq, Ord, Generic, ToJSON, FromJSON)
