{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.WebSockets (
    broadcast,
    sendMessageToClient,
    application
  ) where

import Control.Exception (fromException)
import Control.Monad (forM_, mapM_, forever)
import Control.Concurrent (MVar, newMVar, modifyMVar_, readMVar)
import Control.Monad.IO.Class (liftIO)

import Data.ByteString.Lazy (ByteString)
import Data.ByteString.Lazy.Char8 (unpack)
import qualified Data.ByteString.Lazy as T
import Data.Text.Lazy.Encoding (decodeUtf8)

import Data.Monoid (mappend)

import qualified Network.WebSockets as WS

import System.Random (randomIO)

import Beaninfo.Types
import Beaninfo.Strategies
import Beaninfo.Server.States

sendMessageToClient :: Client -> ByteString -> IO ()
sendMessageToClient client message = WS.sendSink (getClientSink client) $ makeMessage message
  where makeMessage = WS.textData . decodeUtf8

broadcast :: ServerState -> BFunction
broadcast clients getMsg = do
  forM_ clients $ \client -> do
    getMsg client >>= sendMessageToClient client


generateClientId :: IO Int
generateClientId = randomIO

createClient :: WS.Sink CurrentProtocol -> IO Client
createClient sink = do
  clientId <- generateClientId
  let client = Client clientId sink GeneralInfo
  return client

application :: IOStrategy -> WS.Request -> WSMonad ()
application strategy rq = do
  WS.acceptRequest rq
  WS.getVersion >>= liftIO . putStrLn . ("Client version: " ++)
  sink <- WS.getSink
  client <- liftIO $ createClient sink
  liftIO $ triggerEvent strategy (ClientConnected client)
  let stateManager = controlState strategy client
  wrapHeartBeat strategy client stateManager
  return ()

controlState :: IOStrategy -> Client -> WSMonad ()
controlState strategy client = do
  command <- WS.receiveData :: WSMonad ByteString
  liftIO $ do
    putStrLn $ "command received" ++ (unpack command)
    triggerEvent strategy (ClientCommandReceived client command)


wrapHeartBeat :: IOStrategy -> Client -> WSMonad () -> WSMonad ()
wrapHeartBeat strategy client action = do
    flip WS.catchWsError catchDisconnect $ do
      action
      wrapHeartBeat strategy client action
  where catchDisconnect e = case fromException e of
          Just WS.ConnectionClosed -> do
            liftIO $ do
              putStrLn "Client disconnected"
              triggerEvent strategy (ClientDisconnected client)
          _ -> return ()

--broadcastForServer :: MServer -> BFunction
--broadcastForServer state getMsg = (return state) >>= readMVar >>= (flip broadcast $ getMsg)

