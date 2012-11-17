{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.Stalker.Server (

  notyifyServer

  ) where

import Control.Concurrent (threadDelay)
import Data.ByteString.Lazy (ByteString)
import Network.Beanstalk (BeanstalkServer)
import qualified Network.Beanstalk as BS
import qualified Data.Aeson as JSON


type BFunction = ByteString -> IO ()

loopNotification :: BeanstalkServer -> BFunction -> IO ()
loopNotification server broadcast = do
    putStrLn "looping"
    stats <- BS.statsServer server
    broadcast $ JSON.encode stats
    threadDelay t
    loopNotification server broadcast
  where t = 5000000

notyifyServer :: BFunction -> String -> Int -> IO ()
notyifyServer broadcast host port = do
  server <- BS.connectBeanstalk host (show port)
  loopNotification server broadcast