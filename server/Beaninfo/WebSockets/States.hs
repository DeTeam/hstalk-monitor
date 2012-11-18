{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.WebSockets.States (

  handleState

  ) where 


import Control.Monad (forM_, mapM_, forever)
import Control.Applicative (empty)
import Control.Concurrent (MVar, newMVar, modifyMVar_, readMVar)
import Control.Monad.IO.Class (liftIO)

import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy as T

import Data.Aeson
import Data.Aeson.Types
import Data.Maybe (maybe)
import Data.HashMap.Strict (HashMap)
import Data.Text  (Text)
import Data.ByteString.Lazy (ByteString)
import Data.ByteString.Char8 (pack)
import qualified Data.HashMap.Strict as HM

import Beaninfo.Types
import Beaninfo.WebSockets.Server

data StateChangeMessage = 
  TubeMessage String  | 
  JobMessage Int      |
  UnknownMessage

instance FromJSON StateChangeMessage where
  parseJSON (Object v) 
      | isTubeMessage v = do
                            tubeName <- v .: "tube"
                            return $ TubeMessage tubeName
      | isJobMessage v = do
                            jobId <- v .: "job"
                            return $ JobMessage jobId
      | otherwise = return UnknownMessage


isTubeMessage :: Object -> Bool
isTubeMessage hash = maybeCompare hash "state" "tube"

isJobMessage :: Object -> Bool
isJobMessage hash = maybeCompare hash "state" "job"

maybeCompare :: Object -> Text -> Text -> Bool
maybeCompare hash key value = maybe False f m
  where f = (== String value)
        m = HM.lookup key hash


handleState :: MServer -> Client -> ByteString -> WSMonad ()
handleState state client message =
  case (decode message) :: Maybe StateChangeMessage of 

    Just (TubeMessage name) -> do
      let tube = pack name
          clientId = getClientId client
          sink = getClientSink client
          client' = Client clientId sink (TubeInfo tube)
      liftIO $ putStrLn "switch to tube"
      liftIO $ modifyMVar_ state $ return . (addClient client') . (removeClient client)
      return ()

    Just (JobMessage i) -> do
      let clientId = getClientId client
          sink = getClientSink client
          client' = Client clientId sink (JobInfo i)
      liftIO $ modifyMVar_ state $ return . (addClient client') . (removeClient client)
      liftIO $ putStrLn "switch to job"
      return ()

    Just UnknownMessage -> do
      let clientId = getClientId client
          sink = getClientSink client
          client' = Client clientId sink GeneralInfo
      liftIO $ modifyMVar_ state $ return . (addClient client') . (removeClient client)
      liftIO $ putStrLn "switch to general info"
      return ()

    _ ->  do
      liftIO $ putStrLn "Something we can't handle"
      return ()



