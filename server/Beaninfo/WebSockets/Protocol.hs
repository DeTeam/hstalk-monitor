{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.WebSockets.Protocol (
    broadcastForServer,
    clientAcceptServer
  ) where

import Control.Exception (fromException)
import Control.Monad (forM_, mapM_, forever)
import Control.Concurrent (MVar, newMVar, modifyMVar_, readMVar)
import Control.Monad.IO.Class (liftIO)

import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy as T
import Data.Text.Lazy.Encoding (decodeUtf8)

import Data.Monoid (mappend)

import qualified Network.WebSockets as WS

import System.Random (randomIO)

import Beaninfo.Types
import Beaninfo.WebSockets.Server
import qualified Beaninfo.WebSockets.States as ST

broadcast :: ServerState -> BFunction
broadcast clients getMsg = do

  forM_ clients $ \client -> do
    msg <- getMsg client
    WS.sendSink (getClientSink client) $ makeMessage msg

  where makeMessage = WS.textData . decodeUtf8


generateClientId :: IO Int
generateClientId = randomIO

createClient :: MServer -> WS.Sink CurrentProtocol -> IO Client
createClient state sink = do
  clientId <- generateClientId
  let client = Client clientId sink GeneralInfo
  modifyMVar_ state $ return . (addClient client)
  return client

application :: MServer -> WS.Request -> WSMonad ()
application state rq = do
  WS.acceptRequest rq
  WS.getVersion >>= liftIO . putStrLn . ("Client version: " ++)
  sink <- WS.getSink
  client <- liftIO $ createClient state sink
  let stateManager = controlState state client
  wrapHeartBeat state client stateManager
  return ()

controlState :: MServer -> Client -> WSMonad ()
controlState state client = do
  command <- WS.receiveData :: WSMonad ByteString
  liftIO $ putStrLn "command received"
  ST.handleState state client command

wrapHeartBeat :: MServer -> Client -> WSMonad () -> WSMonad ()
wrapHeartBeat state client action = do
    flip WS.catchWsError catchDisconnect $ do
      action
      wrapHeartBeat state client action
  where catchDisconnect e = case fromException e of
          Just WS.ConnectionClosed -> do
            liftIO $ do
              putStrLn "Client disconnected"
              modifyMVar_ state $ return . (removeClient client)
          _ -> return ()

clientAcceptServer :: MServer -> String -> Int -> IO ()
clientAcceptServer state host port =  WS.runServer host port $ application state

broadcastForServer :: MServer -> BFunction
broadcastForServer state getMsg = (return state) >>= readMVar >>= (flip broadcast $ getMsg)

