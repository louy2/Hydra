module Hydra.Core.Lang.Interpreter where

import           Hydra.Prelude

import           Hydra.Core.ControlFlow.Interpreter         (runControlFlowL)
import qualified Hydra.Core.Lang.Language               as L
import           Hydra.Core.Logger.Impl.HsLoggerInterpreter (runLoggerL, flushStmLogger)
import           Hydra.Core.Random.Interpreter              (runRandomL)
import qualified Hydra.Core.RLens                       as RLens
import qualified Hydra.Core.Runtime                     as R
import           Hydra.Core.State.Interpreter               (runStateL)

-- | Interprets core lang.
interpretLangF :: R.CoreRuntime -> L.LangF a -> IO a
interpretLangF coreRt (L.EvalStateAtomically action next) = do
    let stateRt = coreRt ^. RLens.stateRuntime
    let logHndl = coreRt ^. RLens.loggerRuntime . RLens.hsLoggerHandle
    res <- atomically $ runStateL stateRt action
    flushStmLogger (stateRt ^. RLens.stmLog) logHndl
    pure $ next res
interpretLangF coreRt (L.EvalControlFlow f    next) = next <$> runControlFlowL coreRt f
interpretLangF coreRt (L.EvalLogger msg next) =
    next <$> runLoggerL (coreRt ^. RLens.loggerRuntime . RLens.hsLoggerHandle) msg
interpretLangF _      (L.EvalRandom  s next)        = next <$> runRandomL s
interpretLangF _      (L.EvalIO f next)             = next <$> f

-- | Runs core lang.
runLangL :: R.CoreRuntime -> L.LangL a -> IO a
runLangL coreRt = foldF (interpretLangF coreRt)
