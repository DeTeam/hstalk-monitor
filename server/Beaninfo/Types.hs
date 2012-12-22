module Beaninfo.Types (

  Client (..),
  ServerState (..),
  CurrentProtocol (..),
  MServer (..),
  WSMonad (..),
  ClientSubscription (..),
  BFunction (..),
  BasicServerInfo (..)

  ) where

import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString as S (ByteString)
import qualified Network.WebSockets as WS
import Control.Concurrent (MVar)
import Data.Aeson
import Data.ByteString.Char8 (unpack)
import qualified Network.Beanstalk (BeanstalkServer)

import Data.Typeable
import Control.Arrow

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

data ServerEvent =  ClientConnected Client |
                    ClientDisconnected Client |
                    ClientCommandReceived Client ByteString | 
                    TimerPush

data Strategy a = Strategy {
  shouldActivate :: ServerEvent -> Bool,
  runStrategy :: ServerEvent -> IO a
}

type IOStrategy = Strategy (IO ())

type DataSourceServer = BeanstalkServer

data BasicServerInfo = 
  CommonServerInfo S.ByteString |
  ListServerInfo [S.ByteString]

instance ToJSON BasicServerInfo where
  toJSON (CommonServerInfo s) = toJSON s
  toJSON (ListServerInfo tubes) = toJSON $ fmap unpack tubes

type BFunction = (Client -> IO ByteString) -> IO ()
type CurrentProtocol = WS.Hybi00
type ServerState = [Client]
type MServer = MVar ServerState
type WSMonad = WS.WebSockets CurrentProtocol