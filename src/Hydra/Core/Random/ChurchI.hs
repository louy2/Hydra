module Hydra.Core.Random.ChurchI where

import           Hydra.Prelude


import qualified Hydra.Core.ChurchL as CL
import qualified Hydra.Core.Random.Interpreter as I
import qualified Hydra.Core.Language as L

runRandomL :: CL.RandomL a -> IO a
runRandomL = foldF I.interpretRandomF
