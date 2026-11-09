-- Simulacion del automata usando la monada State (puntaje extra E)
module Simulacion
  ( paso
  , simular
  ) where

import Control.Monad (forM_)
import Control.Monad.State
import Automata (Automata(..), mostrar)
import qualified Automata as A

-- Un paso de la simulacion como accion de State.
-- No recibe ni devuelve el automata, solo modifica el estado.
paso :: State Automata ()
paso = modify A.paso

-- Simulacion completa: imprime la generacion actual y avanza un paso,
-- repitiendo n veces. Se usa StateT sobre IO para poder imprimir,
-- liftIO permite imprimir dentro de StateT,
-- y el paso de State se ejecuta dentro con 'state (runState paso)'.
simular :: Int -> StateT Automata IO ()
simular n = forM_ [1 .. n] $ \_ -> do
  fila <- gets mostrar
  liftIO (putStrLn fila)
  state (runState paso)
