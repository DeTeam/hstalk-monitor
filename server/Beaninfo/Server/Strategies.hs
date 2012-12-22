--
-- Strategy represents a computation with 
--
module Beaninfo.Server.Strategies (
  serverLoopStrategy,
  commandReceivedStrategy,
  clientDisconnectedStrategy
) where

import Beaninfo.Types
import Beaninfo.Server.Cacher
import Beaninfo.Server.Clients
import Beaninfo.Server.States
import Beaninfo.Stalker
import Beaninfo.WebSockets

import qualified Network.Beanstalk as BS

serverLoopStrategy :: DataSourceServer -> MServer -> IOStrategy
serverLoopStrategy source server = Strategy p $ \_ -> do
    cacher <- newCacher
    let broadCastAll = mapM_ $ broadcast $ getUserMessage source cacher
    withMVar server broadCastAll
  where
        p :: ServerEvent -> Bool
        p TimerPush = True
        p _ = False

clientDisconnectedStrategy :: DataSourceServer -> MServer -> IOStrategy
clientDisconnectedStrategy soruce server = Strategy p $ \(ClientDisconnected client) -> do 
    modifyMVar_ server $ return . (removeClient client)
  where
        p :: ServerEvent -> Bool
        p ClientDisconnected _ = True
        p _ = False

commandReceivedStrategy source server = Strategy p $ \(ClientCommandReceived client command) -> do
    case decode command :: StateChangeMessage of
      Just scm -> do
        handleState server client scm
        cacher <- newCacher
        getUserMessage source cacher >>= sendMessageToClient client
      Nothing -> return ()
  where
        p :: ServerEvent -> Bool
        p ClientCommandReceived _ _ = True
        p _ = False

-- With given computation and event - do some IO
triggerEvent :: IOStrategy -> ServerEvent -> IO ()

