{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell       #-}

module Hydra.Core.Process.FTL where

import           Hydra.Prelude hiding (atomically)

import Control.Concurrent
import Control.Concurrent.STM

class (Monad m) => ProcessL m where
  type ProcessHandle m :: * -> *
  forkProcess  :: m a -> m (ProcessHandle m a)
  killProcess  :: ProcessHandle m a -> m ()
  tryGetResult :: ProcessHandle m a -> m (Maybe a)
  awaitResult  :: ProcessHandle m a -> m a

newtype H a = H { unH :: (ThreadId, TMVar (Either SomeException a)) }

instance ProcessL (ReaderT e IO) where
  type ProcessHandle (ReaderT e IO) = H
  forkProcess f = ReaderT $ \e -> do
     z <- newEmptyTMVarIO
     t <- forkIOWithUnmask $ \restore -> do
       x <- (restore $ runReaderT f e) `catch` (\e -> do
          atomically $ putTMVar z (Left e)
          throwM e)
       atomically $ putTMVar z (Right x)
     pure $ H (t,z)
  killProcess = ReaderT . const . killThread . fst . unH
  tryGetResult (H (_,e)) = ReaderT $ const $ atomically (tryReadTMVar e) >>=
    traverse (\case
      Left e -> throwM e
      Right x -> pure x)
  awaitResult (H (_,e)) = ReaderT $ const $ atomically (readTMVar e) >>= \case
    Left e -> throwM e
    Right x -> pure x
