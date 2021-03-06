module Hydra.Core.KVDB.Impl.RocksDB where

import           Hydra.Prelude

import qualified Hydra.Core.Domain   as D

import qualified Database.RocksDB as Rocks

writeOpts :: Rocks.WriteOptions
writeOpts = Rocks.defaultWriteOptions
  { Rocks.sync = True
  }

get :: Rocks.DB -> D.KVDBKey -> IO (D.DBResult D.KVDBValue)
get db key = do
  -- TODO: exception safety
  eMbVal <- try $ Rocks.get db Rocks.defaultReadOptions key
  pure $ case eMbVal of
    Left (err :: SomeException) -> Left $ D.DBError D.SystemError $ show err
    Right Nothing -> Left $ D.DBError D.KeyNotFound $ show key
    Right (Just val) -> Right val

put :: Rocks.DB -> D.KVDBKey -> D.KVDBValue -> IO (D.DBResult ())
put db key val = do
  eRes <- try $ Rocks.put db writeOpts key val
  case eRes of
    Left (err :: SomeException) -> pure $ Left $ D.DBError D.SystemError $ show err
    Right () -> pure $ Right ()
