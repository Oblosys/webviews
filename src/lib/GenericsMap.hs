module GenericsMap where

import Types
import ObloUtils

import Data.Maybe
import Data.Map (Map)
import qualified Data.Map as Map 
import Data.IntSet (IntSet)
import qualified Data.IntSet as IntSet 
import qualified Data.IntMap as IntMap 
import Debug.Trace


getAllIds :: forall db . WebView db -> [Id]
getAllIds rootView = snd $ mapWebView (getAllIdsWV, getAllIdsWd, noWidgetUpdates, True) rootView [] 
  where getAllIdsWV :: [Id] -> WebView db -> (WebView db, [Id])
        getAllIdsWV ids wv@(WebView _ sid id _ _) = (wv, sid:id:ids)
        getAllIdsWd ids wd@(Widget sid id _)          = (wd, sid:id:ids)

clearIds :: forall db . WebView db -> WebView db
clearIds rootView = fst $ mapWebView (clearIdsWV, clearIdsWd, noWidgetUpdates, True) rootView () 
  where clearIdsWV :: () -> WebView db -> (WebView db, ())
        clearIdsWV _ wv@(WebView vid _ _ mkF v) = (WebView vid noId noId mkF v, ())
        clearIdsWd _ wd@(Widget _ _ w)          = (Widget noId noId w, ())

