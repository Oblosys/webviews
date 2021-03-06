module BorrowItUtils where

--import Data.GPS
import Database

lenderDistance Lender{_lenderCoords=(lat1,long1)} Lender{_lenderCoords=(lat2,long2)} = 300 {-
  distance (pt (latitude lat1) (longitude long1) Nothing Nothing) (pt (latitude lat2) (longitude long2) Nothing Nothing)
 -}
showDistance d | d < 100 = "< 100m"
               | d < 950  = show (round (d/100) :: Int) ++ "00m"
               | d < 10000 = show (truncate (d/1000) :: Int) ++ "," ++ show ((truncate (d/100) :: Int) `mod` 10) ++ "km"
               | otherwise = show (round (d/1000) :: Int) ++ "km"
 -- todo: use nicefloat here. now the x.xkm are truncated while the rest are rounded
                      