{-# LANGUAGE OverloadedStrings #-}

module Beaninfo.Server.States (
  handleState,
  messageToState
) where 

import Control.Concurrent (modifyMVar_)

import Data.ByteString.Char8 (pack)

import Beaninfo.Types
import Beaninfo.Messages
import Beaninfo.Server.Clients

modifySubscriptionFor :: MServer -> Client -> ClientSubscription -> IO Client
modifySubscriptionFor state client s = do
      let clientId = getClientId client
          sink = getClientSink client
          client' = Client clientId sink s
      modifyMVar_ state $ return . (addClient client') . (removeClient client)
      return client'

handleState :: MServer -> Client -> StateChangeMessage -> IO Client
handleState state client message = modifySubscription $ messageToState message
  where modifySubscription = modifySubscriptionFor state client

messageToState :: StateChangeMessage -> ClientSubscription
messageToState (TubeMessage name) = TubeInfo (pack name)
messageToState (JobMessage i) = JobInfo i
messageToState UnknownMessage = GeneralInfo