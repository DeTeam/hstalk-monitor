module Beaninfo.Types (

  Client (..),
  ServerState (..),
  CurrentProtocol (..),
  MServer (..),
  WSMonad (..),
  ClientSubscription (..)

  ) where

import Data.ByteString.Lazy (ByteString)
import qualified Network.WebSockets as WS
import Control.Concurrent (MVar)

data ClientSubscription =
  GeneralInfo |
  TubeInfo ByteString  |
  JobInfo Int

data Client = Client {
    getClientId :: Int,
    getClientSink :: WS.Sink CurrentProtocol,
    getClientSubscription :: ClientSubscription
  }

type CurrentProtocol = WS.Hybi00
type ServerState = [Client]
type MServer = MVar ServerState
type WSMonad = WS.WebSockets CurrentProtocol