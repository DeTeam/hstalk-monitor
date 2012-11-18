module Beaninfo.Types (

  Client (..),
  ServerState (..),
  CurrentProtocol (..),
  MServer (..),
  WSMonad (..),
  ClientSubscription (..),
  BFunction (..)

  ) where

import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString as S (ByteString)
import qualified Network.WebSockets as WS
import Control.Concurrent (MVar)

data ClientSubscription =
  GeneralInfo |
  TubeInfo S.ByteString  |
  JobInfo Int
  deriving (Show)

data Client = Client {
    getClientId :: Int,
    getClientSink :: WS.Sink CurrentProtocol,
    getClientSubscription :: ClientSubscription
  }


type BFunction = (Client -> IO ByteString) -> IO ()
type CurrentProtocol = WS.Hybi00
type ServerState = [Client]
type MServer = MVar ServerState
type WSMonad = WS.WebSockets CurrentProtocol