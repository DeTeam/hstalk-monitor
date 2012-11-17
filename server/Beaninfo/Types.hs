module Beaninfo.Types (

  Client(..),
  ServerState(..),
  CurrentProtocol(..),
  MServer(..),
  WSMonad(..)

  ) where

import qualified Network.WebSockets as WS
import Control.Concurrent (MVar)

-- Клиент представляет собой кортеж из чиселки и синка
-- т.к. вроде instance'а для Show у синка нет
type Client = (Int, WS.Sink WS.Hybi00)

-- Полезность - синионим
type CurrentProtocol = WS.Hybi00

-- Тут помимо пачки клиентов скоро добавится 
-- клиент beanstalkd'а
type ServerState = [Client]

-- Передаем сервер между тредами
type MServer = MVar ServerState

type WSMonad = WS.WebSockets CurrentProtocol