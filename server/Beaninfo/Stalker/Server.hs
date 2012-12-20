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
import Data.Maybe

import Beaninfo.Types
import Beaninfo.Stalker.Cacher

loopNotification :: BeanstalkServer -> BFunction -> IO ()
loopNotification server broadcast = do
    putStrLn "looping"
    tubes <- BS.listTubes server
    cacher <- newCacher
    broadcast $ getUserMessage server cacher
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

getUserMessage :: BeanstalkServer -> Cacher -> Client -> IO ByteString
getUserMessage server cacher c = do
  putStrLn . show $ sub
  fromCache <- retrieve cacher sub
  case fromCache of
    Just v -> return v
    _ -> cache cacher sub $
        liftA (JSON.encode . insertCurrentState) $ do
          putStrLn "Actually go for data"
          case sub of 
            GeneralInfo -> do
              hash <- liftA muteMap $ BS.statsServer server
              tubes <- BS.listTubes server
              return $ insert "tubes" (ListServerInfo tubes) hash
            TubeInfo tube -> liftA muteMap $ BS.statsTube server tube
            JobInfo job -> liftA muteMap $ BS.statsJob server job
  where sub = getClientSubscription c
        insertCurrentState = insert "state" $ CommonServerInfo $ case sub of
          GeneralInfo -> "general"
          TubeInfo _  -> "tube"
          JobInfo _   -> "job"

