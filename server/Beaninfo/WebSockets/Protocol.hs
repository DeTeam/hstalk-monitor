{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.WebSockets.Protocol (
    broadcastForServer,
    clientAcceptServer
  ) where

-- Полезности для работы с MVar итд
import Control.Exception (fromException)
import Control.Monad (forM_, mapM_, forever)
import Control.Concurrent (MVar, newMVar, modifyMVar_, readMVar)
import Control.Monad.IO.Class (liftIO)

-- Всякие внешние зависимости
import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy as T
import Data.Text.Lazy.Encoding (decodeUtf8)

-- Конкатенация строчек нужна
import Data.Monoid (mappend)

-- Веб-сокеты
import qualified Network.WebSockets as WS

import System.Random (randomIO)

-- На нужны типы
import Beaninfo.Types
import Beaninfo.WebSockets.Server

-- Вещалка всем клиентами
broadcast :: ServerState -> ByteString -> IO ()
broadcast clients message = do

  -- Отправляем мессадж всем клиентам
  forM_ clients $ \(_, sink) -> 
    WS.sendSink sink $ makeMessage message

  where makeMessage = WS.textData . decodeUtf8

-- Генерим айдишничек для юзера
generateClientId :: IO Int
generateClientId = randomIO

-- Нужна ф-ия для создания клиента в IO монаде
-- Фишка - генерим случайный ID
-- Изменяем состояние
createClient :: MServer -> WS.Sink CurrentProtocol -> IO Client
createClient state sink = do
  clientId <- generateClientId
  let client = (clientId, sink)
  modifyMVar_ state $ return . (addClient client)
  return client

-- Получаем синк
-- Как-то лог
-- Создем клиента
-- Добавляем клиента
application :: MServer -> WS.Request -> WS.WebSockets CurrentProtocol ()
application state rq = do
  WS.acceptRequest rq
  WS.getVersion >>= liftIO . putStrLn . ("Client version: " ++)
  sink <- WS.getSink
  client <- liftIO $ createClient state sink
  forever hearbeat
  return ()

hearbeat :: WS.WebSockets CurrentProtocol ByteString
hearbeat = WS.receiveData

clientAcceptServer :: MServer -> String -> Int -> IO ()
clientAcceptServer state host port =  WS.runServer host port $ application state

broadcastForServer :: MServer -> ByteString -> IO ()
broadcastForServer state msg = (return state) >>= readMVar >>= (flip broadcast $ msg)

