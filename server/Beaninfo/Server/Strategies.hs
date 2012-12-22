--
-- Strategy represents a computation with 
--
module Beaninfo.Server.Strategies (
  serverLoopStrategy,
  commandReceivedStrategy,
  clientDisconnectedStrategy,
  triggerEvent
) where

import Beaninfo.Types
import Beaninfo.Messages
import Beaninfo.Strategies
import Beaninfo.Server.Cacher
import Beaninfo.Server.Clients
import Beaninfo.Server.States
import Beaninfo.Stalker
import Beaninfo.WebSockets

import Control.Concurrent (withMVar, modifyMVar_)
import qualified Network.Beanstalk as BS
import Data.Aeson


serverLoopStrategy :: DataSourceServer -> MServer -> IOStrategy
serverLoopStrategy source server = Strategy p $ \_ -> do
    cacher <- newCacher
    let 
        messageFor = getUserMessage source cacher
        broadCastAll = mapM_ $ \client -> do
          message <- messageFor client
          sendMessageToClient client message
    withMVar server broadCastAll
    return ()
  where
        p :: ServerEvent -> Bool
        p TimerPush = True
        p _ = False

clientDisconnectedStrategy :: DataSourceServer -> MServer -> IOStrategy
clientDisconnectedStrategy source server = Strategy p $ \(ClientDisconnected client) -> do 
    modifyMVar_ server $ return . (removeClient client)
  where
        p :: ServerEvent -> Bool
        p (ClientDisconnected _) = True
        p _ = False

commandReceivedStrategy source server = Strategy p $ \(ClientCommandReceived client command) -> do
    case decode command :: Maybe StateChangeMessage of
      Just scm -> do
        client' <- handleState server client scm
        cacher <- newCacher
        getUserMessage source cacher client' >>= sendMessageToClient client'
      Nothing -> return ()
  where
        p :: ServerEvent -> Bool
        p (ClientCommandReceived _ _) = True
        p _ = False

