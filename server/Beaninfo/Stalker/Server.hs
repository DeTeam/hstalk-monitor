{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.Stalker.Server (

  notyifyServer

  ) where

import Control.Concurrent (threadDelay)
import Control.Applicative (liftA)
import Data.ByteString.Lazy (ByteString)
import Data.ByteString.Lazy.Char8 (pack)
import Network.Beanstalk (BeanstalkServer)
import qualified Network.Beanstalk as BS
import qualified Data.Aeson as JSON

import Beaninfo.Types

loopNotification :: BeanstalkServer -> BFunction -> IO ()
loopNotification server broadcast = do
    putStrLn "looping"
    tubes <- BS.listTubes server
    broadcast $ getUserMessage server
    threadDelay t
    loopNotification server broadcast
  where t = 5000000

notyifyServer :: BFunction -> String -> Int -> IO ()
notyifyServer broadcast host port = do
  server <- BS.connectBeanstalk host (show port)
  loopNotification server broadcast


getUserMessage :: BeanstalkServer -> Client -> IO ByteString
getUserMessage server c = do
  putStrLn .show $ getClientSubscription c
  liftA JSON.encode $
    case getClientSubscription c of 
      GeneralInfo -> BS.statsServer server
      TubeInfo tube -> BS.statsTube server tube
      JobInfo job -> BS.statsJob server job
