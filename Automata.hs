-- Modulo con la definicion del automata celular 1D y las reglas de Wolfram
module Automata
  ( Automata(..)
  , crearAutomata
  , crearAleatorio
  , nuevoValor
  , paso
  , mostrar
  ) where

import Data.Bits (testBit)

-- Registro que representa el automata
-- celdas: True = viva, False = muerta
data Automata = Automata
  { celdas     :: [Bool]
  , regla      :: Int
  , generacion :: Int
  } deriving (Show)

-- Crea el automata con una sola celula viva al centro
crearAutomata :: Int -> Int -> Automata
crearAutomata r ancho = Automata
  { celdas     = [i == centro | i <- [0 .. ancho - 1]]
  , regla      = r
  , generacion = 0
  }
  where
    centro = ancho `div` 2

-- Crea el automata a partir de una lista de celdas ya dada
-- (se usa para la condicion inicial aleatoria)
crearAleatorio :: Int -> [Bool] -> Automata
crearAleatorio r cs = Automata { celdas = cs, regla = r, generacion = 0 }

-- Dada la regla y la vecindad (izq, centro, der) entrega el nuevo valor.
-- La vecindad se lee como un numero binario de 3 bits:
--   111 -> 7, 110 -> 6, ..., 000 -> 0
-- y el nuevo valor es el bit en esa posicion del numero de la regla.
-- Ej: regla 30 = 00011110, para la vecindad 100 (=4) el bit 4 es 1.
nuevoValor :: Int -> Bool -> Bool -> Bool -> Bool
nuevoValor r izq centro der = testBit r indice
  where
    indice = 4 * aInt izq + 2 * aInt centro + aInt der
    aInt b = if b then 1 else 0

-- Calcula la siguiente generacion con bordes periodicos
-- (la celda de mas a la izquierda es vecina de la de mas a la derecha)
paso :: Automata -> Automata
paso a = a { celdas = nuevas, generacion = generacion a + 1 }
  where
    cs        = celdas a
    izquierda = last cs : init cs        -- vecino izquierdo de cada celda
    derecha   = drop 1 cs ++ take 1 cs   -- vecino derecho de cada celda
    nuevas    = zipWith3 (nuevoValor (regla a)) izquierda cs derecha

-- Convierte la fila de celdas a texto: '#' viva, ' ' muerta
mostrar :: Automata -> String
mostrar a = map (\c -> if c then '#' else ' ') (celdas a)