assignIdsFromList :: forall db . [Id] -> WebView db -> WebView db
assignIdsFromList allIds rootView =
  let assigned = fst $ mapWebView (assignIdsWV, assignIdsWd, noWidgetUpdates, True) rootView freeIds
  in {- trace (if [] /= filter (==Id (-1))(getAll assigned :: [Id]) then show assigned else "ok") $ -} assigned
 where usedIds = IntSet.fromList $ map unId $ filter (/= noId) $ allIds 
       freeIds = (IntSet.fromList $ [0 .. length allIds - 1]) `IntSet.difference` usedIds

       assignIdsWV :: IntSet -> WebView db -> (WebView db, IntSet)
       assignIdsWV state (WebView vi sid id mkF v) = (WebView vi sid' id' mkF v, state'')
        where (sid',state') = mkId state sid
              (id',state'') = mkId state' id
       
       assignIdsWd state (Widget sid id w) = (Widget sid' id' w, state'')
        where (sid',state') = mkId state sid
              (id',state'') = mkId state' id

mkId ids (Id i) = if (i == -1) 
                         then if IntSet.null ids 
                                         then error "Internal error: assign Id, empty id list"
                                         else let (newId, ids') = IntSet.deleteFindMin ids 
                                              in  (Id newId, ids') 
                                    else (Id i, ids)       

getTopLevelWebViews :: WebView db -> [WebView db]
getTopLevelWebViews wv = [w | WebViewNode w <- getTopLevelWebNodes wv]

-- get top-level WebNodes (WebViews and widgets), not including the WebView itself
getTopLevelWebNodes :: WebView db -> [WebNode db]
getTopLevelWebNodes (WebView _ _ _ _ v) = map snd $ getWebNodesAndViewIds False v

mkWebNodeMap :: WebView db -> WebNodeMap db
mkWebNodeMap wv = Map.fromList $ getWebNodesAndViewIds True wv

mkViewMap :: WebView db -> ViewMap db
mkViewMap wv = Map.fromList $ [ (vid, wv) | (vid, WebViewNode wv) <- getWebNodesAndViewIds True wv ]

getLabelViewByViewId :: ViewId -> WebView db -> LabelView db
getLabelViewByViewId i wv =
  case getAnyWidgetById i wv of
    LabelWidget x -> x
    _             -> error $ "internal error: widget with id " ++ show i ++ " is not a LabelView" 

getTextViewByViewId :: ViewId -> WebView db -> TextView db
getTextViewByViewId i wv =
  case getAnyWidgetById i wv of
    TextWidget x -> x
    _              -> error $ "internal error: widget with id " ++ show i ++ " is not a TextView" 

getRadioViewByViewId :: ViewId -> WebView db -> RadioView db
getRadioViewByViewId i wv =
  case getAnyWidgetById i wv of
    RadioViewWidget x -> x
    _                 -> error $ "internal error: widget with id " ++ show i ++ " is not a RadioView" 

getSelectViewByViewId :: ViewId -> WebView db -> SelectView db
getSelectViewByViewId i wv =
  case getAnyWidgetById i wv of
    SelectViewWidget x -> x
    _                  -> error $ "internal error: widget with id " ++ show i ++ " is not a SelectView" 


getButtonByViewId :: ViewId -> WebView db -> Button db
getButtonByViewId i wv =
  case getAnyWidgetById i wv of
    ButtonWidget x -> x
    _              -> error $ "internal error: widget with id " ++ show i ++ " is not a Button" 

getJSVarByViewId :: ViewId -> WebView db -> JSVar db
getJSVarByViewId i wv =
  case getAnyWidgetById i wv of
    JSVarWidget x -> x
    _             -> error $ "internal error: widget with id " ++ show i ++ " is not a JSVar" 

getEditActionByViewId :: ViewId -> WebView db -> EditAction db
getEditActionByViewId i wv =
  case getAnyWidgetById i wv of
    EditActionWidget x -> x
    _             -> error $ "internal error: widget with id " ++ show i ++ " is not an EditAction" 

getWebViewById :: ViewId -> WebView db -> WebView db
getWebViewById i wv = 
  case getWebNodeById "getWebViewById" i wv of
    (WebViewNode wv) -> wv
    _                -> error $ "internal error: webnode with id " ++ show i ++ " is not a WebViewNode"

getAnyWidgetById :: ViewId -> WebView db -> AnyWidget db
getAnyWidgetById i wv = 
  case getWebNodeById "getWebViewById" i wv of
    (WidgetNode _ _ _ wd) -> wd
    _                -> error $ "internal error: webnode with id " ++ show i ++ " is not a WidgetNode"

getWebNodeById :: String -> ViewId -> WebView db -> WebNode db
getWebNodeById callerTag i wv = 
  case [ wn | (vid, wn) <- getWebNodesAndViewIds True wv, vid == i ] of
    [b] -> b
    []  -> error $ "internal error: getWebNodeById (called by "++callerTag++"): no webnode with id " ++ show i
    _   -> error $ "internal error: getWebNodeById (called by "++callerTag++"): multiple webnode with id " ++ show i

getWebNodesAndViewIds :: forall db v . MapWebView db v => Bool -> v -> [(ViewId, WebNode db)]
getWebNodesAndViewIds recursive v = snd $ mapWebView (getWebNodesAndViewIdsWV, getWebNodesAndViewIdsWd, noWidgetUpdates, recursive) v []
 where getWebNodesAndViewIdsWV :: [(ViewId, WebNode db)] -> WebView db -> (WebView db, [(ViewId, WebNode db)])
       getWebNodesAndViewIdsWV state wv@(WebView vi _ _ _ _) = (wv, (vi, WebViewNode wv):state)

       getWebNodesAndViewIdsWd :: MapWebView db (w db) => [(ViewId, WebNode db)] -> Widget (w db) -> (Widget (w db), [(ViewId, WebNode db)])
       getWebNodesAndViewIdsWd state wd@(Widget sid id w) = (wd, widgetNode ++  state) 
         where widgetNode :: [(ViewId, WebNode db)]
               widgetNode = case widgetToAnyWidget w of
                              Nothing       -> error "Generics.getWebNodesAndViewIds Widget with non-widget child."
                              Just (vid,a)  -> [(vid, WidgetNode vid sid id a)]

widgetToAnyWidget :: MapWebView db w => w -> (Maybe (ViewId,AnyWidget db))
widgetToAnyWidget w = snd $ mapWebView (inert,inert,widgetUpdates,False {- has no effect -}) w Nothing 
 where widgetUpdates :: WidgetUpdates db (Maybe (ViewId, AnyWidget db))
       widgetUpdates = WidgetUpdates labelViewUpd textViewUpd radioViewUpd selectViewUpd buttonUpd jsVarUpd editActionUpd
                                     
       labelViewUpd s w  = (w, Just (getViewId w, LabelWidget w))
       textViewUpd s w   = (w, Just (getViewId w, TextWidget w))
       radioViewUpd s w  = (w, Just (getViewId w, RadioViewWidget w))
       selectViewUpd s w = (w, Just (getViewId w, SelectViewWidget w))
       buttonUpd s w     = (w, Just (getViewId w, ButtonWidget w))
       jsVarUpd s w      = (w, Just (getViewId w, JSVarWidget w))
       editActionUpd s w = (w, Just (getViewId w, EditActionWidget w))

replaceWebViewById :: forall db . ViewId -> WebView db -> WebView db -> WebView db
replaceWebViewById vid newWV rootView = fst $ mapWebView (replaceWebViewByIdWV, replaceWebViewByIdWd, noWidgetUpdates, True) rootView ()
 where replaceWebViewByIdWV :: () -> WebView db -> (WebView db, ())
       replaceWebViewByIdWV state wv@(WebView vi sid id mkF v) = (if vid == vi then newWV else wv, state)

       replaceWebViewByIdWd state wd = (wd, state)


substituteIds :: forall db . [(Id, Id)] -> WebView db -> WebView db
substituteIds subs rootView = fst $ mapWebView (substituteIdsWV, substituteIdsWd, noWidgetUpdates, True) rootView ()
 where substituteIdsWV :: () -> WebView db -> (WebView db, ())
       substituteIdsWV state (WebView vi sid id mkF v) = (WebView vi (substituteId sid) (substituteId id) mkF v, state)
       
       substituteIdsWd state (Widget sid id w) = (Widget (substituteId sid) (substituteId id) w, state)
       
       subsMap = IntMap.fromList $ map (\(Id i1, Id i2) -> (i1,i2)) subs
       
       substituteId id@(Id i) = case IntMap.lookup i subsMap of
                                  Nothing  -> id
                                  Just i' -> Id i'

type Updates = Map ViewId String  -- maps id's to the string representation of the new value

--           
-- TODO: fix s and v param order and maybe make MapWebView instances easier by removing arg
--       and fix applyUpdates and getWebNodesAndViewIds since their params can probably be curried then
-- TODO: profile

-- TODO: make TH generation for MapWebView instances

-- TODO: take widgets out of the map. doesn't really add anything as they won't appear without a wrapping Widget
-- TODO: use anywidget type in widget? There doesn't seem to be a need for different types
-- TODO: make lenses for WebViews

-- TODO: when we completely remove the old syb generics, remove Data and Typeable contexts where possible


-- update the datastructure at the id's in Updates 
applyUpdates :: forall db d . Updates -> WebView db -> WebView db
applyUpdates updates rootView = fst $ mapWebView (applyUpdatesWV, applyUpdatesWd, widgetUpdates, True) rootView ()
 where applyUpdatesWV :: () -> WebView db -> (WebView db, ())
       applyUpdatesWV state wd = (wd, state)
       applyUpdatesWd state wd = (wd, state)
       widgetUpdates = WidgetUpdates labelViewUpd textViewUpd radioViewUpd selectViewUpd buttonUpd jsVarUpd editActionUpd
                                     
       labelViewUpd      = inert
       textViewUpd s w   = mkWidgetUpdate s w (\v -> w{getTextStrVal=v})            id
       radioViewUpd s w  = mkWidgetUpdate s w (\v -> w{getRadioSelection=v})  $ unsafeRead ("Generics.replace.radioViewUpd at "++(show $ getViewId w))
       selectViewUpd s w = mkWidgetUpdate s w (\v -> w{getSelectSelection=v}) $ unsafeRead ("Generics.replace.selectViewUpd at "++(show $ getViewId w))
       buttonUpd         = inert 
       jsVarUpd s w      = mkWidgetUpdate s w (\v -> w{getJSVarValue_=v})        id
       editActionUpd     = inert 

       mkWidgetUpdate :: HasViewId w => s -> w -> (a -> w) -> (String -> a) -> (w,s) 
       mkWidgetUpdate w upd parse = undefined -- case Map.lookup (getViewId w) updates of
--                                      Nothing  -> w
--                                      Just str -> upd (parse str)
                                      