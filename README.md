# Tarea 1 INFO188 - Autómata celular 1D en Haskell

**Ramo:** INFO188 Paradigmas de Programación, 2026
**Profesor:** Cristóbal A. Navarro

**Integrantes:**

- Benjamin Riquelme
- Diego Corales
- Cristobal Mansilla
- Alvaro Guarda

## Descripción

En esta tarea implementamos en Haskell un autómata celular elemental de una dimensión. El autómata es una fila de células que pueden estar vivas o muertas, y en cada generación el nuevo valor de cada célula depende de ella misma y de sus dos vecinas (izquierda y derecha), siguiendo una de las 256 reglas de Wolfram (0 a 255).

Los bordes son periódicos, o sea, la primera célula es vecina de la última y al revés.

## Estructura del proyecto

```
.
├── main.hs          -- programa principal: lee argumentos y lanza la simulación
├── Automata.hs      -- módulo con el registro Automata, la regla y paso :: Automata -> Automata
├── Simulacion.hs    -- módulo con la simulación usando la mónada State
├── Makefile
└── README.md
```

## Compilación y ejecución

Se necesita GHC (probado con la versión 9.10.3, instalada con GHCup) y los paquetes `mtl` y `random`. Si alguno no está instalado:

```
cabal update
cabal install --lib random
cabal install --lib mtl
```

Para compilar en Linux o macOS:

```
make
```

En Windows, si no se tiene `make`, se compila directamente con:

```
ghc -O2 -Wall main.hs -o prog
```

Esto genera el ejecutable `prog` (`prog.exe` en Windows). Para borrar los archivos compilados se usa `make clean`.

Para ejecutar (en Windows se usa `.\prog` en vez de `./prog`):

```
./prog <regla> <ancho> <generaciones>
```

El programa parte con una sola célula viva al centro (posición `ancho / 2`). Las células vivas se muestran con `#` y las muertas con un espacio.

Si se agrega `aleatorio` como cuarto argumento, la condición inicial se genera al azar:

```
./prog <regla> <ancho> <generaciones> aleatorio
```

Si la regla no está entre 0 y 255, o el ancho o las generaciones no son mayores a 0, el programa muestra un mensaje de error.

## Implementación

### 1. Modelo del autómata

El autómata se modela como un registro:

```haskell
data Automata = Automata
  { celdas     :: [Bool]
  , regla      :: Int
  , generacion :: Int
  }
```

- `celdas`: la fila de células, `True` es viva y `False` es muerta.
- `regla`: el número de la regla de Wolfram.
- `generacion`: el número de la generación actual (parte en 0 y aumenta en 1 con cada paso).

Una generación se calcula con la función `paso :: Automata -> Automata` del módulo `Automata.hs`.

### 2. Reglas de Wolfram

El número de la regla en binario (8 bits) dice el nuevo valor de la célula para cada una de las 8 vecindades posibles. Por ejemplo, para la regla 30, que en binario es `00011110`:

| Vecindad    | 111 | 110 | 101 | 100 | 011 | 010 | 001 | 000 |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- |
| Nuevo valor | 0   | 0   | 0   | 1   | 1   | 1   | 1   | 0   |

La idea que usamos es que la vecindad `(izq, centro, der)` también se puede leer como un número binario de 3 bits, que va de 0 (`000`) a 7 (`111`). Ese número es justo la posición del bit de la regla que hay que mirar. Por eso la función queda bien corta:

```haskell
nuevoValor :: Int -> Bool -> Bool -> Bool -> Bool
nuevoValor r izq centro der = testBit r indice
  where
    indice = 4 * aInt izq + 2 * aInt centro + aInt der
    aInt b = if b then 1 else 0
```

Por ejemplo, con la regla 30 y la vecindad `100`, el índice es 4 y el bit 4 de `00011110` es 1, así que la célula queda viva, igual que en la tabla.

### Bordes periódicos

Para tener los vecinos de todas las células a la vez, se arman dos listas desplazadas de la fila original:

