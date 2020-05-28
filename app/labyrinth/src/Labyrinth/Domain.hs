{-# LANGUAGE DeriveAnyClass #-}

module Labyrinth.Domain where

import qualified Data.Set as Set

import Labyrinth.Prelude

type Pos = (Int, Int)
type Bounds = (Int, Int)
type Wormholes = Map Int Pos
type Exit = (Pos, Direction)
type Exits = Set.Set Exit

type LabRender = (Bounds, Map Pos String)
type Skeleton = LabRender

data Direction
  = DirUp
  | DirDown
  | DirLeft
  | DirRight
  deriving (Show, Read, Eq, Ord, Bounded, Enum)

data Wall
  = NoWall
  | Wall
  | Monolith Bool     -- ^ True it it's an exit
  deriving (Show, Read, Eq, Ord, Generic, ToJSON, FromJSON)

data Cell = Cell
  { leftWall  :: Wall
  , rightWall :: Wall
  , upWall    :: Wall
  , downWall  :: Wall
  }
  deriving (Show, Read, Eq, Ord, Generic, ToJSON, FromJSON)

data Content
  = NoContent
  | Treasure
  | Wormhole Int
  deriving (Show, Read, Eq, Ord, Generic, ToJSON, FromJSON)

type Labyrinth = Map Pos (Cell, Content)

data Inventory = Inventory
  { treasureFound :: Bool
  }
  deriving (Show, Read, Eq, Ord, Generic, ToJSON, FromJSON)

data LabyrinthInfo = LabyrinthInfo
  { liBounds    :: Bounds
  , liWormholes :: Wormholes
  , liExits     :: Exits
  , liTreasure  :: Maybe Pos
  }
