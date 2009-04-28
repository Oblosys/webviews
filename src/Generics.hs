{-# OPTIONS -fglasgow-exts #-}
module Generics where

import Types

import Data.Generics
import Data.Map (Map)
import qualified Data.Map as Map 
import Data.IntSet (IntSet)
import qualified Data.IntSet as IntSet 

-- Generics


data Tree = Bin Tree Tree | Leaf Char deriving (Show, Data, Typeable)

mytree = Bin (Bin (Leaf 'a') (Leaf 'b')) (Leaf 'c')

mkViewMap :: WebView -> ViewMap
mkViewMap wv = let wvs = getAll wv
                    in  Map.fromList [ (i, wv) | wv@(WebView i _ _ _ _) <- wvs]

-- webviews are to coarse for incrementality. We also need buttons, eints etc. as identifiable entities
-- making these into webviews does not seem to be okay. Maybe a separate class is needed
-- For now, we use a TreeMap for this.

data WebNode = WebViewNode WebView
             | WidgetNode  Id Id AnyWidget
               deriving (Typeable, Data)

data AnyWidget = EIntWidget EInt 
               | EStringWidget EString 
               | ButtonWidget Button  
                 deriving (Eq, Typeable, Data)
{-
-- mkWebMap :: WebView -> [WebNodeViewMap
mkWebMap :: Data d => d -> [(Id, WebNode)]
mkWebMap x = everything (++) ([] `mkQ`  (\w@(WebView vwId sid id _ _) -> [(id, WebViewNode w)]) 
                                 `extQ` (\x -> [(getIntId x, EIntNode x)])
                                 `extQ` (\x -> [(getStrId x, EStringNode x)])
                                 `extQ` (\x -> [(getButtonId x, ButtonNode x)])
                             ) x
-}
getTopLevelWebNodes :: WebView -> [WebNode]
getTopLevelWebNodes (WebView _ _ _ _ v) =
  everythingTopLevel (Nothing `mkQ`  (\w@(WebView vwId sid id _ _) -> Just $ WebViewNode w) 
                              `extQ` (\w@(Widget stbid id x@(EInt _ _))   -> Just $ WidgetNode stbid id (EIntWidget x))
                              `extQ` (\w@(Widget stbid id x@(EString _ _)) -> Just $ WidgetNode stbid id (EStringWidget x))
                              `extQ` (\w@(Widget stbid id x@(Button _ _))   -> Just $ WidgetNode stbid id (ButtonWidget x))
                     ) v             -- TODO can we do this bettter?
  
-- lookup the view id and if the associated view is of the desired type, return it. Otherwise
-- return initial
getOldView :: (Initial v, Typeable v) => ViewId -> ViewMap -> v
getOldView vid viewMap = 
  case Map.lookup vid viewMap of
    Nothing              -> initial
    Just (WebView _ _ _ _ aView) -> case cast aView of
                                  Nothing      -> initial
                                  Just oldView -> oldView

getAll :: (Data a, Data b) => a -> [b]
getAll = listify (const True)

getTopLevelWebViews :: Data a => a -> [WebView]
getTopLevelWebViews wv = everythingTopLevel (Nothing `mkQ` Just) wv
-- the type sig specifies the term type


-- is everythingBut, but not on the root (not used now)
everythingBelow :: Data r => GenericQ (Maybe r) -> GenericQ [r]
everythingBelow f x = foldl (++) [] (gmapQ (everythingTopLevel f) x)

-- TODO: this name is wrong
-- get all non-nested descendents of a type
-- Eg. everythingBelow () (X (T_1 .. (T_2 .. (T_3 ..) ..)) (T_4)) = [T_1,T_2,T_4]
everythingTopLevel :: Data r => GenericQ (Maybe r) -> GenericQ [r]
everythingTopLevel f x = case f x of
                      Just x  -> [x]
                      Nothing -> foldl (++) [] (gmapQ (everythingTopLevel f) x)

getWebViewContainingId :: Id -> WebView -> Maybe WebView
getWebViewContainingId (Id i) wv = 
  case somethingAcc Nothing (Nothing `mkQ` Just) (Nothing `mkQ` isId) wv of
    Just (_, Just wv') -> Just wv'
    Just (_, Nothing)  -> Nothing -- not called on a webview
    Nothing -> Nothing -- id not found
  where isId (Id i') = if i == i' then Just i' else Nothing

somethingAcc :: (Data a, Data r) => a -> GenericQ (Maybe a) -> GenericQ (Maybe r) -> GenericQ (Maybe (r,a))
somethingAcc a fa f x = let a' = case fa x of 
                                   Nothing -> a
                                   Just a' -> a'
                        in  case f x of
                              Just x  -> Just (x,a')
                              Nothing -> foldl orElse Nothing (gmapQ (somethingAcc a' fa f) x)

{-
everythingBut :: Data a 
 => GenericQ Bool
 -> (forall a. Data a => a -> r) 
 -> a -> r 
everythingBut q f x = {- if q x then [x] else -} foldl (++) [] (gmapQ (everythingBut q f) x)
-}

-- number all Id's in the argument data structure uniquely
--assignIds :: Data d => d -> d

assignIds x = let (x', _,_,_) = assignIdz x in x'
                  
assignIdz x = (snd $ everywhereAccum assignId freeIds x, allIds, usedIds, freeIds)
 where allIds = getAll x :: [Id]
       usedIds = IntSet.fromList $ map unId $ filter (/= noId) $ allIds 
       freeIds = (IntSet.fromList $ [0 .. length allIds - 1]) `IntSet.difference` usedIds
       
       
assignId :: Data d => IntSet -> d -> (IntSet,d)
assignId = mkAccT $ \ids (Id id) -> if (id == -1) 
                                    then if IntSet.null ids 
                                         then error "Internal error: assign Id, empty id list"
                                         else let (newId, ids') = IntSet.deleteFindMin ids 
                                              in  (ids', Id newId) 
                                    else (ids, Id id)


type Updates = Map Id String  -- maps id's to the string representation of the new value

-- update the datastructure at the id's in Updates 
replace :: Data d => Updates -> d -> d
replace updates v = (everywhere $ extT (mkT (replaceEString updates))  (replaceEInt updates)) v

replaceEString :: Updates -> EString -> EString
replaceEString updates x@(EString i _) =
  case Map.lookup i updates of
    Just str -> (EString i str)
    Nothing -> x

replaceEInt :: Updates -> EInt -> EInt
replaceEInt updates x@(EInt i _) =
  case Map.lookup i updates of
    Just str -> (EInt i (read str))
    Nothing -> x

replaceWebViewById :: (ViewId) -> WebView -> WebView -> WebView
replaceWebViewById i wv rootView =
 (everywhere $ mkT replaceWebView) rootView
 where replaceWebView wv'@(WebView i' _ _ _ _) = if i == i' then wv else wv' 
--getWebViews x = listify (\(WebView i' :: WebView) -> True) x 

getButtonById :: Data d => Id -> d -> Button
getButtonById i view = 
  case listify (\(Button i' _) -> i==i') view of
    [b] -> b
    []  -> error $ "internal error: no button with id "++show i
    _   -> error $ "internal error: multiple buttons with id "++show i

--

everywhereAccum :: Data d => (forall b . Data b => a -> b -> (a,b)) -> a -> d -> (a,d)
everywhereAccum f acc a =
 let (acc'',r) = gfoldl k z a
 in  f acc'' r  
 where k (acc',a2b) a = let (acc'',a') = everywhereAccum f acc' a
                            b = a2b a'
                        in  (acc'', b)
       z e = (acc, e)

gReplace :: forall a d . (Typeable a, Data d) => [a] -> d -> ([a],d)
gReplace = mkAccT $ \(i:is) _ -> (is,i)

number :: Data d => Int -> d -> (Int,d)
number  = mkAccT $ \acc _ -> (acc+1, acc)

mkAccT :: forall a b acc . (Typeable acc, Typeable a, Data b) => (acc -> a -> (acc,a)) -> (acc -> b -> (acc,b))
mkAccT f = case cast f  of -- can we do this without requiring Typeable acc?
                  Just g  -> g 
                  Nothing -> \acc b -> (acc,b)


getWebViewById i view = 
  case listify (\(WebView i' _ _ _ _) -> i==i') view of
    [b] -> b
    []  -> error $ "internal error: no button with id "
    _   -> error $ "internal error: multiple buttons with id "

getEStringByIdRef :: Data v => IdRef -> v -> Maybe String
getEStringByIdRef (IdRef i) view =
  something (Nothing `mkQ` (\(EString (Id i') str) -> if i == i' then Just str else Nothing)) view