- vecinos izquierdos: `last cs : init cs` (el último elemento pasa al inicio)
- vecinos derechos: `drop 1 cs ++ take 1 cs` (el primer elemento pasa al final)

Después se aplica la regla con `zipWith3` sobre las tres listas:

```haskell
paso :: Automata -> Automata
paso a = a { celdas = nuevas, generacion = generacion a + 1 }
  where
    cs        = celdas a
    izquierda = last cs : init cs
    derecha   = drop 1 cs ++ take 1 cs
    nuevas    = zipWith3 (nuevoValor (regla a)) izquierda cs derecha
```

Así la célula del borde izquierdo usa como vecina la del borde derecho y viceversa.

### 3. Ejecución del programa

`main.hs` lee los argumentos con `getArgs`, los convierte a número con `readMaybe` (para que no se caiga si se escribe algo que no es número), crea el autómata con una célula viva al centro y ejecuta la simulación.

## Puntos extra

### A. Condición inicial aleatoria

Con el argumento `aleatorio` se genera la fila inicial usando `System.Random`:

```haskell
gen <- newStdGen
let cs = take ancho (randoms gen) :: [Bool]
```

Cada célula tiene la misma probabilidad de partir viva o muerta, y cada ejecución da un resultado distinto.

### E. Simulación con la mónada State

En `Simulacion.hs` está la función `paso :: State Automata ()`, que no recibe ni devuelve el autómata, sino que modifica el estado con `modify`:

```haskell
paso :: State Automata ()
paso = modify A.paso
```

La simulación completa se hace con `forM_`. Como hay que imprimir cada generación, usamos `StateT Automata IO`, que es la mónada State con IO por debajo. En cada iteración se lee la fila con `gets`, se imprime con `liftIO` y se avanza un paso:

```haskell
simular :: Int -> StateT Automata IO ()
simular n = forM_ [1 .. n] $ \_ -> do
  fila <- gets mostrar
  liftIO (putStrLn fila)
  state (runState paso)
```

`state (runState paso)` sirve para ejecutar el `paso` de tipo `State` dentro de `StateT ... IO`. En `main` se parte la simulación con `evalStateT (simular gens) inicial`, así que el estado nunca se pasa a mano entre funciones: solo se entrega el autómata inicial una vez y el resto lo maneja la mónada.

## Ejemplos

Regla 90, ancho 31 y 8 generaciones (el ejemplo del enunciado):

```
$ ./prog 90 31 8
               #
              # #
             #   #
            # # # #
           #       #
          # #     # #
         #   #   #   #
        # # # # # # # #
```

Regla 30, ancho 31 y 16 generaciones. En la última fila se nota que los bordes son periódicos, porque el patrón que llega al borde izquierdo aparece por el lado derecho:

```
$ ./prog 30 31 16
               #
              ###
             ##  #
            ## ####
           ##  #   #
          ## #### ###
         ##  #    #  #
        ## ####  ######
       ##  #   ###     #
      ## #### ##  #   ###
     ##  #    # #### ##  #
    ## ####  ## #    # ####
   ##  #   ###  ##  ## #   #
  ## #### ##  ### ###  ## ###
 ##  #    # ###   #  ###  #  #
## ####  ## #  # #####  #######
```

Con condición inicial aleatoria (la salida cambia en cada ejecución):

```
$ ./prog 90 31 6 aleatorio
```

## Conclusiones

Con esta tarea pudimos ver que en Haskell un autómata celular queda bastante corto, porque la parte principal es aplicar una función a cada célula junto con sus vecinas, y eso se hace fácil con listas y `zipWith3`. Lo que más nos ayudó fue darnos cuenta de que la vecindad se puede leer como un número binario y usarla directamente como índice del bit de la regla, así no hubo que escribir los 8 casos a mano.

Con la mónada State vimos que se puede escribir la simulación de forma parecida a un programa imperativo (leer el estado, imprimir, avanzar) sin perder la pureza de las funciones, ya que la función `paso` del módulo `Automata` sigue siendo pura y la mónada solo se encarga de ir guardando el estado.
