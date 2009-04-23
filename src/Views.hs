{-# OPTIONS -fglasgow-exts #-}
module Views where

import Control.Monad.Trans
import Data.List
import Text.Html
import Data.Generics

import Types
import Database
import Generics


-- TODO: automaticly supplying old views
--       figure out load stuff
--       use a monad for auto handling listeners to database
-- don't use Presentable, because we might present strings in different ways.


instance Storeable WebView where
  save (WebView _ _ v) =
    let topLevelWebViews = getTopLevelWebViews v
    in  foldl (.) id $ save v : map save topLevelWebViews

-- first save self, then children
-- TODO: does this order matter?

-- should be with TH stuff for Database, like DatabaseUtils or something
instance Initial VisitId where initial = VisitId (-1)

instance Initial PigId where initial = PigId (-1)


presentRadioBox :: [String] -> EInt -> [Html]
presentRadioBox items (EInt (Id i) ei) = radioBox (show i) items ei

presentTextField :: EString -> Html
presentTextField (EString (Id i) str) =
  textfield "" ! [identifier (show i), strAttr "VALUE" str
                 , strAttr "onChange" $ "textFieldChanged('"++show i++"')"]

-- seems like this one could be in Present
presentButton :: String -> Button -> Html
presentButton txt (Button (Id id) _) =
   primHtml $ "<button onclick=\"queueCommand('ButtonC "++show id++"')\">"++txt++"</button>"


mkViewEdit i f = 
  ViewEdit i $ \(WebView i lv v) -> WebView i lv $ applyIfCorrectType f v


applyIfCorrectType :: (Typeable y, Typeable x) => (y -> y) -> x -> x
applyIfCorrectType f x = case cast f of 
                           Just fx -> fx x
                           Nothing -> x


-- the view matching on load can be done explicitly, following structure and checking ids, or
-- maybe automatically, based on id. Maybe extra state can be in a separate data structure even,
-- like in Proxima
mkRootView db = mkVisitView (VisitId 1) db 

mkWebView :: (Presentable v, Storeable v, Initial v, Show v, Eq v, Data v) =>
             ViewId -> (Database -> ViewMap -> ViewId -> v) -> Database -> ViewMap -> WebView
mkWebView vid wvcnstr db viewMap = loadView db viewMap $
  WebView vid wvcnstr initial

loadView db viewMap (WebView vid f _) = (WebView vid f (f db viewMap vid))



data VisitView = 
  VisitView VisitId EString EString EInt Button Button Button [PigId] [String] (Maybe WebView)
  deriving (Eq, Show, Typeable, Data)

-- todo: doc edits seem to reset viewed pig nr.
mkVisitView i = mkWebView (ViewId 0) $
  \db viewMap vid -> 
  let (VisitView _ _ _ oldViewedPig _ _ _ _ _ mpigv) = getOldView vid viewMap
      (Visit visd zipcode date pigIds) = unsafeLookup (allVisits db) i
      viewedPig = constrain 0 (length pigIds - 1) $ getIntVal oldViewedPig
      pignames = map (pigName . unsafeLookup (allPigs db)) pigIds
  in  VisitView i (estr zipcode) (estr date) (eint viewedPig) 
                (Button noId (previous (ViewId 0))) (Button noId (next (ViewId 0)))
                (Button noId (addPig visd)) pigIds pignames $
-- todo: check id's
                (if null pigIds -- remove guard for weird hanging exception (after removing last pig)
                    then Nothing
                    else Just $ mkPigView viewedPig (pigIds !! viewedPig) db viewMap
                   )
 where -- next and previous may cause out of bounds, but on reload, this is constrained
       previous i = mkViewEdit i $
         \(VisitView vid zipCode date viewedPig b1 b2 b3 pigs pignames mSubview) ->
         VisitView vid zipCode date (eint $ getIntVal viewedPig-1) b1 b2 b3 pigs pignames mSubview

       next i = mkViewEdit i $
         \(VisitView vid zipCode date viewedPig b1 b2 b3 pigs pignames mSubview) ->
         VisitView vid zipCode date (eint $ getIntVal viewedPig+1) b1 b2 b3 pigs pignames mSubview

       addPig i = DocEdit $ addNewPig i 

addNewPig vid db =
  let ((Pig newPigId _ _ _ _), db') = newPig vid db      
  in  (updateVisit vid $ \v -> v { pigs = pigs v ++ [newPigId] }) db'

instance Presentable VisitView where
  present (VisitView vid zipCode date viewedPig b1 b2 b3 pigs pignames mSubview) =
        h2 << ("Visit at "+++ presentTextField zipCode +++" on " +++ presentTextField date)
    +++ ("Visited "++ show (length pigs) ++" pig" ++ (if (length pigs == 1) then "" else "s") ++":")
    +++ show pignames
    +++ p << ((if null pigs then stringToHtml $ "Not viewing any pigs" 
               else "Viewing pig nr. " +++ show (getIntVal viewedPig))
    -- "debugAdd('boing');queueCommand('Set("++id++","++show i++");')"
              +++ presentButton "previous" b1 +++ presentButton "next" b2 +++ presentButton "add" b3)
    +++ p << (case mSubview of
               Nothing -> stringToHtml "no pigs"
               Just pv -> present pv)

instance Storeable VisitView where
  save (VisitView vid zipCode date _ _ _ _ pigs pignames mSubView) db =
    updateVisit vid (\(Visit _ _ _ pigIds) ->
                      Visit vid (getStrVal zipCode) (getStrVal date) pigIds)
                    db

instance Initial VisitView where
  initial = VisitView initial initial initial initial initial initial initial initial initial initial


data PigView = PigView PigId Button Int EString [EInt] (Either Int String) 
               deriving (Eq, Show, Typeable, Data)

mkPigView pignr i = mkWebView (ViewId 33) $ 
      \db viewMap vid ->
  let (Pig pid vid name symptoms diagnosis) = unsafeLookup (allPigs db) i
  in  PigView pid (Button noId (removePigAlsoFromVisit pid vid)) pignr (estr name) (map eint symptoms) diagnosis
 where -- need db support for removal and we need parent
       removePigAlsoFromVisit pid vid = 
         DocEdit $ removePig pid . updateVisit vid (\v -> v { pigs = delete pid $ pigs v } )  

instance Presentable PigView where
  present (PigView pid b pignr name [] diagnosis) = stringToHtml "initial pig"
  present (PigView pid b pignr name [tv, kl, ho] diagnosis) =
    boxed $
        p << ("Pig nr. " +++ show pignr +++ presentButton "remove" b)
    +++ p << ("Name:" +++ presentTextField name)
    +++ p << "Type varken: " 
    +++ presentRadioBox ["Roze", "Grijs"] tv
    +++ p << "Fase cyclus: "
    +++ presentRadioBox ["1", "2", "3"] kl
    +++ p << "Haren overeind: "
    +++ presentRadioBox ["Ja", "Nee"] ho
    +++ p << ("diagnosis " ++ show diagnosis)
 
instance Storeable PigView where
  save (PigView pid _ _ name symptoms diagnosis) =
    updatePig pid (\(Pig _ vid _ _ diagnosis) -> 
                    (Pig pid vid (getStrVal name) (map getIntVal symptoms) diagnosis)) 

instance Initial PigView where
  initial = PigView initial initial initial initial initial initial




updateReplaceHtml :: String -> Html -> Html
updateReplaceHtml targetId newElement =
  thediv![strAttr "op" "replace", strAttr "targetId" targetId ] 
    << newElement

mkDiv str elt = thediv![identifier str] << elt

boxed html = thediv![thestyle "border:solid; border-width:1px; padding:4px;"] << html

--radioBox :: String -> [String] -> Int -> Html
radioBox id items selectedIx =
  [ radio id (show i) ! ( [strAttr "onChange" ("queueCommand('SetC "++id++" %22"++show i++"%22   ')") ]
                          ++ if i == selectedIx then [strAttr "checked" ""] else []) 
                          +++ item +++ br 
                        | (i, item) <- zip [0..] items ]


htmlPage title bdy = 
  thehtml $ concatHtml [ header $ thetitle $ toHtml title
                       , body bdy 
                       ]


-- Utils

lputStr :: MonadIO m => String -> m ()
lputStr = liftIO . putStr

lputStrLn :: MonadIO m => String -> m ()
lputStrLn = liftIO . putStrLn

constrain mn mx x = (mn `max` x) `min` mx