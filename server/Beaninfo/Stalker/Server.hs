{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.Stalker.Server (

  notyifyServer

  ) where

import Control.Concurrent (threadDelay)
import Control.Applicative (liftA)
import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString as S
import Data.ByteString.Lazy.Char8 (pack)
import Network.Beanstalk (BeanstalkServer)
import qualified Network.Beanstalk as BS
import qualified Data.Aeson as JSON
import Data.Map (Map, insert, fromList, toList)

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


muteMap :: Map S.ByteString S.ByteString -> Map S.ByteString BasicServerInfo
muteMap m = fromList . map f $ toList m
  where f (k,v) = (k, CommonServerInfo v)

getUserMessage :: BeanstalkServer -> Client -> IO ByteString
getUserMessage server c = do
  putStrLn .show $ getClientSubscription c
  liftA JSON.encode $
    case getClientSubscription c of 
      GeneralInfo -> do
        hash <- liftA muteMap $ BS.statsServer server
        tubes <- BS.listTubes server
        return $ insert "tubes" (ListServerInfo tubes) hash
      TubeInfo tube -> liftA muteMap $ BS.statsTube server tube
      JobInfo job -> liftA muteMap $ BS.statsJob server job
