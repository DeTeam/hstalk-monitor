{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.Stalker (

  notyifyServer,
  getUserMessage,
  mutateMap

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
import Beaninfo.Server.Strategies
import Beaninfo.Server.Cacher

notyifyServer ::  IOStrategy -> IO ()
notyifyServer strategy = do
    putStrLn "looping"
    triggerEvent strategy TimerPush
    threadDelay t
    notyifyServer server broadcast
  where t = 5000000


mutateMap :: Map S.ByteString S.ByteString -> Map S.ByteString BasicServerInfo
mutateMap m = fromList . map f $ toList m
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
              hash <- liftA mutateMap $ BS.statsServer server
              tubes <- BS.listTubes server
              return $ insert "tubes" (ListServerInfo tubes) hash
            TubeInfo tube -> liftA mutateMap $ BS.statsTube server tube
            JobInfo job -> liftA mutateMap $ BS.statsJob server job
  where sub = getClientSubscription c
        insertCurrentState = insert "state" $ CommonServerInfo $ case sub of
          GeneralInfo -> "general"
          TubeInfo _  -> "tube"
          JobInfo _   -> "job"

