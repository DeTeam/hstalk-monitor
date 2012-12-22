{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.Messages (
  StateChangeMessage (..)
) where 

import Data.Aeson
import Data.Aeson.Types
import Data.Maybe (maybe)
import Data.HashMap.Strict (HashMap)
import Data.Text  (Text)
import Data.ByteString.Lazy (ByteString)
import Data.ByteString.Char8 (pack)
import qualified Data.HashMap.Strict as HM

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