{-# LANGUAGE DeriveDataTypeable, PatternGuards, MultiParamTypeClasses, OverloadedStrings, TemplateHaskell, ImpredicativeTypes #-}
{-# LANGUAGE TypeOperators, TupleSections, FlexibleInstances, ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts, UndecidableInstances #-} -- For TaggedPresent instances.
module WebViewLibExp where
{- Module for experimenting with generic WebViews that will be put in WebViewLib.
   Keeping them here during development prevents having to recompile the library on every change. 
-}

import Prelude hiding ((.), id)           -- fclabels
import Control.Category ((.), id)         -- fclabels
import Data.Label                         -- fclabels
import Data.Generics
import Data.List
import Data.Function (on)
import Types
import ObloUtils
import Generics
import WebViewPrim
import WebViewLib
import BlazeHtml
import HtmlLib
import TemplateHaskell
import Control.Applicative
import Debug.Trace


class TaggedPresent tag args where
  taggedPresent :: tag -> args -> Html
  
  

data SortDefaultPresent = SortDefaultPresent deriving (Show,Eq,Typeable) -- this appears as a type arg, so we need Typeable

instance MapWebView db SortDefaultPresent
instance Initial SortDefaultPresent where
  initial = SortDefaultPresent

instance TaggedPresent SortDefaultPresent (Widget (SelectView db), Widget (SelectView db), [WebView db v]) where
  taggedPresent SortDefaultPresent (sortFieldSelect, sortOrderSelect, webViews) =
    (vList $ hStretchList [space, E $ "Sort" +++ nbsp, E $ present sortOrderSelect, E $ nbsp +++ "on" +++ nbsp, E $ present sortFieldSelect] 
              ! style ("color:white;margin: 4px 0px 4px 0px;" ++ gradientStyle Nothing "#101010" "#707070") 
            : intersperse hSep (map present webViews)
    ) ! style "width: 100%"        
   where hSep = div_ ! style "width: 100%; height:1px; background-color: black; margin: 5px 0px 5px 0px" $ noHtml



data SortView tag db v = 
  SortView tag (Widget (SelectView db)) (Widget (SelectView db)) [WebView db v]  
    deriving (Eq, Show, Typeable)

-- no derive Initial/MapWebView functions for parameterized types yet, so we specify manual instances
instance Initial tag => Initial (SortView tag db v) where
  initial = SortView initial initial initial initial
instance (MapWebView db tag, IsView db v) => MapWebView db (SortView tag db v) where
  mapWebView (SortView tag wv1 wv2 wvs)  = SortView <$> mapWebView tag <*> mapWebView wv1 <*> mapWebView wv2 <*> mapWebView wvs 

instance Storeable db (SortView tag db v)

mkSortView :: (Typeable db, IsView db v) => [(String, a->a->Ordering)] -> (a-> WebViewM db (WebView db v)) -> [a] -> WebViewM db (WebView db (SortView SortDefaultPresent db v))
mkSortView = mkSortViewEx SortDefaultPresent

mkSortViewEx :: ( Typeable db, IsView db v
                , TaggedPresent tag (Widget (SelectView db), Widget (SelectView db), [WebView db v])
                , Eq tag, Show tag, Typeable tag, Initial tag, MapWebView db tag) =>
              tag -> [(String, a->a->Ordering)] -> (a-> WebViewM db (WebView db v)) -> [a] ->
              WebViewM db (WebView db (SortView tag db v))
mkSortViewEx tag namedSortFunctions mkResultWV results = mkWebView $
  \vid oldView@(SortView _ sortFieldSelectOld sortOrderSelectOld _) ->
    do { let sortField = getSelection sortFieldSelectOld
       ; let sortOrder = getSelection sortOrderSelectOld
       ; let (sortFieldNames, sortFunctions) = unzip namedSortFunctions
       ; sortFieldSelect <- mkSelectView sortFieldNames sortField True
       ; sortOrderSelect <- mkSelectView ["Ascending", "Descending"] sortOrder True
       
       ; resultsWVs <- sequence [ fmap (r,) $ mkResultWV r | r <- results ]
       ; sortedResultViews <- case results of
                                [] -> return [] -- fmap singleton $ mkHtmlView $ "No results"
                                _  -> return $ map snd $ (if sortOrder == 0 then id else reverse) $ 
                                                         sortBy (sortFunctions !! sortField `on` fst) $ resultsWVs
    
       ; return $ SortView tag sortFieldSelect sortOrderSelect sortedResultViews
       }

instance TaggedPresent tag (Widget (SelectView db), Widget (SelectView db), [WebView db v]) => Presentable (SortView tag db v) where
  present (SortView tag sortFieldSelect sortOrderSelect webViews) = taggedPresent tag (sortFieldSelect, sortOrderSelect, webViews)

data SearchView db v = 
  SearchView String (Widget (TextView db)) (Widget (Button db)) (WebView db v) String 
    deriving (Eq, Show, Typeable)

instance IsView db v => Initial (SearchView db v) where
  initial = SearchView initial initial initial initial initial
instance IsView db v => MapWebView db (SearchView db v) where
  mapWebView (SearchView a b c d e) = SearchView <$> mapWebView a <*> mapWebView b <*> mapWebView c <*> mapWebView d <*> mapWebView e

instance Storeable db (SearchView db v)


-- todo: different languages 
mkSearchView label argName resultsf = mkWebView $
  \vid oldView@( SearchView _ _ _ _ _) ->
    do { args <- getHashArgs
       ; let searchTerm = case lookup argName args of 
                            Nothing    -> ""
                            Just term -> term 
       ; searchField <- mkTextField searchTerm
       ; searchButton <- mkButtonWithClick "Search" True $ const ""
       ; results <- resultsf searchTerm
       ; return $ SearchView label searchField searchButton results $
                  jsScript $
                    let navigateAction = "setHashArg('"++argName++"', "++jsGetWidgetValue searchField++");"
                    in  [ onClick searchButton navigateAction
                        , onSubmit searchField navigateAction
                        -- change background color for testing bug
                        --, "$(" ++ (jsGetElementByIdRef $ mkViewRef (getViewId searchField)) ++ ").css('background-color','blue')"
                        ]
       }
instance IsView db v => Presentable (SearchView db v) where
  present (SearchView label searchField searchButton wv script) =
      (hStretchList [E $ toHtml label +++ nbsp, Stretch $ with [style "width: 100%;"] (present searchField), E nbsp, E $ present searchButton]) +++
      present wv
      +++ mkScript script

------ Editable Properties (will move to lib)
{-      
-- An encapsulated database update that can be part of a webview. 
data Function a b = Function (a -> b)


instance Initial (Function a b) where
  initial = Function $ error "Initial Function"
  
-- never equal, so no incrementality
instance Eq (Function a b) where
  _ == _ = False
  
instance Show (Function a b) where
  show _ = "Function"
-}
-- non-optimal way to show editable properties. The problem is that the update specified is not a view update but a database update.
data Property db a = EditableProperty (Either Html (PropertyWidget db))
                   | StaticProperty Html deriving (Eq, Show)

-- We want to put properties in a list, so an extra parameter for the widget is not an option.
-- We could use an existential, but then deriving instances won't work anymore, so for now we use an explicit sum type.
data PropertyWidget db = PropertyTextView (Widget (TextView db))
                       | PropertySelectView (Widget (SelectView db)) deriving (Eq, Show)
                    
  
instance Initial (Property db a) where
  initial = StaticProperty initial

deriveMapWebView ''PropertyWidget 

-- extra arg, so no derive
instance MapWebView db (Property db a) where
  mapWebView (EditableProperty a) = EditableProperty <$> mapWebView a 
  mapWebView (StaticProperty a) = StaticProperty <$> mapWebView a 
  

{- The update is a database update, but it would be better to be able to specify a view update, since we don't 
want to commit all textfields immediately to the database. Maybe save could be part of the edit monad? (but then do we need
to save again after performing the viewEdit in save?) or we could add an edit action to text fields (not the commit action, but
a blur action) -}
-- not a web view, but it is an instance of Presentable
mkEditableProperty :: (Show v, Typeable v) => 
                      ViewId -> Bool -> (v :-> Maybe a) -> (a :-> p) ->
                      (p -> String) -> (String -> Maybe p) -> (p -> Html) -> a -> 
                      WebViewM db (Property db a)
mkEditableProperty vid editing objectLens valueLens presStr parseStr pres orgObj =
 do { eValue <- if editing
                then fmap (Right . PropertyTextView) $ mkTextFieldWithChange (presStr $ get valueLens orgObj) $ \str ->
                       viewEdit vid $ \v ->
                         case get objectLens v of
                           Nothing -> v
                           Just o  -> case parseStr str of
                                        Nothing -> trace ("Parse error for " ++ show str) v
                                        Just p' -> let v' = set objectLens (Just $ set valueLens p' o) v
                                                   in {- trace ("Setting "++show vid++" to " ++ show v') $ -} v'
                else return $ Left $ pres $ get valueLens orgObj 
    ; return $ EditableProperty eValue
    }

mkEditableSelectProperty :: (Show v, Typeable v) => ViewId -> Bool -> (v :-> Maybe a) -> (a :-> p) ->
                            (p -> String) -> (p -> Html) -> [p] -> a ->
                            WebViewM db (Property db a)
mkEditableSelectProperty vid editing objectLens valueLens presStr pres propVals orgObj =
 do { eValue <- if editing
                then let propValStrs = map presStr propVals
                         selection = get valueLens orgObj 
                         -- select index based on string representation, so we don't need Eq on p. (if p's have same string repr. the user won't be able to distinguish anyway)
                         selectionIx = case elemIndex (presStr selection) propValStrs of
                                         Just i  -> i
                                         Nothing -> 0 -- if the property is not in the list, we select the first one 
                                                      -- (this can happen if the list does not contain all values)
                     in  fmap (Right . PropertySelectView) $ mkSelectViewWithChange propValStrs selectionIx True $ \sel -> 
                           viewEdit vid $ \v ->
                             case get objectLens v of
                               Nothing -> v
                               Just o  -> if (sel >= 0 && sel < length propVals) 
                                          then set objectLens (Just $ set valueLens (propVals!!sel) o) v
                                          else error $ "Internal error: mkEditableSelectProperty: index " ++ show sel ++
                                                       " out of bounds for: " ++ show (map presStr propVals)
                else return $ Left $ pres $ get valueLens orgObj 
    ; return $ EditableProperty eValue
    }

mkStaticProperty :: (a :-> p) -> (p -> Html) -> a -> WebViewM db (Property db a) -- monadic only to have behave similar to
mkStaticProperty lens pres obj = return $ StaticProperty $ pres $ get lens obj  -- mkEditbleProperty (maybe not necessary)

instance Presentable (Property db a) where
  present (StaticProperty htmlStr)             = toHtml htmlStr
  present (EditableProperty (Left htmlStr))    = toHtml htmlStr
  present (EditableProperty (Right (PropertyTextView textField)))     = present textField
  present (EditableProperty (Right (PropertySelectView selectField))) = present selectField

instance Storeable db (Property db a)

presentEditableProperties :: [(String, Property db a)] -> Html            
presentEditableProperties namedProps =
  table $ sequence_ [ tr $ sequence_ [ td $ with [style "font-weight: bold"] $ toHtml propName, td $ nbsp +++ ":" +++ nbsp
                                     , td $ present prop] 
                    | (propName, prop) <- namedProps
                    ]

------ End of editable Properties
