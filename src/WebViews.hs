{-# OPTIONS -fglasgow-exts #-}
module WebViews where

import Data.List
import Text.Html hiding (image)
import qualified Text.Html as Html
import Data.Generics
import Data.Char
import Data.Map (Map)
import qualified Data.Map as Map 
import Data.IntMap (IntMap)
import qualified Data.IntMap as IntMap 
import Debug.Trace
import System.Time
import Types
import Database
import Generics
import WebViewLib
import HtmlLib
import Control.Monad.State

mkRootView :: User -> Database -> Int -> ViewMap -> IO WebView
mkRootView user db sessionId viewMap =
  fmap assignIds $ runWebView user db viewMap [] 0 $ mkVisitsView sessionId
  -- TODO: id's here?


-- Visits ----------------------------------------------------------------------  

data VisitsView = 
  VisitsView Bool Int Int User [(String,String)] 
                 WebView [EditAction] (Widget Button) (Widget Button) (Widget Button) (Widget Button) 
                 (Maybe WebView) [CommentId] [WebView] (Maybe (Widget Button))
    deriving (Eq, Show, Typeable, Data)
  
instance Initial VisitsView where                 
  initial = VisitsView True 0 initial initial initial initial initial initial initial initial initial initial initial initial initial

modifyViewedVisit fn (VisitsView a v b c d e f g h i j k l m n) = 
  VisitsView a (fn v) b c d e f g h i j k l m n

mkVisitsView sessionId = mkWebView $
 \vid (VisitsView fresh oldViewedVisit _ _ _ _ _  _ _ _ _ _ oldCommentIds _ _) ->
  do { (visitIds, visits) <- withDb $ (\db -> unzip $ Map.toList $ allVisits db)
     ; let viewedVisit = constrain 0 (length visits - 1) oldViewedVisit
     ; today <- liftIO getToday             
     ; prevB   <- mkButton "Previous" (viewedVisit > 0)                   $ prev vid
     ; nextB   <- mkButton "Next"     (viewedVisit < (length visits - 1)) $ next vid 
     ; addB    <- mkButton "Add"      True                                $ addNewVisit today
     ; removeB <- mkButton "Remove" (not $ null visits) $
                    ConfirmEdit ("Are you sure you want to remove this visit?") $ 
                      DocEdit $ removeVisit (visitIds !! viewedVisit)
                  
     ; selectionActions <- sequence [ mkEditAction $ selectVisit vid p 
                                    | p <- [0..length visits - 1 ]
                                    ]
     ; user <- getUser
               
     ; loginOutView <- if user == Nothing then mkLoginView 
                                          else mkLogoutView
     
     ; visitView <-  if null visits then return Nothing
                     else do { vw <- mkVisitView (visitIds !! viewedVisit)
                             ; return (Just vw)
                             }
     ; commentIds <- withDb $ \db -> Map.keys (allComments db)
                                    
     ; commentViews <- sequence 
                          [ mkCommentView cid (not fresh && cid `notElem` oldCommentIds) 
                                               -- if this view is not fresh, and an
                          | cid <- commentIds  -- id was not in commentIds, it was
                          ]                    -- added and will be in edit mode
                                               -- BUG: unfortunately, this also happens when it
                                               -- was introduced by a different session :-(
                       
     ; mAddCommentButton <- case user of 
                              Nothing -> return Nothing 
                              Just (login,_) -> fmap Just $ mkButton "Add a comment" True $ 
                                                 addComment login today
     ;  return $ VisitsView False viewedVisit sessionId user
                 [ (zipCode visit, date visit) | visit <- visits ]
                 loginOutView selectionActions 
                 prevB nextB addB removeB  visitView commentIds commentViews mAddCommentButton
     }
 where prev vid = mkViewEdit vid $ modifyViewedVisit decrease
       next vid = mkViewEdit vid $ modifyViewedVisit increase
       
       addNewVisit today = DocEdit $ \db -> let ((Visit nvid _ _ _),db') = newVisit db 
                                            in  updateVisit nvid (\v -> v {date = today}) db' 
       selectVisit vi v = mkViewEdit vi $ modifyViewedVisit (const v)

       getToday =
         do { clockTime <-  getClockTime
            ; ct <- toCalendarTime clockTime
            ; return $ show (ctDay ct) ++ " " ++show (ctMonth ct) ++ " " ++show (ctYear ct) ++
                       ", "++show (ctHour ct) ++ ":" ++ reverse (take 2 (reverse $ "0" ++ show (ctMin ct)))
            }
         
       addComment login today = 
         DocEdit $ \db -> let ((Comment ncid _ _ _), db') = newComment db
                          in  updateComment ncid (\v -> v { commentAuthor = login
                                                          , commentDate = today}) db'

instance Presentable VisitsView where
  present (VisitsView _ viewedVisit sessionId user visits loginoutView selectionActions  
                      prev next add remove mv _ commentViews mAddCommentButton) =
    withBgColor (Rgb 235 235 235) $ withPad 5 0 5 0 $    
    with_ [thestyle "font-family: arial"] $
      mkTableEx [width "100%"] [] [valign "top"]
       [[ ([],
           (h2 << "Piglet 2.0")  +++
           ("List of all visits     (session# "++show sessionId++")") +++         
      p << (hList [ withBgColor (Rgb 250 250 250) $ roundedBoxed Nothing $ withSize 200 100 $ 
             (let rowAttrss = [] :
                              [ [withEditActionAttr selectionAction] ++
                                if i == viewedVisit then [ fgbgColorAttr (Rgb 255 255 255) (Rgb 0 0 255)
                                                           ] else [] 
                              | (i,selectionAction) <- zip [0..] selectionActions 
                              ]
                  rows = [ stringToHtml "Nr.    ", stringToHtml "Zip"+++nbspaces 3
                         , (stringToHtml "Date"+++nbspaces 10) ]  :
                         [ [stringToHtml $ show i, stringToHtml zipCode, stringToHtml date] 
                         | (i, (zipCode, date)) <- zip [1..] visits
                         ]
              in  mkTable [strAttr "width" "100%", strAttr "cellPadding" "2", thestyle "border-collapse: collapse"] 
                     rowAttrss [] rows
                 )])  +++
      p << (present add +++ present remove) 
      )
      ,([align "right"],
     hList[
      case user of
         Nothing -> present loginoutView 
         Just (_,name) -> stringToHtml ("Hello "++name++".") +++ br +++ br +++ present loginoutView
      ] )]
      ] +++
      p << ((if null visits then "There are no visits. " else "Viewing visit nr. "++ show (viewedVisit+1) ++ ".") +++ 
             "    " +++ present prev +++ present next) +++ 
      boxed (case mv of
               Nothing -> stringToHtml "No visits."
               Just pv -> present pv) +++
      h2 << "Comments" +++
      vList (map present commentViews) +++ 
      nbsp +++ (case mAddCommentButton of 
                  Nothing -> stringToHtml "Please log in to add a comment"
                  Just b  -> present b)
      
instance Storeable VisitsView where
  save _ = id
     



-- Visit -----------------------------------------------------------------------  

data VisitView = 
  VisitView VisitId (Widget Text) (Widget Text) Int (Widget Button) 
           (Widget Button) (Widget Button) [PigId] [String] [WebView]
    deriving (Eq, Show, Typeable, Data)

modifyViewedPig f (VisitView vid zipCode date viewedPig b1 b2 b3 pigs pignames mSubview) =
  VisitView vid zipCode date (f viewedPig) b1 b2 b3 pigs pignames mSubview

mkVisitView i = mkWebView $
  \vid (VisitView _ _ _ oldViewedPig _ _ _ _ _ mpigv) -> 
    do { (Visit visd zipcode date pigIds) <- withDb $ \db -> unsafeLookup (allVisits db) i
       ; let nrOfPigs = length pigIds
             viewedPig = constrain 0 (nrOfPigs - 1) $ oldViewedPig
       ; pignames <- withDb $ \db -> map (pigName . unsafeLookup (allPigs db)) pigIds
       
       ; zipT  <- mkTextField zipcode 
       ; dateT <- mkTextField date
       ; prevB <- mkButton "Previous" (viewedPig > 0)              $ previous vid
       ; nextB <- mkButton "Next"     (viewedPig < (nrOfPigs - 1)) $ next vid
       ; addB  <- mkButton "Add"      True                         $ addPig visd
                 
       ; pigViews <- sequence [ mkPigView vid i pigId viewedPig
                              | (pigId,i) <- zip pigIds [0..] 
                              ]
                                     
       ; return $ VisitView i zipT dateT viewedPig prevB  nextB addB pigIds pignames pigViews 
       }
 where -- next and previous may cause out of bounds, but on reload, this is constrained
       previous vi = mkViewEdit vi $ modifyViewedPig decrease
       next vi = mkViewEdit vi $ modifyViewedPig increase
       addPig i = DocEdit $ addNewPig i 
      
addNewPig vid db = let ((Pig newPigId _ _ _ _), db') = newPig vid db      
                   in  (updateVisit vid $ \v -> v { pigs = pigs v ++ [newPigId] }) db'

instance Presentable VisitView where
  present (VisitView vid zipCode date viewedPig b1 b2 b3 pigs pignames subviews) =
    p << ("Visit at zip code "+++ present zipCode +++" on " +++ present date) +++
    p << ("Visited "++ show (length pigs) ++ " pig" ++  pluralS (length pigs) ++ ": " ++ 
          listCommaAnd pignames) +++
    p << ((if null pigs 
           then stringToHtml $ "Not viewing any pigs.   " 
           else "Viewing pig nr. " +++ show (viewedPig+1) +++ ".   ")
           +++ present b1 +++ present b2) +++
    withPad 15 0 0 0 (hList $ map present subviews ++ [present b3] )

instance Storeable VisitView where
  save (VisitView vid zipCode date _ _ _ _ pigs pignames _) =
    updateVisit vid (\(Visit _ _ _ pigIds) ->
                      Visit vid (getStrVal zipCode) (getStrVal date) pigIds)

instance Initial VisitView where
  initial = VisitView (VisitId initial) initial initial initial initial initial initial initial initial initial
                       




-- Pig -------------------------------------------------------------------------  

data PigView = PigView PigId EditAction String (Widget Button) Int Int (Widget Text) (Widget Text) [Widget RadioView] (Either Int String) 
               deriving (Eq, Show, Typeable, Data)

mkPigView parentViewId pignr i viewedPig = mkWebView $ 
  \vid (PigView _ _ _ _ _ _ oldViewStateT _ _ _) ->
   do { (Pig pid vid name [s0,s1,s2] diagnosis) <- withDb $ \db -> unsafeLookup (allPigs db) i
      ; selectAction <- mkEditAction $ mkViewEdit parentViewId $ modifyViewedPig (\_ -> pignr)
      ; removeB <- mkButton "remove" True $ 
                     ConfirmEdit ("Are you sure you want to remove pig "++show (pignr+1)++"?") $ 
                       removePigAlsoFromVisit pid vid              
      ; nameT <- mkTextField name                             
      ; viewStateT <- mkTextField (getStrVal oldViewStateT)
      ; rv1 <- mkRadioView ["Pink", "Grey"] s0 True
      ; rv2 <- mkRadioView ["Yes", "No"]    s1 True
      ; rv3 <- mkRadioView ["Yes", "No"]    s2 (s1 == 0)
      ; return $ PigView pid selectAction (imageUrl s0) removeB  viewedPig pignr 
                         viewStateT nameT [rv1, rv2, rv3] diagnosis
      }
 where removePigAlsoFromVisit pid vid =
         DocEdit $ removePig pid . updateVisit vid (\v -> v { pigs = delete pid $ pigs v } )  
       
       imageUrl s0 = "pig"++pigColor s0++pigDirection++".png" 
       pigColor s0 = if s0 == 1 then "Grey" else ""
       pigDirection = if viewedPig < pignr then "Left" 
                      else if viewedPig > pignr then "Right" else ""

instance Presentable PigView where
  present (PigView pid _ _ b _ _ pignr name [] diagnosis) = stringToHtml "initial pig"
  present (PigView pid editAction imageUrl b viewedPig pignr viewStateT name [co, ab, as] diagnosis) =
    withEditAction editAction $    
      roundedBoxed (Just $ if viewedPig == pignr then Rgb 200 200 200 else Rgb 225 225 225) $
        (center $ image imageUrl) +++
        (center $ " nr. " +++ show (pignr+1)) +++
        p << (center $ (present b)) +++
        p << ("Name:" +++ present name) +++
        p << "Pig color: " +++
        present co +++
        p << "Has had antibiotics: " +++
        present ab +++
        p << "Antibiotics successful: " +++
        present as +++ br +++
        "Note: " +++ present viewStateT
    
instance Storeable PigView where
  save (PigView pid _ _ _ _ _ _ name symptoms diagnosis) =
    updatePig pid (\(Pig _ vid _ _ diagnosis) -> 
                    (Pig pid vid (getStrVal name) (map getSelection symptoms) diagnosis)) 

instance Initial PigView where
  initial = PigView (PigId initial) initial "" initial initial initial initial initial initial initial


data CommentView = CommentView CommentId Bool String String String
                               (Maybe (WebView)) (Maybe (WebView)) (Maybe (Widget Text))
                   deriving (Eq, Show, Typeable, Data)

instance Initial CommentView where
  initial = CommentView (CommentId initial) initial initial initial initial initial initial initial

modifyEdited fn (CommentView a edited b c d e f g) = (CommentView a (fn edited) b c d e f g)

mkCommentView commentId new = mkWebView $ \vid (CommentView _ edited' _ _ _ _ _ oldMTextfield) ->
 do { (Comment _ author date text) <- withDb $ \db -> unsafeLookup (allComments db) commentId
    
    ; let (_,name) = unsafeLookup users author
          
          edited = if new then True else edited' 
    
    ; submitButton <- mkLinkView "Submit" (mkViewEdit vid $ modifyEdited (const False))
    ; editButton <- mkLinkView "Edit" (mkViewEdit vid $ modifyEdited (const True))
    ; user <- getUser                
    ; let mEditAction = if edited
--                    then fmap Just $ mkButton "Submit" True $ mkViewEdit vid $ modifyEdited (const False)
                     then Just submitButton
                     else if userIsAuthorized author user 
                          then Just editButton
                          else Nothing
    ; removeAction <- mkLinkView "Remove" 
                        (ConfirmEdit ("Are you sure you want to remove this comment?") $ 
                          DocEdit $ removeComment commentId)
    ; let mRemoveAction = if userIsAuthorized author user 
                          then Just removeAction
                          else Nothing
      
    ; textArea <- mkTextArea text
    ; let mTextArea = if edited
                      then Just textArea
                      else Nothing
    
    ; return $ CommentView commentId edited name date text mEditAction mRemoveAction mTextArea
    }
 where userIsAuthorized authorLogin (Just (login, _)) = login == authorLogin || login == "martijn" 
       userIsAuthorized _           Nothing           = False

instance Storeable CommentView where
  save (CommentView cid edited _ date text _ _ mTextArea) =
    updateComment cid (\(Comment _ author _ _) -> 
                             let text' = if edited
                                        then case mTextArea of
                                               Just textArea -> getStrVal textArea
                                               Nothing    -> text
                                        else text
                                        
                             in  Comment cid author date text')

instance Presentable CommentView where
  present (CommentView _ edited author date text mEditAction mRemoveAction mTextArea) =
    thediv![thestyle "border:solid; border-width:1px; padding:0px; min-width: 550px;"] $
     (withBgColor (Rgb 225 225 225) $ --  thespan![thestyle "margin:4px;"] $
        (thespan![thestyle "margin:4px;"] $ "Posted by " +++ stringToHtml author +++ " on " +++ stringToHtml date)
        `hDistribute`
        ( withColor (Color "blue") $
          case mEditAction of
           Just ea -> present ea
           Nothing -> stringToHtml ""
         +++ nbspaces 2 +++
         case mRemoveAction of
           Just ra -> present ra
           Nothing -> stringToHtml "") -- TODO: why is it not possible to add spaces behind this?
     ) +++ 
     (withBgColor (Color "white") $ 
        
         if edited then case mTextArea of 
                          Nothing -> thespan![thestyle "margin:4px;"] $ -- TODO: figure out why margin above creates too much space  
                                       multiLineStringToHtml text
                          Just textArea -> withHeight 100 $ present textArea
         else thespan![thestyle "margin:4px;"] $ -- TODO: figure out why margin above creates too much space  
                multiLineStringToHtml text)