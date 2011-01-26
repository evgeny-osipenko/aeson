{-# LANGUAGE BangPatterns, OverloadedStrings #-}

import Control.Exception
import Control.Monad
import Data.Aeson
import Data.Aeson.Parser
import Data.Attoparsec
import Data.Time.Clock
import System.Environment (getArgs)
import System.IO
import qualified Data.ByteString as B

main = do
  (cnt:args) <- getArgs
  let count = read cnt :: Int
  forM_ args $ \arg -> bracket (openFile arg ReadMode) hClose $ \h -> do
    putStrLn $ arg ++ ":"
    start <- getCurrentTime
    let loop !good !bad
            | good+bad >= count = return (good, bad)
            | otherwise = do
          hSeek h AbsoluteSeek 0
          let refill = B.hGet h 1024
          result <- parseWith refill json =<< refill
          case result of
            Done _ _ -> loop (good+1) bad
            _        -> loop good (bad+1)
    (good, _) <- loop 0 0
    end <- getCurrentTime
    putStrLn $ "  " ++ show good ++ " good, " ++ show (diffUTCTime end start)
