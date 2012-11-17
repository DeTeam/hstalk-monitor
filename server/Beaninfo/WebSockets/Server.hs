module Beaninfo.WebSockets.Server (

    newServerState,
    numClients,
    clientExists,
    addClient,
    removeClient

  ) where

import Beaninfo.Types

newServerState :: ServerState
newServerState = []

numClients :: ServerState -> Int
numClients = length

clientExists :: Client -> ServerState -> Bool
clientExists client = any ((== fst client) . fst)

addClient :: Client -> ServerState -> ServerState
addClient client clients = client : clients

removeClient :: Client -> ServerState -> ServerState
removeClient client = filter ((/= fst client) . fst)