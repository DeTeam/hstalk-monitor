{-# LANGUAGE OverloadedStrings #-}

--
-- Author: DeTeam
-- Date: 2012-11-17
-- Description: Little tool for monitoring beanstalkd queue
--  Aeson-based JSON communication via WebSockets, Warp

module Main ( main ) where

import Control.Monad (mapM)
import Control.Concurrent (newMVar)
import Control.Concurrent.Async (async, waitAny)
import Data.Monoid (mappend)

import qualified Network.Beanstalk as BS

-- Common data types
import Beaninfo.Types

import Beaninfo.WebSockets
import Beaninfo.Stalker
import Beaninfo.Server.Strategies
import Beaninfo.Server.Clients

-- WAI + Warp
import Network.Wai.Application.Static (staticApp, defaultWebAppSettings)
import Network.Wai.Handler.WebSockets (intercept)
import Network.Wai.Handler.Warp (runSettings, defaultSettings, 
                                 settingsIntercept, settingsPort)


splitIO :: [IO ()] -> IO ()
splitIO actions = do
  asyncs <- mapM async actions
  waitAny asyncs
  return ()


main :: IO ()
main = do
  state <- newMVar newServerState
  bsServer <- BS.connectBeanstalk "0.0.0.0" "11300"
  let 
      build s = s bsServer state

      serverStrategy = foldl1 (mappend) [
          build serverLoopStrategy,
          build commandReceivedStrategy,
          build clientDisconnectedStrategy
        ]

      config = defaultSettings {
        settingsPort=8765,
        settingsIntercept=intercept $ (application serverStrategy)
      }
      webSocketsServer  = runSettings config $ staticApp $ defaultWebAppSettings "www"
      beanstalkServer   = notyifyServer serverStrategy
  splitIO [webSocketsServer, beanstalkServer]