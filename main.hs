-- Tarea 1 INFO188: Automata celular 1D
-- Uso: ./prog <regla> <ancho> <generaciones> [aleatorio]
module Main where

import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.Random (newStdGen, randoms)
import Control.Monad.State (evalStateT)
import Text.Read (readMaybe)

import Automata (Automata, crearAutomata, crearAleatorio)
import Simulacion (simular)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [r, w, g]              -> iniciar r w g False
    [r, w, g, "aleatorio"] -> iniciar r w g True
    _                      -> usoIncorrecto

-- Valida los argumentos y lanza la simulacion
iniciar :: String -> String -> String -> Bool -> IO ()
iniciar r w g aleatorio =
  case (readMaybe r, readMaybe w, readMaybe g) of
    (Just regla, Just ancho, Just gens)
      | regla < 0 || regla > 255 -> do
          putStrLn "Error: la regla debe estar entre 0 y 255"
          exitFailure
      | ancho <= 0 || gens <= 0 -> do
          putStrLn "Error: el ancho y las generaciones deben ser mayores a 0"
          exitFailure
      | otherwise -> do
          inicial <- condicionInicial regla ancho aleatorio
          evalStateT (simular gens) inicial
    _ -> usoIncorrecto

-- Una celula viva al centro, o celdas al azar si se pidio "aleatorio"
condicionInicial :: Int -> Int -> Bool -> IO Automata
condicionInicial regla ancho False = return (crearAutomata regla ancho)
condicionInicial regla ancho True  = do
  gen <- newStdGen
  let cs = take ancho (randoms gen) :: [Bool]
  return (crearAleatorio regla cs)

usoIncorrecto :: IO ()
usoIncorrecto = do
  putStrLn "Uso: ./prog <regla> <ancho> <generaciones> [aleatorio]"
  putStrLn "Ejemplo: ./prog 90 31 8"
  exitFailure
