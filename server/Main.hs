{-# LANGUAGE OverloadedStrings #-}

--
-- Author: DeTeam
-- Date: 2012-11-17
-- Description: Классная библиотечка (в перспективе - бинарник),
--  которая умеет спавнить WebSockets сервер на указанном хосте/порту
--    и принимает клиентов.
--  Клиенты регуларно получают инфу о состоянии Beanstalkd сервачка
--  (пока что - миниму, потом, может, расширим)
--
--  Для обмена сообщениями используется JSON формализованный с пом-ю Aeson (сообщения опр. формата, иначе - ошибочки)

module Main ( main ) where

-- Для классного распараллеливания
import Control.Concurrent (newMVar)
import Control.Concurrent.Async (async, waitBoth)

-- Веб-сокеты
import qualified Network.WebSockets as WS

-- Всякие нужны типы данных
import Beaninfo.Types

-- Полезности, которые будут использоваться в main и пр
import Beaninfo.WebSockets.Protocol

-- Тут инфа о том, как работать с клиентами,
-- и прочее для работы с ServerState
import Beaninfo.WebSockets.Server

-- Сервер для работы с бинстолком
import Beaninfo.Stalker.Server

-- Подключаем WAI, WARP
import Network.Wai.Application.Static (staticApp, defaultWebAppSettings)
import Network.Wai.Handler.WebSockets (intercept)
import Network.Wai.Handler.Warp (runSettings, defaultSettings, 
                                 settingsIntercept, settingsPort)

-- Берем и делимся на два классных потока
splitIO :: IO () -> IO () -> IO ()
splitIO s1 s2 = do
  a1 <- async s1
  a2 <- async s2
  waitBoth a1 a2
  return ()


main :: IO ()
main = do
  state <- newMVar newServerState
  let 
      config = defaultSettings {
        settingsPort=8765,
        settingsIntercept=intercept $ (application state)
      }
      broadcast = broadcastForServer state
      s1 = runSettings config $ staticApp $ defaultWebAppSettings "www"
      s2 = notyifyServer broadcast "0.0.0.0" 11300
  splitIO s1 s2