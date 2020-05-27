
module Labyrinth.Tests.LogicSpec where

import qualified Control.Exception as E
import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified Data.Word as Word8
import           Test.Hspec (Spec, around, describe, it, shouldBe, shouldSatisfy)
import           Test.Hspec.QuickCheck (prop)
import           Test.QuickCheck (arbitrary, property, verbose, withMaxSuccess)
import           Test.QuickCheck.Monadic (assert, monadicIO, pick, pre, run)

import qualified Hydra.Domain               as D
import qualified Hydra.Runtime              as R
import qualified Hydra.Interpreters         as R

import           Labyrinth.Prelude
import           Labyrinth.App
import           Labyrinth.Types
import           Labyrinth.Domain
import           Labyrinth.Render
import           Labyrinth.Algorithms
import           Labyrinth.Labyrinths
import           Labyrinth.Gen
import           Labyrinth.Lens


initAppState :: Bool -> (Int, Int, Labyrinth) -> AppL AppState
initAppState hasTreasure (x0, y0, lab) = do
  let LabyrinthInfo {..} = analyzeLabyrinth lab
  let renderTemplate = renderSkeleton _bounds

  renderTemplateVar <- newVarIO renderTemplate
  labRenderVar      <- newVarIO renderTemplate
  labVar            <- newVarIO lab
  labBoundsVar      <- newVarIO _bounds
  wormholesVar      <- newVarIO _wormholes
  posVar            <- newVarIO (x0, y0)
  playerHPVar       <- newVarIO 100
  bearPosVar        <- newVarIO (x0, y0)
  inv               <- InventoryState <$> newVarIO hasTreasure
  gameStateVar      <- newVarIO PlayerMove
  moveMsgsVar       <- newVarIO []

  pure $ AppState
    labVar
    labBoundsVar
    renderTemplateVar
    labRenderVar
    wormholesVar
    posVar
    playerHPVar
    bearPosVar
    inv
    gameStateVar
    moveMsgsVar


withAppState :: Labyrinth -> R.AppRuntime -> (AppState -> IO a) -> IO a
withAppState lab rt act = do
  st <- R.runAppL rt $ initAppState False (0, 0, lab)
  act st

withLabyrinthApp :: Labyrinth -> ((R.AppRuntime, AppState) -> IO a) -> IO a
withLabyrinthApp lab act
  = R.withAppRuntime Nothing
  $ \rt -> withAppState lab rt
  $ \st -> act (rt, st)

runLabMethod :: (Int, Int, Labyrinth) -> R.AppRuntime -> (AppState -> AppL a) -> IO a
runLabMethod startLab rt act = R.runAppL rt (initAppState False startLab >>= act)

runLabMethodWithTreasure :: (Int, Int, Labyrinth) -> R.AppRuntime -> (AppState -> AppL a) -> IO a
runLabMethodWithTreasure startLab rt act = R.runAppL rt (initAppState True startLab >>= act)

spec :: Spec
spec = do
  around (R.withCoreRuntime Nothing)
    $ it "generated labyrinth has correct bounds"
    $ \runtime -> property
    $ withMaxSuccess 5
    $ monadicIO
    $ do
        eLab <- run $ try $ R.runLangL runtime generateRndLabyrinth
        case eLab of
          Left (err :: SomeException) -> assert False
          Right lab -> do
            let LabyrinthInfo {..} = analyzeLabyrinth lab
            let (x, y) = _bounds
            let wms = Map.size _wormholes
            assert $ x * y >= 16 && x * y <= 100
            assert $ (wms >= 2) && (wms <= 5)

  around (R.withAppRuntime Nothing) $ do

    describe "Labyrinth generation tests" $

      it "generateLabyrinth" $ \rt -> do
        lab <- R.runLangL (R._coreRuntime rt) $ generateLabyrinth (4, 4) 3 5

        let LabyrinthInfo {..} = analyzeLabyrinth lab
        _bounds `shouldBe` (4, 4)
        (Map.size _wormholes) `shouldSatisfy` (\x -> x >= 2 && x <= 5)
        (Set.size _exits) `shouldSatisfy` (\x -> x >= 1 && x <= 3)
        -- _treasure `shouldSatisfy` (\mbT -> isJust mbT && inBounds _bounds (fromJust mbT))

    describe "testMove functional tests" $ do

      let lab = testLabyrinth2

      it "testMove DirUp monolith" $ \rt -> do
        let movingResult = testMove (0, 0) DirUp lab
        movingResult `shouldBe` ImpossibleMove "Step impossible: monolith wall"

      it "testMove DirRight wall" $ \rt -> do
        let movingResult = testMove (0, 0) DirRight lab
        movingResult `shouldBe` ImpossibleMove "Step impossible: wall"

      it "testMove DirDown pass" $ \rt -> do
        let movingResult = testMove (0, 0) DirDown lab
        movingResult `shouldBe` (SuccessfullMove (0, 1))

      it "testMove DirRight treasure" $ \rt -> do
        let movingResult = testMove (0, 1) DirRight lab
        movingResult `shouldBe` (SuccessfullMove (1, 1))

      it "testMove DirDown wormhole" $ \rt -> do
        let movingResult = testMove (0, 1) DirDown lab
        movingResult `shouldBe` (SuccessfullMove (0, 2))

      it "testMove DirRight exit no treasure" $ \rt -> do
        let movingResult = testMove (2, 1) DirRight lab
        movingResult `shouldBe` LeavingLabyrinthMove

      it "testMove DirRight exit treasure" $ \rt -> do
        let movingResult = testMove (2, 1) DirRight lab
        movingResult `shouldBe` LeavingLabyrinthMove

    describe "performPlayerContentEvent tests" $ do

      it "performPlayerContentEvent no content" $ \rt -> do
        (pos, tr, gs) <- runLabMethod (0, 0, testLabyrinth2) rt (\st -> do
          scenario $ performPlayerContentEvent st

          pos <- readVarIO $ st ^. playerPos
          tr  <- readVarIO $ st ^. playerInventory . treasure
          gs  <- readVarIO $ st ^. gameState
          pure (pos, tr, gs))

        pos `shouldBe` (0, 0)
        tr `shouldBe` False
        gs `shouldBe` PlayerMove

      it "performPlayerContentEvent wormhole" $ \rt -> do
        (pos, tr, gs) <- runLabMethod (0, 2, testLabyrinth2) rt (\st -> do
          scenario $ performPlayerContentEvent st

          pos <- readVarIO $ st ^. playerPos
          tr  <- readVarIO $ st ^. playerInventory . treasure
          gs  <- readVarIO $ st ^. gameState
          pure (pos, tr, gs))

        pos `shouldBe` (2, 0)
        tr `shouldBe` False
        gs `shouldBe` PlayerMove
