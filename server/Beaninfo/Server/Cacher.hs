module Beaninfo.Server.Cacher (
    retrieve,
    cache,
    newCacher,
    Cacher()
  ) where


import Data.ByteString.Lazy (ByteString)
import qualified Data.Map as M
import Data.Maybe

import Control.Applicative ( (<$>) )
import Control.Concurrent.MVar ( MVar, newMVar, modifyMVar_, readMVar )

import Beaninfo.Types

type Cacher = MVar (M.Map String ByteString)

newCacher :: IO Cacher
newCacher = newMVar M.empty

getKey :: ClientSubscription -> String
getKey = show

retrieve :: Cacher -> ClientSubscription -> IO (Maybe ByteString)
retrieve cacher sub = M.lookup (getKey sub) <$> readMVar cacher

cache :: Cacher -> ClientSubscription -> IO ByteString -> IO ByteString
cache cacher sub action = do
  value <- action
  let updateHash hash = M.insert (getKey sub) value hash
  modifyMVar_ cacher (return . updateHash)
  return value
