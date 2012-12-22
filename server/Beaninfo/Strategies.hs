{-# LANGUAGE TypeSynonymInstances, FlexibleInstances #-}

module Beaninfo.Strategies (
  Strategy (..),
  triggerEvent
) where

import Data.Monoid

import Beaninfo.Types


instance Monoid IOStrategy where
  mempty = Strategy (const False) $ \_ -> return ()
  s1 `mappend` s2 = Strategy (const True) $ \e -> triggerEvent s1 e >> triggerEvent s2 e 



-- With given computation and event - do some IO
triggerEvent :: IOStrategy -> ServerEvent -> IO ()
triggerEvent s e = do
  if shouldActivate s e
    then runStrategy s e
    else return ()