-- | This module provides utility functions for creating prompts. Useful
-- if you want to use Shh and GHCi as a shell.
module Shh.Prompt where

import Shh
import System.Environment
import Network.HostName
import Data.Time

-- | The type of GHCi prompt functions
type PromptFn = [String] -> Int -> IO String

-- | Format a prompt line suitable for use with Shh.
--
-- This also calls `initInteractive`, which is required for a good
-- user experience when using `shh` as a shell.
--
-- The format of the prompt uses the "%" character as an escape mechanism,
-- allowing for the substitution of various values into the prompt.
--
-- * @%% -> %@
-- * @%u -> current user@
-- * @%w -> current directory@
-- * @%h -> hostname@
-- * @%t -> HH:MM:SS@
--
-- Use it by importing @Shh.Prompt@ in your @.ghci@ or @$SHH_DIR/init.ghci@
-- files and @:set prompt-function formatPrompt "%u\@%h:%w$ "@
formatPrompt :: String -> PromptFn
formatPrompt fmt _ _ = do
    initInteractive
    format fmt
        where

            format :: String -> IO String
            format ('%' : '%' : rest) = ('%':) <$> format rest
            format ('%' : 'u' : rest) = insertEnv "USER" rest
            format ('%' : 'w' : rest) = insertEnv "PWD" rest
            format ('%' : 'h' : rest) = insertIO getHostName rest
            format ('%' : 't' : rest) = insertIO getTime rest
            format ( x  : rest) = (x:) <$> format rest
            format [] = pure []

            insertEnv :: String -> String -> IO String
            insertEnv var rest = insertIO (getEnv var) rest

            insertIO :: IO String -> String -> IO String
            insertIO a rest = a >>= \s -> (s ++) <$> format rest

            getTime :: IO String
            getTime = formatTime defaultTimeLocale "%H:%M:%S" <$>
                (utcToLocalTime <$> getCurrentTimeZone <*> getCurrentTime)

