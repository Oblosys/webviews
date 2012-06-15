{-# OPTIONS -XFlexibleInstances -XMultiParamTypeClasses -XScopedTypeVariables -XDeriveDataTypeable #-}
module WebViewPrim where

import Control.Monad.State
import BlazeHtml
import Data.List
import Data.Generics
import Debug.Trace

import Types
import Generics
import HtmlLib


--       GADTs?
-- TODO: use a monad for auto handling listeners to database

{-

initials really necessary?
Related: When will oldview not be found during loadView, leading to using oldview' from the webView?
Right now, initials have no viewId, so using them is dangerous.


authenticate shows possible danger. if the refs are evaluated to get the name and password, and the structure
has changed, then the refs will fail. This should not lead to an error. It will probably never happen
since restructuring leads to recreation of the login view because of failure to reuse.

TODO when doing loading on non-root, check how this works with the unique id stuff.

TODO check noViewId, this is now a rootViewId
TODO change liftS

TODO somehow ensure that widgets/subviews are not conditional
TODO unpresented widgets should not crash



Ideas: search pigs by name
inView attr that sets the scrollbars (also nested) so elt with attr is in view
save scroll state of all scrollers, and restore after reload
separate specific from generic part
tabbed views, also with separate urls
templates from files in presentation
monad for editing
cleanup
-}

-- TODO: Maybe put this in a Utils?
debugLn str = trace str $ return ()

-- When loading from different point than root, make sure Id's are not messed up

instance Data db => Storeable db (WebView db) where
  save (WebView _ _ _ _ v) =
    let topLevelWebViews :: [WebView db] = getTopLevelWebViews v
    in  foldl (.) id $ save v : map save topLevelWebViews



---- Monad stuff

runWebView user db viewMap path viewIdCounter wvm =
 do { rv <- evalStateT wvm (WebViewState user db viewMap path viewIdCounter)
    ; return $ assignIds rv
    }


withDb f = do { (WebViewState _ db _ _ _) <- get
              ; return $ f db
              }


getUser :: WebViewM db User 
getUser = do { (WebViewState u _ _ _ _) <- get
             ; return u
             }


liftS :: ([Int] -> Int -> (x,Int)) -> WebViewM db x
liftS f = StateT (\(WebViewState user db viewMap path i) -> 
                   (return $ let (x, i')= f path i in (x, WebViewState user db viewMap path i')))

assignViewId :: (ViewId -> v) -> WebViewM db v
assignViewId viewConstr = liftS $ \path vidC -> (viewConstr (ViewId $ path ++ [vidC]), vidC +1)

mkEditAction :: EditCommand db -> WebViewM db (EditAction db) 
mkEditAction ec = mkEditActionEx $ const ec

mkEditActionEx :: ([String] -> EditCommand db) -> WebViewM db (EditAction db) 
mkEditActionEx fec = assignViewId $ \vid -> EditAction vid fec


mkLabelView str = assignViewId $ \vid -> labelView vid str

mkTextField str = mkTextFieldEx str Nothing

mkTextFieldAct str act = mkTextFieldEx str $ Just act

mkTextFieldEx str mEditAction = assignViewId $ \vid -> textField vid str mEditAction

mkPasswordField str = mkPasswordFieldEx str Nothing

mkPasswordFieldAct str act = mkPasswordFieldEx str $ Just act

mkPasswordFieldEx str mEditAction = assignViewId $ \vid -> passwordField vid str mEditAction

mkTextArea str = assignViewId $ \vid -> textArea vid str

mkRadioView is s en = assignViewId $ \vid -> radioView vid is s en

mkSelectView is s en = assignViewId $ \vid -> selectView vid is s en

mkButton str en ac = mkButtonEx str en "" (const "") ac

mkButtonWithStyle str en st ac = mkButtonEx str en st (const "") ac

mkButtonWithClick str en foc = mkButtonEx str en "" foc $ Edit $ return () -- because onclick currently disables server edit command

mkButtonWithStyleClick str en st foc = mkButtonEx str en st foc $ Edit $ return () -- because onclick currently disables server edit command

mkButtonEx :: String -> Bool -> String -> (ViewId -> String) -> EditCommand db -> WebViewM db (Widget (Button db)) -- signature nec. against ambiguity
mkButtonEx str en st foc ac = assignViewId $ \vid -> button vid str en st (foc vid) ac

mkJSVar name value = assignViewId $ \vid -> jsVar_ vid name value


widgetGetViewRef widget = mkViewRef $ getViewId widget
                  
{-
mkAction :: (v->v) -> ViewM v Int
mkAction f = 
 do { actions <- get
    ; put $ actions ++ [f]
    ; return $ length actions + 1
    }


testMonad = print $ "bla" {- runMonad [1,2,3] $
 do { l <- getList
    ; return l
    } -}

-}
-- hide this constructor, so user needs to use mkView
{-
data AView v = AView { editActions :: [v->v], makeView :: v -> v }

mkView :: (ViewM v (v->v)) -> (AView v)
mkView mv = runIdentity $ 
 do { (mkview, state) <- runStateT mv []
    ; return $ AView state mkview
    }



data TestView = TestView Int String

--mkTestView
mkTestView v = mkView $ 
 do { i <- mkAction $ \(TestView x s) -> TestView x s
    ; return $ \v -> TestView i "bla"
    } 
-}


--- Edit Monad


docEdit :: (db -> db) -> EditM db ()
docEdit docUpdate =
 do { (sessionId, user, db, rootView, pendingEdit) <- get
    ; put (sessionId, user, docUpdate db, rootView, pendingEdit)
    }

viewEdit :: (Typeable db, Data db, Data v) => ViewId -> (v -> v) -> EditM db ()
viewEdit vid viewUpdate =
  do{ (sessionId, user, db, rootView, pendingEdit) <- get
    ; let webViewUpdate = \(WebView vi si i lv v) ->
                            WebView vi si i lv $ applyIfCorrectType viewUpdate v
          wv = getWebViewById vid rootView
          wv' = webViewUpdate wv
          rootView' = replaceWebViewById vid wv' rootView 
                          
    ; put (sessionId, user, save rootView' db, rootView', pendingEdit)
    }

-- TODO save automatically, or maybe require explicit save? (after several view updates)
-- for now, just after every viewEdit

applyIfCorrectType :: (Typeable y, Typeable x) => (y -> y) -> x -> x
applyIfCorrectType f x = case cast f of 
                           Just fx -> fx x
                           Nothing -> x

-- Experimental, not sure if we need this one and if it works correctly
withView :: forall db v a . (Typeable db, Data db, Data v, Typeable a) => ViewId -> (v->a) -> EditM db (Maybe a)
withView vid f =
  do{ (sessionId, user, db, rootView, pendingEdit) <- get
    ; let wf = \(WebView vi si i lv v) -> case cast f of
                                            Nothing -> Nothing
                                            Just castf -> Just $ castf v
          wv = getWebViewById vid rootView :: WebView db
          
    ; return $ wf wv
    }

-- the view matching on load can be done explicitly, following structure and checking ids, or
-- maybe automatically, based on id. Maybe extra state can be in a separate data structure even,
-- like in Proxima
loadView :: WebView db -> WebViewM db (WebView db)
loadView (WebView _ si i mkView oldView') =
 do { state@(WebViewState user db viewMap path viewIdCounter) <- get
    ; let newViewId = ViewId $ path ++ [viewIdCounter]                             
    ; put $ WebViewState user db viewMap (path++[viewIdCounter]) 0
    ; let oldView = case lookupOldView newViewId viewMap of
                      Just oldView -> oldView
                      Nothing      -> oldView' -- this will be initial
                      
    ; view <- mkView newViewId oldView -- path is one level deeper for children created here 
    ; modify $ \s -> s { getStatePath = path, getStateViewIdCounter = viewIdCounter + 1} -- restore old path
    ; return $ WebView newViewId si i mkView view    
    }
        
mkWebView :: Data db => (Presentable v, Storeable db v, Initial v, Show v, Eq v, Data v) =>
             (ViewId -> v -> WebViewM db v) ->
             WebViewM db (WebView db)
mkWebView mkView =
 do { let initialWebView = WebView noViewId noId noId mkView initial
    ; webView <- loadView initialWebView
    ; return webView
    } 


{-
id that is unique in parent guarantees no errors. What about uniqueness for pigs when switching visits?
what about space leaks there?

TODO: this seems only necessary for subviews, as these can have extra state
for widgets, there may be a little less reuse, but no problem. Except maybe if a widget
is created based on a list of elements, but does not take its content fnice to do it in pig itself, but then we need to remove it's ols unique id from the path and make sure
that it's own unique id does not clash with generated id's or unique id's from other lists. We cannot
include the generated unique id, because then the unique id does not identify the view by itself anymore

widget [.., 0]
widget [.., 1]
views  [.., unique1]
       [.., unique2]
view   [.., 2]
views  [.., unique3]
views  [.., unique4]
(uniques may not overlap with {0,1,2})

doing it at the list is easier

widget [.., 0]
widget [.., 1]
views  [..,2, unique1]
       [..,2, unique2]
view   [.., 3]
views  [.., 4,unique1]
views  [.., 4,unique2]

Now the unique id's only have to be unique with regard to other elts in the list.

Note that the zeros after the uniques are added due to the way mkWebview and load Webview work.
-}
uniqueIds :: [(Int, WebViewM db (WebView db))] -> WebViewM db [WebView db]
uniqueIds idsMkWvs =
 do { state@(WebViewState user db viewMap path viewIdCounter) <- get
    ; put $ state { getStatePath = path++[viewIdCounter], getStateViewIdCounter = 0 } 
      -- 0 is not used, it will be replaced by the unique ids
      
    ; wvs <- sequence [ uniqueId id mkWv | (id, mkWv) <- idsMkWvs]
    ; modify $ \s -> s { getStatePath = path, getStateViewIdCounter = viewIdCounter+1 }
    ; return wvs
    }
 
uniqueId uniqueId wv =
 do { modify $ \s -> s { getStateViewIdCounter = uniqueId } 
    ; v <- wv
    ; return v
    }

{-

Everything seems to work:
not updating the unchanged controls and keeping id's unique causes edit events survive update
They do seem to lose focus though, but since we know what was edited, we can easily restore the focus after
the update
-}

presentLabelView :: LabelView -> Html
presentLabelView (LabelView viewId str) = div_ ! id_ (toValue $ show viewId) $ toHtml str

-- textfields are in forms, that causes registering text field updates on pressing enter
-- (or Done) on the iPhone.

presentTextField :: TextView db -> Html
presentTextField (TextView viewId TextArea str _) =
   form !* [ thestyle "display: inline; width: 100%;"
         , strAttr "onSubmit" $ "return false"] $  -- return false, since we don't actually submit the form
     textarea !* [ id_ (toValue $ show viewId)
                , thestyle "width: 100%; height: 100%;"
                , strAttr "onFocus" $ "script"++viewIdSuffix viewId++".onFocus()"
                , strAttr "onBlur" $ "script"++viewIdSuffix viewId++".onBlur()"
                , strAttr "onKeyUp" $ "script"++viewIdSuffix viewId++".onKeyUp()"
                    ] << toHtml str >>
  (mkScript $ declareWVTextViewScript viewId)      
presentTextField (TextView viewId textType str mEditAction) = 
  let inputField = case textType of TextField -> textfield ""
                                    PasswordField -> password ""
                                    
  in form !* [ thestyle "display: inline"
            , strAttr "onSubmit" $ (case mEditAction of
                                    Nothing -> "return false"
                                    Just _  -> "script"++viewIdSuffix viewId++".onSubmit();"++
                                               "return false")] $ -- return false, since we don't actually submit the form
       inputField !* [ id_ (toValue $ show viewId), strAttr "value" str, width "100%"
                    , strAttr "onFocus" $ "script"++viewIdSuffix viewId++".onFocus()"
                    , strAttr "onBlur" $ "script"++viewIdSuffix viewId++".onBlur()"
                    , strAttr "onKeyUp" $ "script"++viewIdSuffix viewId++".onKeyUp()" ]  >>
  (mkScript $ declareWVTextViewScript viewId)      

declareWVTextViewScript viewId = jsDeclareVar (ViewIdT viewId) "script" $ "new TextViewScript(\""++show viewId++"\");"

-- For the moment, onclick disables the standard server ButtonC command
presentButton :: Button db -> Html
presentButton (Button viewId txt enabled style onclick _) =
{-  (primHtml $ "<button id=\""++ show viewId++"\" "++ (if enabled then "" else "disabled ") ++ (if style /="" then " style=\"" ++style++"\" " else "")++
                            "onclick=\""++ (if onclick /= "" then onclick else "queueCommand('ButtonC ("++show viewId++")')" )++
                                     "\" "++
                            "onfocus=\"elementGotFocus('"++show viewId++"')\">"++txt++"</button>") -}
  (primHtml $ "<button id=\""++ show viewId++"\" "++ (if enabled then "" else "disabled ") ++ (if style /="" then " style=\"" ++style++"\" " else "")++
                            "onclick="++ (if onclick /= "" then show onclick else "\"script"++viewIdSuffix viewId++".onClick()\"")++" "++
                            "onfocus=\"script"++viewIdSuffix viewId++".onFocus()\">"++txt++"</button>") >>
  (mkScript $ declareWVButtonScript viewId)
-- TODO: text should be escaped

declareWVButtonScript viewId = jsDeclareVar (ViewIdT viewId) "script" $ "new ButtonScript(\""++show viewId++"\");"

-- Edit actions are a bit different, since they do not have a widget presentation.
-- TODO: maybe combine edit actions with buttons, so they use the same command structure
-- a descriptive text field can be added to the action, to let the server be able to show
-- which button was pressed. However, it is not sure if this works okay with restoring id's
-- though it probably works out, as the ea id is the only one needing restoration.
withEditAction (EditAction viewId _) elt =
  thespan !* [ id_ $ toValue $ show viewId
             , strAttr "onClick" $ "queueCommand('PerformEditActionC ("++show viewId++") []')"] << elt

withEditActionAttr (EditAction viewId _) =  
  strAttr "onClick" $ "queueCommand('PerformEditActionC ("++show viewId++") []')"

presentRadioView (RadioView viewId items selectedIx enabled) = thespan << sequence_
  [ radio (show viewId) (show i) !* ( [ id_ (toValue eltId) -- all buttons have viewId as name, so they belong to the same radio button set 
                          , strAttr "onChange" ("queueCommand('SetC ("++show viewId++") %22"++show i++"%22')") 
                          , strAttr "onFocus" ("elementGotFocus('"++eltId++"')")
                          ]
                          ++ (if enabled && i == selectedIx then [strAttr "checked" ""] else []) 
                          ++ (if not enabled then [strAttr "disabled" ""] else [])) 
                          >> toHtml item >> br 
  | (i, item) <- zip [0..] items 
  , let eltId = "radio"++show viewId++"button"++show i ] -- these must be unique for setting focus

presentSelectView :: SelectView -> Html
presentSelectView (SelectView viewId items selectedIx enabled) = 
  do { select !* ([ id_ $ toValue $ show viewId
                  , strAttr "onChange" ("script"++viewIdSuffix viewId++".onChange()")
                  , strAttr "onFocus" ("script"++viewIdSuffix viewId++".onFocus()")
                  ] ++
                  if not enabled then [strAttr "disabled" ""] else []) $ 
              
         sequence_
           [ option (toHtml item) !* (if i == selectedIx then [strAttr "selected" ""] else [])
           | (i, item) <- zip [0..] items ]
     ; mkScript $ declareWVSelectScript viewId
     }

declareWVSelectScript viewId = jsDeclareVar (ViewIdT viewId) "script" $ "new SelectScript(\""++show viewId++"\");"

presentJSVar :: JSVar -> Html
presentJSVar (JSVar viewId name value) = thediv ! (id_ . toValue $ show viewId) << 
  (mkScript $ let jsVar = name++viewIdSuffix viewId
              in  "if (typeof "++jsVar++" ==\"undefined\") {"++jsVar++" = "++value++"};")
              -- no "var " here, does not work when evaluated with eval
  


instance Presentable (WebView db) where
  present (WebView _ (Id stubId) _ _ _) = mkSpan (show stubId) << "ViewStub"
  
instance Presentable (Widget x) where
  present (Widget (Id stubId) _ _) = mkSpan (show stubId) << "WidgetStub"


-- todo button text and radio/select text needs to go into view
instance Presentable (AnyWidget db) where                          
  present (LabelWidget w) = presentLabelView w 
  present (TextWidget w) = presentTextField w
  present (RadioViewWidget w) = presentRadioView w 
  present (SelectViewWidget w) = presentSelectView w 
  present (ButtonWidget w) = presentButton w 
  present (JSVarWidget w) = presentJSVar w 
  
  
  
  
-- Phantom typing

newtype ViewIdT viewType = ViewIdT ViewId

newtype WebViewT viewType db = WebViewT { unWebViewT :: WebView db } deriving (Eq, Show, Typeable, Data)

instance Data db => Initial (WebViewT wv db)
  where initial = WebViewT initial

instance Presentable (WebViewT wv db)
  where present (WebViewT wv) = present wv
 
getViewIdT :: WebViewT v db -> ViewIdT v
getViewIdT (WebViewT wv) = ViewIdT $ getViewId wv

-- TODO: still need this for widget view id's. Figure out what to do with widgets
-- right now, they use getViewIdT_ and also avoid the typed stuff with some ..ByViewIdRef functions 
getViewIdT_ :: HasViewId v => v -> ViewId
getViewIdT_ = getViewId

mkWebViewT :: Data db => (Presentable v, Storeable db v, Initial v, Show v, Eq v, Data v) =>
             (ViewIdT v -> v -> WebViewM db v) ->
             WebViewM db (WebViewT v db)
             
mkWebViewT mkViewT = 
 do { wv <- mkWebView (\vid -> mkViewT $ ViewIdT vid)
    ; return $ WebViewT wv
    }

rootWebView :: String -> (SessionId -> [String] -> WebViewM db (WebViewT  v db)) -> (String, SessionId -> [String] -> WebViewM db (WebView db) )
rootWebView name mkWV = (name, \sessionId args -> fmap unWebViewT $ mkWV sessionId args)
    
viewEditT :: (Typeable db, Data db, Data v) => ViewIdT v -> (v -> v) -> EditM db ()
viewEditT (ViewIdT vid) viewUpdate = viewEdit vid viewUpdate




-- Scripting

viewIdSuffix (ViewId ps) = concatMap (('_':).show) ps

declareFunction :: ViewId -> String -> [String] -> String -> String
declareFunction vid name params body = name++viewIdSuffix vid++" = Function("++concatMap ((++",").show) params++"'"++body++"');"
-- no "var" when declaring the variable that contains the functions, but in body they are allowed (and maybe necessary for IE)
-- todo: escape '

escapeSingleQuote str = concatMap (\c -> if c == '\'' then "\\'" else [c]) str 
jsFunction (ViewIdT v) n a b = declareFunction v n a $ escapeSingleQuote $ intercalate ";" b -- no newlines here, since scripts are executed line by line 
jsScript lines = intercalate ";\n" lines
jsIf c t = "if ("++c++") {"++intercalate ";" t++"}"
jsIfElse c t e = "if ("++c++") {"++intercalate ";" t++"} else {"++intercalate ";" e++ "}"
jsFor c b = "for ("++c++") {"++intercalate ";" b++"}"
jsGetElementByIdRef (ViewIdRef id) = "document.getElementById('"++show (ViewId id)++"')"
jsArr elts = "["++intercalate"," elts ++"]"
jsLog e = "console.log("++e++")";

mkJson :: [(String,String)] -> String
mkJson fields = "{"++intercalate "," [name++": "++value| (name, value)<-fields]++"}"



-- TODO should script have all fields? Or is a missing field no problem (or preventable by type checker)
-- TODO generate script nodes before executing scripts? Now they are generated by the scripts, so either
--      child cannot refer to parent or parent cannot refer to child.
onClick :: (Widget (Button db)) -> String -> String
onClick button expr = onEvent "Click" button expr

onKeyUp :: (Widget (TextView db)) -> String -> String
onKeyUp button expr = onEvent "KeyUp" button expr

-- fired on return key
onSubmit :: (Widget (TextView db)) -> String -> String
onSubmit button expr = onEvent "Submit" button expr

onEvent :: HasViewId w => String -> (Widget w) -> String -> String
onEvent event widget expr = "script"++viewIdSuffix (getViewId widget) ++ ".on"++event++" = function () {"++expr++"};"

jsVar (ViewIdT vid) name = name++viewIdSuffix vid
jsAssignVar (ViewIdT vid) name value = name++viewIdSuffix vid++" = "++value++";"
-- TODO: maybe refVar and assignVar are more appropriate?
jsDeclareVar (ViewIdT vid) name value = let jsVar = name++viewIdSuffix vid
                            in  "if (typeof "++jsVar++" ==\"undefined\") {"++jsVar++" = "++value++";};"
-- no "var " here, does not work when evaluated with eval

jsCallFunction (ViewIdT vid) name params = name++viewIdSuffix vid++"("++intercalate "," params++")"
-- old disenable call in presentButton:--"disenable"++viewIdSuffix (ViewId $ init $ unViewId viewId)++"('"++show (unViewId viewId)++"');
-- figure out if we need the viewId for the button when specifying the onclick
-- but maybe  we get a way to specify a client-side edit op and do this more general

jsGetWidgetValue widget = jsGetElementByIdRef (widgetGetViewRef widget) ++".value"

jsNavigateTo href = "window.location.href = "++ href ++ ";"


inertTextView :: (Widget (TextView db)) -> String
inertTextView tv = jsScript [ onEvent "Submit" tv ""
                            , onEvent "Focus" tv ""
                            , onEvent "Blur" tv ""
                            ]
                            
callServerEditAction ea args = "queueCommand('PerformEditActionC ("++show (getActionViewId ea)++") [\"'+"++
                                      intercalate "+'\",\"'+" args ++"+'\"]')"



-- Hacky stuff

-- probably to be deleted, labels do not need to be accessed    
getLabelContents :: forall db . Data db => Widget LabelView -> EditM db String
getLabelContents text =
 do { (sessionId, user, db, rootView, pendingEdit) <- get
    ; return $ getLabelContentsByViewIdRef (undefined :: db{-dummy arg-}) (widgetGetViewRef text) rootView
    } 
    
getLabelContentsByViewIdRef :: forall db v . (Typeable db, Data v) => db -> ViewIdRef -> v -> String
getLabelContentsByViewIdRef _ (ViewIdRef i) view =
  let (LabelView _ str) :: LabelView = getLabelViewByViewId (ViewId i) view
  in  str

-- not sure if we'll need these, passing vars as arguments works for submit actions.
getJSVarContents :: forall db . Data db => Widget JSVar -> EditM db String
getJSVarContents text =
 do { (sessionId, user, db, rootView, pendingEdit) <- get
    ; return $ getJSVarContentsByViewIdRef (undefined :: db{-dummy arg-}) (widgetGetViewRef text) rootView
    } 
    
getJSVarContentsByViewIdRef :: forall db v . (Typeable db, Data v) => db -> ViewIdRef -> v -> String
getJSVarContentsByViewIdRef _ (ViewIdRef i) view =
  let (JSVar _ _ value) :: JSVar = getJSVarByViewId (ViewId i) view
  in  value

                            