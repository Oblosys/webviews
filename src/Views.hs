{-# OPTIONS -fglasgow-exts #-}
module Views where

import Control.Monad.Trans
import Data.List
import Text.Html hiding (image)
import qualified Text.Html as Html
import Data.Generics
import Data.Char
import Data.Map (Map)
import qualified Data.Map as Map 
import Data.IntMap (IntMap)
import qualified Data.IntMap as IntMap 
import Data.Tree
import Debug.Trace

import Types
import Database
import Generics

-- IDEA: use phantom types to enforce type structure on views
--       GADTs?
-- TODO: figure out load stuff
--       use a monad for auto handling listeners to database


instance Storeable WebView where
  save (WebView _ _ _ _ v) =
    let topLevelWebViews = getTopLevelWebViews v
    in  foldl (.) id $ save v : map save topLevelWebViews

  
-- first save self, then children
-- TODO: does this order matter?

-- should be with TH stuff for Database, like DatabaseUtils or something
instance Initial VisitId where initial = VisitId (-1)

instance Initial PigId where initial = PigId (-1)



mkViewEdit i f = 
  ViewEdit i $ \(WebView vi si i lv v) -> WebView vi si i lv $ applyIfCorrectType f v


applyIfCorrectType :: (Typeable y, Typeable x) => (y -> y) -> x -> x
applyIfCorrectType f x = case cast f of 
                           Just fx -> fx x
                           Nothing -> x


-- the view matching on load can be done explicitly, following structure and checking ids, or
-- maybe automatically, based on id. Maybe extra state can be in a separate data structure even,
-- like in Proxima
mkRootView :: User -> Database -> Int -> ViewMap -> WebView
mkRootView user db sessionId viewMap = 
  --mkPigView 3 (PigId 1) 5 user db viewMap 
  mkVisitView sessionId (VisitId 1) user db viewMap

mkWebView :: (Presentable v, Storeable v, Initial v, Show v, Eq v, Data v) =>
             ViewId -> (User -> Database -> ViewMap -> ViewId -> v) -> User -> Database -> ViewMap -> WebView
mkWebView vid wvcnstr user db viewMap = loadView user db viewMap $
  WebView vid noId noId wvcnstr initial

loadView user db viewMap (WebView vid si i f _) = (WebView vid si i f (f user db viewMap vid))



data VisitView = 
  VisitView VisitId Int User (Widget EString) (Widget EString) (Widget RadioView) (Widget Button) 
           (Widget Button) (Widget Button) [PigId] [String] WebView [WebView]
    deriving (Eq, Show, Typeable, Data)

-- todo: doc edits seem to reset viewed pig nr.
mkVisitView sessionId i = mkWebView (ViewId 0) $
  \user db viewMap vid -> 
  let (VisitView _ _ _ _ _ oldViewedPig _ _ _ _ _ _ mpigv) = getOldView vid viewMap
      (Visit visd zipcode date pigIds) = unsafeLookup (allVisits db) i
      viewedPig = constrain 0 (length pigIds - 1) $ getSelection oldViewedPig
      pignames = map (pigName . unsafeLookup (allPigs db)) pigIds
  in  VisitView i sessionId user (estr (ViewId 1000) zipcode) (estr (ViewId 1001) date) (radioView  (ViewId 1002) ["1","2","3","4"] viewedPig) 
                (button (ViewId 1003) "previous" (previous (ViewId 0))) 
                (button (ViewId 1005) "next" (next (ViewId 0)))
                (button (ViewId 1007) "add" (addPig visd)) pigIds pignames
-- todo: check id's
             {-   (if null pigIds -- remove guard for weird hanging exception (after removing last pig)
                    then Nothing
                    else Just $ mkPigView viewedPig (pigIds !! viewedPig) db viewMap
                   )-}
                (if user == Nothing then (mkLoginView user db viewMap) 
                                    else (mkLogoutView user db viewMap))
                [mkPigView i pigId viewedPig user db viewMap | (pigId,i) <- zip pigIds [0..]]
 where -- next and previous may cause out of bounds, but on reload, this is constrained
       previous i = mkViewEdit i $
         \(VisitView vid sid us zipCode date viewedPig b1 b2 b3 pigs pignames loginv mSubview) ->
         VisitView vid sid us zipCode date (setSelection (getSelection viewedPig-1) viewedPig) b1 b2 b3 pigs pignames loginv mSubview

       next i = mkViewEdit i $
         \(VisitView vid sid us zipCode date viewedPig b1 b2 b3 pigs pignames loginv mSubview) ->
         VisitView vid sid us zipCode date (setSelection (getSelection viewedPig+1) viewedPig) b1 b2 b3 pigs pignames loginv mSubview

       addPig i = DocEdit $ addNewPig i 

addNewPig vid db =
  let ((Pig newPigId _ _ _ _), db') = newPig vid db      
  in  (updateVisit vid $ \v -> v { pigs = pigs v ++ [newPigId] }) db'

instance Presentable VisitView where
  present (VisitView vid sid us zipCode date viewedPig b1 b2 b3 pigs pignames loginoutView subviews) =
        withBgColor (Rgb 235 235 235) $
        (case us of
           Nothing -> p << present loginoutView 
           Just (_,name) -> p << stringToHtml ("Hello "++name++".") +++ present loginoutView) +++
        
        (p <<"Visit at "+++ present zipCode +++" on " +++ present date +++ 
          "           (session# "+++show sid+++")")
    +++ p << ("Visited "++ show (length pigs) ++ " pig" ++ pluralS (length pigs) ++ ": " ++
              listCommaAnd pignames)
    +++ p << ((if null pigs then stringToHtml $ "Not viewing any pigs" 
               else "Viewing pig nr. " +++ present viewedPig +++ "   ")
           +++ present b1 +++ present b2)
    +++ withPad 15 0 0 0 {- (case mSubview of
               Nothing -> stringToHtml "no pigs"
               Just pv -> present pv) -}
            (hList $ map present subviews ++ [present b3] )

instance Storeable VisitView where
  save (VisitView vid sid us zipCode date _ _ _ _ pigs pignames _ _) db =
    updateVisit vid (\(Visit _ _ _ pigIds) ->
                      Visit vid (getStrVal zipCode) (getStrVal date) pigIds)
                    db

instance Initial VisitView where
  initial = VisitView initial initial initial initial initial initial initial initial initial initial initial initial initial
                       

data PigView = PigView PigId (Widget Button) Int Int (Widget EString) [Widget RadioView] (Either Int String) 
               deriving (Eq, Show, Typeable, Data)

mkPigView pignr i viewedPig = mkWebView (ViewId $ 10+pignr) $ 
      \user db viewMap vid ->
  let (Pig pid vid name [s0,s1,s2] diagnosis) = unsafeLookup (allPigs db) i
  in  PigView pid (button (ViewId $ pignr*10000 + 10000) "remove" ( ConfirmEdit ("Are you sure you want to remove pig "++show pignr++"?") $ 
                                   removePigAlsoFromVisit pid vid)) 
              viewedPig pignr (estr (ViewId $ pignr*10000 + 10001) name) 
                [ radioView (ViewId $ pignr*10000 + 10002) ["Roze", "Grijs"] s0
                , radioView (ViewId $ pignr*10000 + 10003) ["1", "2", "3"] s1
                , radioView (ViewId $ pignr*10000 + 10004) ["Ja", "Nee"] s2
                ] diagnosis
 where -- need db support for removal and we need parent
       removePigAlsoFromVisit pid vid =
         DocEdit $ removePig pid . updateVisit vid (\v -> v { pigs = delete pid $ pigs v } )  

instance Presentable PigView where
  present (PigView pid b _ pignr name [] diagnosis) = stringToHtml "initial pig"
  present (PigView pid b viewedPig pignr name [tv, kl, ho] diagnosis) =
        withBgColor (if viewedPig == pignr then Rgb 200 200 200 else Rgb 225 225 225) $
     mkSpan ("pigview"++show (unId (getStrId name))) $ -- borrow from name, so id is changed by syb 
     boxed $
        (center $ image $ pigImage)
    +++ (center $ " nr. " +++ show (pignr+1))
    +++ p << (center $ (present b))
    +++ p << ("Name:" +++ present name)
    +++ p << "Type varken: " 
    +++ present tv
    +++ p << "Fase cyclus: "
    +++ present kl
    +++ p << "Haren overeind: "
    +++ present ho
    +++ p << ("diagnosis " ++ show diagnosis)
    where pigImage | viewedPig == pignr = "pig.png"
                   | viewedPig < pignr = "pigLeft.png"
                   | viewedPig > pignr = "pigRight.png"

instance Storeable PigView where
  save (PigView pid _ _ _ name symptoms diagnosis) =
    updatePig pid (\(Pig _ vid _ _ diagnosis) -> 
                    (Pig pid vid (getStrVal name) (map getSelection symptoms) diagnosis)) 

instance Initial PigView where
  initial = PigView initial initial initial initial initial initial initial





data LoginView = LoginView (Widget EString) (Widget EString) (Widget Button) 
  deriving (Eq, Show, Typeable, Data)

mkLoginView = mkWebView (ViewId (44)) $
      \user db viewMap vid ->
        let (LoginView name password b) = getOldView vid viewMap
        in  LoginView (estr (ViewId 3000) $ getStrVal name) 
                      (estr (ViewId 3001) $ getStrVal password) 
                      (button (ViewId 3002) "Login" $ AuthenticateEdit (strRef name) (strRef password))
-- todo using the old id is not okay!
-- TODO: related: how to handle setting the id but not the value

instance Storeable LoginView where save _ = id
                                   
instance Presentable LoginView where
  present (LoginView name password loginbutton) = 
    boxed $ ("Login:" +++ present name) +++
            ("Password:" +++ present password) +++
            present loginbutton
            
instance Initial LoginView where initial = LoginView initial initial initial

data LogoutView = LogoutView (Widget Button) deriving (Eq, Show, Typeable, Data)

mkLogoutView = mkWebView (ViewId (55)) $
  \user db viewMap vid -> LogoutView (button (ViewId 4001) "Logout" LogoutEdit)

instance Storeable LogoutView where save _ = id
                                   
instance Presentable LogoutView where
  present (LogoutView logoutbutton) = 
    present logoutbutton
            
instance Initial LogoutView where initial = LogoutView initial




updateReplaceHtml :: String -> Html -> Html
updateReplaceHtml targetId newElement =
  thediv![strAttr "op" "replace", strAttr "targetId" targetId ] 
    << newElement

mkDiv str elt = thediv![identifier str] << elt

mkSpan str elt = thespan![identifier str] << elt

boxed html = thediv![thestyle "border:solid; border-width:1px; padding:4px;"] << html



{-

Everything seems to work:
not updating the unchanged controls and keeping id's unique causes edit events survive update
They do seem to lose focus though, but since we know what was edited, we can easily restore the focus after
the update
-}


-- don't use Presentable, because we might present strings in different ways.

-- the entire root is a form, that causes registering text field updates on pressing enter
-- (or Done) on the iPhone. It would be nicer to capture this at the textfield itself.
-- Local forms are a problem though because they are block elements
-- TODO: focus loss on enter is not nice  
presentTextField :: EString -> Html
presentTextField = presentTextualInput (textfield "")
  
presentPasswordField :: EString -> Html
presentPasswordField = presentTextualInput (password "")

presentTextualInput :: Html -> EString -> Html
presentTextualInput inputfield (EString (Id i) str) = mkSpan ("input"++show i) $  
  inputfield ! [identifier (show i), strAttr "VALUE" str
               --, strAttr "onChange" $ "textFieldChanged('"++show i++"')"
               , strAttr "onFocus" $ "elementGotFocus('"++show i++"')"
               , strAttr "onBlur" $ "textFieldChanged('"++show i++"')"
               ]

-- seems like this one could be in Present
presentButton :: Button -> Html
presentButton (Button (Id i) txt _) = mkSpan ("input"++show i) $ 
   primHtml $ "<button onclick=\"queueCommand('ButtonC "++show i++"')\""++
                      "onfocus=\"elementGotFocus('"++show i++"')\">"++txt++"</button>"
-- TODO: text should be escaped

presentRadioBox :: RadioView -> Html
presentRadioBox (RadioView (Id i) items rv) = mkDiv ("input"++show i) $ radioBox (show i) items rv
-- id is unique


--radioBox :: String -> [String] -> Int -> Html
radioBox id items selectedIx =
  [ radio id (show i) ! ( [ strAttr "id" eltId 
                          , strAttr "onChange" ("queueCommand('SetC "++id++" %22"++show i++"%22')") 
                          , strAttr "onFocus" ("elementGotFocus('"++eltId++"')")
                          ]
                          ++ if i == selectedIx then [strAttr "checked" ""] else []) 
                          +++ item +++ br 
                        | (i, item) <- zip [0..] items 
                        , let eltId = "radio"++id++"button"++show i ]


hList [] = stringToHtml "" -- TODO should have some empty here
hList views = simpleTable [] [] [ views ]

vList [] = stringToHtml "" -- TODO should have some empty here
vList views = simpleTable [] [] [ [v] | v <- views ]

data Color = Rgb Int Int Int
           | Color String deriving Show

withBgColor (Rgb r g b) h = let colorStr = "#" ++ toHex2 r ++ toHex2 g ++ toHex2 b
                            in  thediv ! [thestyle $ "background-color: "++ colorStr ++";"] << h
withBgColor (Color colorStr) h = thediv ! [thestyle $ "background-color: "++colorStr++";"] << h

-- Utils

lputStr :: MonadIO m => String -> m ()
lputStr = liftIO . putStr

lputStrLn :: MonadIO m => String -> m ()
lputStrLn = liftIO . putStrLn

constrain mn mx x = (mn `max` x) `min` mx

toHex2 :: Int -> String
toHex2 d = [toHexDigit $ d `div` 16] ++ [toHexDigit $ d `mod` 16]

toHexDigit d = let d' = constrain 0 15 d
               in  chr $ d' + if d < 10 then ord '0' else ord 'A' - 10  

withPad left right top bottom h =
  thediv ! [thestyle $ "padding: "++show top++"px "++show right++"px "++
                       show bottom++"px "++show left++"px;"] << h

image filename = Html.image ! [src $ "/img/"++ filename ]

pluralS 1 = ""
pluralS n = "s" 

listCommaAnd :: [String] -> String
listCommaAnd [] = ""
listCommaAnd [s]  = s
listCommaAnd ss@(_:_) = (concat . intersperse ", " $ init ss) ++ " and " ++ last ss 






{-
Right now, incrementality is extremely fragile. Any views that are not presented cause
updates to missing stubs, giving errors.

Problem, parts of the old view that are not updated have their old id's in the browser,
so the rootView are updated to reflect these id's (also for internal id's in widgets)
RestoreId is used for this

pressing the lowest button shows a bug in the incrementality engine.
-}
data Update = Move String IdRef IdRef 
            | RestoreId IdRef IdRef
              deriving Show
              -- move element target 

isMove (Move _ _ _) = True
isMove _          = False




-- TODO: no need to compute new or changed first, can be put in Update list
--       do have to take into account addChangedViewChildren then
diffViewsWN :: ViewMap -> WebView -> ([WebNode], [Update])
diffViewsWN oldViewMap rootView = 
  let oldRootView = snd . head $ Map.toList oldViewMap
      newWebNodeMap = mkWebNodeMap rootView
      oldWebNodeMap = mkWebNodeMap oldRootView
      newOrChangedIdsWebNodes = {- addChangedViewChildren $ -} getNewOrChangedIdsWebNodes oldWebNodeMap newWebNodeMap
      (newOrChangedWebNodeIds, newOrChangedWebNodes) = unzip newOrChangedIdsWebNodes
  in -- trace ("\nOld view map\n"++showViewMap oldViewMap ++ "\nNew view map\n" ++ showViewMap newViewMap) 
    ( newOrChangedWebNodes
    , computeMoves oldWebNodeMap newOrChangedWebNodeIds rootView)

getNewOrChangedIdsWebNodes :: WebNodeMap -> WebNodeMap -> [(ViewId, WebNode)]
getNewOrChangedIdsWebNodes oldWebNodeMap newWebNodeMap =
 -- trace ("newWebNodeMap: "++ show (Map.keys newWebNodeMap))$
  filter isNewOrChanged $ Map.toList newWebNodeMap
 where isNewOrChanged (i, webNode) =
         case Map.lookup i oldWebNodeMap of
           Nothing -> True
           Just oldWebNode -> oldWebNode /= webNode
          
computeMoves :: WebNodeMap -> [ViewId] -> WebView -> [Update]           
computeMoves oldWebNodeMap changedOrNewWebNodes rootView@(WebView rootVid stubId rootId _ _) = 
  (if rootVid `elem` changedOrNewWebNodes 
   then let oldRoot = snd . head $ Map.toList oldWebNodeMap
        in  [ Move "Root move" (mkRef $ rootId) (mkRef $ getWebNodeId oldRoot) ] 
   else []) ++
  concatMap (computeMove oldWebNodeMap changedOrNewWebNodes)
    (getBreadthFirstWebNodes rootView)

-- if we do the comparison here, also take into account moving the immediate children of a changed
-- view
computeMove :: WebNodeMap -> [ViewId] -> WebNode -> [Update]
computeMove oldWebNodeMap changedOrNewWebNodes webNode =  
  if getWebNodeViewId webNode `notElem` changedOrNewWebNodes 
  then -- parent has not changed
       let Just oldWebNode = Map.lookup (getWebNodeViewId webNode) oldWebNodeMap 
       in  [RestoreId (mkRef $ getWebNodeId webNode) (mkRef $ getWebNodeId oldWebNode)] ++
           restoreInternalIds oldWebNode webNode ++ concat
           -- restore id's for parent
           
           [ if childViewId `notElem` changedOrNewWebNodes 
             then -- child has not changed
                  []
             else -- child has changed (or is new, but that doesn't happen)
                  let Just oldChildWebNode = Map.lookup childViewId oldWebNodeMap
                  in  [ Move "a" (mkRef $ getWebNodeId childWebNode) 
                                 (mkRef $ getWebNodeId oldChildWebNode)
                      ]                                      
           | let childWebNodes = getTopLevelWebNodesForWebNode webNode
           , childWebNode <- trace ("\nchildren for "++(show $ getWebNodeViewId webNode) ++ 
                                     ":" ++ show (map shallowShowWebNode childWebNodes)) $ 
                               childWebNodes
           , let childViewId = getWebNodeViewId childWebNode
           ]
  
  else -- parent has changed or is new
       concat    
           [ if childViewId `notElem` changedOrNewWebNodes 
             then -- child has not changed
                  let Just oldChildWebNode = Map.lookup childViewId oldWebNodeMap
                  in  [ Move "b" (mkRef $ getWebNodeId oldChildWebNode)  
                                 (mkRef $ getWebNodeStubId childWebNode)
                      ]
             else -- child has changed or is new
                  [ Move "c" (mkRef $ getWebNodeId childWebNode) 
                             (mkRef $ getWebNodeStubId childWebNode)
                  ]                                      
           | let childWebNodes = getTopLevelWebNodesForWebNode webNode
           , childWebNode <- trace ("\nchildren for "++(show $ getWebNodeViewId webNode) ++ 
                                     ":" ++ show (map shallowShowWebNode childWebNodes)) $ 
                               childWebNodes
           , let childViewId = getWebNodeViewId childWebNode
           ]
       
getTopLevelWebNodesForWebNode (WidgetNode _ _ _ wn) = []
getTopLevelWebNodesForWebNode (WebViewNode (WebView _ _ _ _ v)) = getTopLevelWebNodesWebNode v

restoreInternalIds (WidgetNode _ _ _ oldW) (WidgetNode _ _ _ newW) =  
  [ RestoreId (mkRef $ getWidgetInternalId newW) (mkRef $ getWidgetInternalId oldW) ]
restoreInternalIds (WebViewNode _) (WebViewNode _) = [] 
restoreInternalIds _ _ = error "Internal error: restoreInternalIds, WebNode mismatch"


traceArg str x = trace (str ++ show x) x
           

webViewGetId (WebView _ _ i _ _) = i 

    
getWebNodeViewId (WebViewNode (WebView vid _ _ _ _)) = vid      
getWebNodeViewId (WidgetNode vid _ _ _) = vid

getWebNodeId (WebViewNode (WebView _ _ i _ _)) = i      
getWebNodeId (WidgetNode _ _ i _) = i


getWebNodeStubId (WebViewNode (WebView _ si _ _ _)) = si      
getWebNodeStubId (WidgetNode _ si _ _) = si


getWidgetInternalId :: AnyWidget -> Id
getWidgetInternalId  (RadioViewWidget (RadioView id _ _)) = id
getWidgetInternalId  (EStringWidget (EString id _)) = id
getWidgetInternalId  (ButtonWidget (Button id _ _)) = id
            
getBreadthFirstWebNodes :: WebView -> [WebNode]
getBreadthFirstWebNodes rootView =
  concat $ takeWhile (not . null) $ iterate (concatMap getTopLevelWebNodes) 
                                       [WebViewNode rootView]
 where getTopLevelWebNodes (WebViewNode wv) = getTopLevelWebNodesWebView wv
       getTopLevelWebNodes _ = []
       
mkIncrementalUpdates oldViewMap rootView =
 do { let (newWebNodes, updates) = diffViewsWN oldViewMap rootView
    ; putStrLn $ "\nChanged or new web nodes\n" ++ unlines (map shallowShowWebNode newWebNodes) 
    ; putStrLn $ "\nUpdates\n" ++ unlines (map show updates)
    
    ; let responseHtml = thediv ! [identifier "updates"] <<
                           (map newWebNodeHtml newWebNodes +++
                            map updateHtml updates)

    ; let subs = concat [ case upd of 
                                    RestoreId (IdRef o) (IdRef n) -> [(Id o, Id n)]  
                                    Move _ _ _ -> []
                                | upd <- updates
                                ]
    ; putStrLn $ "Id updates on rootView:" ++ show subs
    -- todo: check restoration on views, and esp. on root.
    
    ; let rootView' = substituteIds subs rootView
    ; putStrLn $ "Html:\n" ++ show responseHtml
    ; return (responseHtml, rootView')
    }
 
                                
showViewMap viewMap = unlines $ "ViewMap:" : [ show k ++ shallowShowWebView wv | (k, wv) <- Map.toList viewMap ]


newWebNodeHtml :: WebNode -> Html
newWebNodeHtml (WebViewNode (WebView _ _ (Id i) _ v)) = 
    thediv![strAttr "op" "new"] << 
      (mkSpan (show i) $ present v)
newWebNodeHtml (WidgetNode _ _ (Id i) w) = 
    thediv![strAttr "op" "new"] << 
      (mkSpan (show i) $ present w)

newViewHtml :: WebView -> Html
newViewHtml (WebView _ _ (Id i) _ v) = 
    thediv![strAttr "op" "new"] << 
      (mkSpan (show i) $ present v)

newWidgetHtml :: (Id, Id, AnyWidget) -> Html
newWidgetHtml (_, (Id i),anyWidget) = 
    thediv![strAttr "op" "new"] << 
      (mkSpan (show i) $ present anyWidget)

updateHtml :: Update -> Html
updateHtml (Move _ (IdRef src) (IdRef dst)) = if src == dst then error "Source is destingation" else
    thediv![strAttr "op" "move", strAttr "src" (show src), strAttr "dst" (show dst)] << ""
updateHtml _ = stringToHtml "" -- restoreId is not for producing html, but for adapting the rootView  


instance Presentable WebView where
  present (WebView _ (Id stubId) _ _ _) = mkSpan (show stubId) << "ViewStub"
  
instance Presentable (Widget x) where
  present (Widget _ (Id stubId) _ _) = mkSpan (show stubId) << "WidgetStub"


-- todo button text and radio text needs to go into view
instance Presentable AnyWidget where                          
  present (RadioViewWidget rv) = presentRadioBox rv 
  present (EStringWidget es) = presentTextField es 
  present (ButtonWidget b) = presentButton b 

shallowShowWebNode (WebViewNode wv) = "WebNode: " ++ shallowShowWebView wv
shallowShowWebNode (WidgetNode _ _ _ w) = "WebNode: " ++ show w 

shallowShowWebView (WebView  vid sid id _ v) =
  "<WebView: "++show vid ++ ", stub:" ++ show (unId sid) ++ ", id:" ++ show (unId id) ++ " " ++ show (typeOf v)++ ">"

drawWebNodes webnode = drawTree $ treeFromView webnode
 where treeFromView (WebViewNode wv@(WebView vid sid id _ v)) =
         Node ("("++show vid ++ ", stub:" ++ show (unId sid) ++ ", id:" ++ show (unId id) ++ ") : " ++ show (typeOf v)) $
              map treeFromView $ getTopLevelWebNodesWebNode v
       treeFromView (WidgetNode vid sid id w) =
         Node ("("++show vid++", stub:" ++ show (unId sid) ++ ", id:" ++ show (unId id) ++ ") : " ++ showAnyWidget w) $
              map treeFromView $ getTopLevelWebNodesWebNode w
        where showAnyWidget (RadioViewWidget (RadioView id is i))    = "RadioView " ++ show id ++" " ++ (show i) ++ ": "++ show is
              showAnyWidget (EStringWidget (EString id s)) = "EString "++ show id ++" "++ (show s)
              showAnyWidget (ButtonWidget (Button id _ _))  = "Button" ++ show id 
                 
data T = T Char [T]
t0 = T 'a' [T 'b' [T 'd' [], T 'e' []], T 'c' [], T 'f' [T 'g' []]]

bfs (T x cs) = [x] :  (map concat $ transpose $ map bfs cs)
