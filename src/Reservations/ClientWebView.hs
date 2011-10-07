{-# OPTIONS -XDeriveDataTypeable -XPatternGuards -XMultiParamTypeClasses -XScopedTypeVariables #-}
module Reservations.ClientWebView where

import Data.List
import Text.Html hiding (image)
import qualified Text.Html as Html
import Data.Generics
import Data.Char
import Data.Maybe
import Data.Map (Map)
import qualified Data.Map as Map 
import Data.IntMap (IntMap)
import qualified Data.IntMap as IntMap 
import Debug.Trace
import System.Time
import Data.Time.Calendar
import Types
import Generics
import WebViewPrim
import WebViewLib
import HtmlLib
import Control.Monad.State
import Server
import System.IO.Unsafe (unsafePerformIO) -- just for calendar stuff
import Reservations.Database

data ClientView = 
  ClientView Int (Maybe Date) (Maybe Time) [Widget (Button Database)] (Widget (TextView Database)) (Widget (TextView Database)) (Widget (Button Database)) (Widget (Button Database)) [Widget (Button Database)] [[Widget (Button Database)]] (Widget (Button Database)) 
  (Widget LabelView) (Widget LabelView) (Widget LabelView) (EditAction Database)
    String
    deriving (Eq, Show, Typeable, Data)
    
setClientViewNrOfPeople np (ClientView _ b c d e f g h i j k l m n o p) = (ClientView np b c d e f g h i j k l m n o p) 
setClientViewDate md (ClientView a _ c d e f g h i j k l m n o p) = (ClientView a md c d e f g h i j k l m n o p) 
setClientViewTime mt (ClientView a b _ d e f g h i j k l m n o p) = (ClientView a b mt d e f g h i j k l m n o p)
 
instance Initial ClientView where                 
  initial = ClientView initial initial initial initial initial initial initial initial initial initial initial initial initial initial initial initial

maxNrOfPeople = 10

mkClientView = mkWebView $
 \vid (ClientView oldNrOfP oldMDate oldMTime _ oldNameText oldCommentText _ _ _ _ _ _ _ _ _ _) ->
  do { clockTime <-  liftIO getClockTime -- this stuff is duplicated
     ; ct <- liftIO $ toCalendarTime clockTime
     ; let today@(currentDay, currentMonth, currentYear) = dateFromCalendarTime ct
           now   = (ctHour ct, ctMin ct)
           
     --; let (initialDate, initialTime) = (Nothing, Nothing)
     ; let (initialDate, initialTime) = (Just today, Just (19,30))
     
     ; let nrOfP = if oldNrOfP == 0 then 2 else oldNrOfP -- todo init is not nice like this
     ; let mDate = maybe initialDate Just oldMDate -- todo init is not nice like this
     
     ; reservations <- fmap Map.elems $ withDb $ \db -> allReservations db
     ; let timeAvailable tm = case mDate of
                                   Nothing -> True
                                   Just dt ->
                                     let reservationsAtTimeAndDay = filter (\r-> dt == date r && tm == time r) reservations
                                     in  sum (map nrOfPeople reservationsAtTimeAndDay) + nrOfP <= maxNrOfPeople
     ; let availableAtDateAndTime dt tm = let reservationsAtTimeAndDay = filter (\r-> dt == date r && tm == time r) reservations
                                          in  maxNrOfPeople - sum (map nrOfPeople reservationsAtTimeAndDay) + nrOfP

     ; let mTime = case oldMTime of
                     Nothing -> initialTime
                     Just oldTime -> if timeAvailable oldTime then oldMTime else Nothing
     
     ; nrButtons <- sequence [ mkButtonWithClick (show nr) True $ \bvid -> callFunction vid "setNr" [show nr]
                                  {- $ Edit $ viewEdit vid $ setClientViewNrOfPeople nr -} | nr <-[1..8]]
     
       -- TODO hacky
     ; nameText  <- mkTextField $ getStrVal (oldNameText) -- needed, even though in browser text is reused without it
     ; commentText  <- mkTextArea $ getStrVal (oldCommentText) -- at server side it is not
     
     ; todayButton <- mkButtonWithStyleClick ("Today ("++show currentDay++" "++showShortMonth currentMonth++")") True "width:100%" $ const ""  {-Edit $ viewEdit vid $ setClientViewDate (Just today) -} 
     ; tomorrowButton <- mkButtonWithStyleClick "Tomorrow" True "width:100%" $ const "" {- Edit $ viewEdit vid $ setClientViewDate (Just $ addToDate today 1) -}
     ; dayButtons <- sequence [ mkButtonWithClick (showShortDay . weekdayForDate $ dt) True $ const "" {- Edit $ viewEdit vid $ setClientViewDate (Just dt) -}
                              | day <-[2..7], let dt = addToDate today day ]
     
     -- todo: cleanup once script stuff is in monad (becomes  sequence [ sequence [ mkButton; script ..] ]

     ; timeButtonssTimeEditss <- 
         sequence [ sequence [ do { b <- mkButtonWithStyleClick (showTime tm) (timeAvailable tm) "width:100%" $ const "" 
                                                {- Edit $ viewEdit vid $ setClientViewTime (Just tm) -}
                                  ; return (b, onClick b $ callFunction vid "setTime" [ "{hour:"++show hr ++",min:"++show mn++",index:"++show ix++"}"])
                                  }     
                             | (mn,j) <-zip [0,30] [0..], let tm = (hr,mn), let ix = 2*i+j ]
                  | (hr,i) <-  zip [18..23] [0..] ] 
     ; let (timeButtonss, timeEditss) = unzip . map unzip $ timeButtonssTimeEditss
     ; let timeEdits = concat timeEditss  -- TODO, we want some way to do getStr on both labels and Texts 
     ; nrOfPeopleLabel <- mkLabelView "nrOfPeopleLabel" 
     ; dateLabel <- mkLabelView "dataLabel" 
     ; timeLabel <- mkLabelView "timeLabel" 
      
     ; confirmButton <- mkButtonEx "Confirm" True {- (isJust mDate && isJust mTime)-} "width: 100%" (const "") $ Edit $ return ()
     ; submitAction <- mkEditActionEx $ \args@[nameStr, nrOfPeopleStr, dateIndexStr, timeStr, commentStr] ->
         Edit $ do { debugLn $ "submit action executed "++show args
                   ;
                   -- todo constructing date/time from indices duplicates work
                   ; debugLn $ "Values are "++nameStr++" "++dateIndexStr++" "++timeStr
                   ; let nrOfPeople = read nrOfPeopleStr
                   ; debugLn $ "nrOfPeople "++show nrOfPeople
                   ; let date = addToDate today (read dateIndexStr)
                   ; debugLn $ "date "++show date

                   ; let time = read timeStr
                   ; debugLn $ "time "++show time
                   
                   ; docEdit $ \db -> 
                        let (Reservation rid _ _ _ _ _, db') = newReservation db
                            db'' = updateReservation rid (const $ Reservation rid date time nameStr nrOfPeople commentStr) db
                        in  db''
                   }
     ; let datesAndAvailabilityDecl = "availability = ["++ -- todo: should be declared with declareVar for safety
             intercalate "," [ "{date: \""++showDay (weekdayForDate  d)++", "++showShortDate d++"\","++
                               " availables: ["++intercalate "," [ show $ availableAtDateAndTime d (h,m)
                                                                | h<-[18..23], m<-[0,30]]++"]}" | i <-[0..7], let d = addToDate today i ] 
             ++"];"
             
     
     ; return $ ClientView nrOfP mDate mTime nrButtons nameText commentText todayButton tomorrowButton dayButtons timeButtonss confirmButton 
                           nrOfPeopleLabel dateLabel timeLabel submitAction
                  $ jsScript --"/*"++show (ctSec ct)++"*/" ++
                  [ datesAndAvailabilityDecl
                    -- maybe combine these with button declarations to prevent multiple list comprehensions
                    -- maybe put script in monad and collect at the end, so we don't have to separate them so far (script :: String -> WebViewM ())
                  , concat [ onClick nrButton $ callFunction vid "setNr" [show nr]| (nr,nrButton) <- zip [1..] nrButtons]
                  , concat [ onClick button $ callFunction vid "setDate" [ show dateIndex ] 
                           | (dateIndex,button) <- zip [0..] $ [todayButton, tomorrowButton]++dayButtons ]
                  , concat timeEdits
                  , inertTextView nameText
                  , inertTextView commentText
                  , onClick confirmButton $ jsScript 
                                          [ callServerEditAction submitAction ["escape("++jsGetElementByIdRef (widgetGetViewRef nameText)++".value)", readVar vid "selectedNr"
                                                                              , readVar vid "selectedDate", "'('+"++readVar vid "selectedTime"++".hour+','+"++readVar vid "selectedTime"++".min+')'"
                                                                              ,"escape("++jsGetElementByIdRef (widgetGetViewRef commentText)++".value)"]
                                          , callFunction vid "reset" []
                                          , callFunction vid "disenable" []] 
                  , jsFunction vid "reset" []
                                          [ callFunction vid "setNr" ["null"]
                                          , callFunction vid "setDate" ["null"]
                                          , callFunction vid "setTime" ["null"]
                                          , jsGetElementByIdRef (widgetGetViewRef nameText)++".value = \"\""
                                          , jsGetElementByIdRef (widgetGetViewRef commentText)++".value = \"\""
                                          ] 
                  , jsFunction vid "inputValid" [] [ "console.log(\"inputValid: \"+"++jsGetElementByIdRef (widgetGetViewRef nameText)++".value)"
                                                   , "return "++readVar vid "selectedNr"++"!=null && "++readVar vid "selectedDate"++"!=null && "++readVar vid "selectedTime"++"!=null && "++
                                                                jsGetElementByIdRef (widgetGetViewRef nameText)++".value != \"\""
                                                   ] 
                  , declareVar vid "selectedNr" "null"
                  , jsFunction vid "setNr" ["nr"] [ "console.log(\"setNr (\"+nr+\") old val: \", "++readVar vid "selectedNr"++")"
                                                  , writeVar vid "selectedNr" "nr"
                                                  , "nrStr = nr==null ? \"Please select nr of people\" : 'Nr of people: '+nr"
                                                  , jsGetElementByIdRef (widgetGetViewRef nrOfPeopleLabel)++".innerHTML = nrStr"
                                                  , callFunction vid "disenable" [] ]
                  , declareVar vid "selectedTime" "null"
                  , declareVar vid "selectedTimeIndex" "null"
                  , jsFunction vid "setTime" ["time"] [ "console.log(\"setTime \"+time, "++readVar vid "selectedTime"++")"
                                                      , writeVar vid "selectedTime" "time"
                                                      , "timeStr = time==null ? \"Please select a time\" : 'Time: ' + time.hour +\":\"+ (time.min<10?\"0\":\"\") + time.min"
                                                      , writeVar vid "selectedTimeIndex" "time == null ? null : time.index"
                                                      , jsGetElementByIdRef (widgetGetViewRef timeLabel)++".innerHTML = timeStr"
                                                      , callFunction vid "disenable" [] ] 
                  , declareVar vid "selectedDate" "null"
                  , jsFunction vid "setDate" ["date"] [ "console.log(\"setDate \"+date, "++readVar vid "selectedDate"++")"
                                                      , writeVar vid "selectedDate" "date"
                                                      , "dateStr = date==null ? \"Please select a date\" : 'Date: ' + availability[date].date"
                                                      , jsGetElementByIdRef (widgetGetViewRef dateLabel)++".innerHTML = dateStr"
                                                      , callFunction vid "disenable" [] ] 
                  , jsFunction vid "disenable" [] [ "console.log(\"disenable: \","++readVar vid "selectedNr"++","++readVar vid "selectedDate"++","++readVar vid "selectedTime" ++" )"
                                                  , "var availables = "++readVar vid "selectedDate"++" == null ? null : availability["++readVar vid "selectedDate"++"].availables"
                                                  , "var buttonIds = [\""++intercalate "\",\"" (map (show . getViewId) $ concat timeButtonss)++"\"]"
                                                  , jsFor "var i=0;i<buttonIds.length;i++" $ 
                                                      [ "document.getElementById(buttonIds[i]).disabled = availables == null ? true : availables[i]<"++readVar vid "selectedNr"
                                                      ]
                                                  , jsIf (readVar vid "selectedTimeIndex"++" && availables && availables["++readVar vid "selectedTimeIndex"++"] <"++readVar vid "selectedNr") 
                                                      [ callFunction vid "setTime" ["null"] ] -- if the selected time becomes unavailable, deselect
                                                      -- TODO this deselect is implemented horribly, with the extra index field in time. Can this be done more elegantly?
                                                  , jsGetElementByIdRef (widgetGetViewRef confirmButton)++".disabled = !"++callFunction vid "inputValid" []
                                                  ]
                    -- todo: handle when time selection is disabled because of availability (on changing nr of persons or date)
                  , onKeyUp nameText $ callFunction vid "disenable" []
                  , callFunction vid "reset" []
                  ]                                   
     }


-- todo comment has hard-coded width. make constant for this
instance Presentable ClientView where
  present (ClientView nrOfP mDate mTime nrButtons nameText commentText todayButton tomorrowButton dayButtons timeButtonss confirmButton
                      nrOfPeopleLabel dateLabel timeLabel _ script) = 
    vList [ hList [ stringToHtml "Name:", hSpace 4, present nameText]
          , vSpace 10
          , present nrOfPeopleLabel
          , hListEx [width "100%"] $ map present nrButtons
          , vSpace 10
          --, stringToHtml $ maybe "Please choose a date" (\d -> (showDay . weekdayForDate $ d) ++ ", " ++ showShortDate d) mDate
          , present dateLabel
          , hListEx [width "100%"] [ present todayButton, present tomorrowButton]
          , hListEx [width "100%"] $ map present dayButtons
          , vSpace 10
          , present timeLabel
          --, stringToHtml $ maybe "Please select a time" (\d -> showTime d) mTime
          , simpleTable [width "100%",cellpadding 0, cellspacing 0] [] $ map (map present) timeButtonss
          , vSpace 10
          , stringToHtml "Comments:"
          , present commentText
          , vSpace 10
          , present confirmButton ] +++           
          mkScript script
 
instance Storeable Database ClientView where
  save _ = id

--- Utils

showMonth m = show (toEnum (m-1) :: System.Time.Month)
showDate (d,m,y) = show d ++ " " ++ showMonth m ++ " " ++ show y
showShortDate (d,m,y) = show d ++ " " ++ showShortMonth m ++ " " ++ show y
showTime (h,m) = (if h<10 then " " else "") ++ show h ++ ":" ++ (if m<10 then "0" else "") ++ show m

daysToWeeks days = if length days < 7 then [days]
                   else take 7 days : daysToWeeks (drop 7 days)

-- TODO: before using seriously, check unsafePerformIO (or remove)
calendarTimeForDate (day, month, year) =
 do { clockTime <-  getClockTime -- first need to get a calendar time in this time zone (only time zone is used, so ok to unsafePerformIO)
    ; today <- toCalendarTime clockTime
    ; return $ today {ctDay= day, ctMonth = toEnum $ month-1, ctYear = year, ctHour = 12, ctMin = 0, ctPicosec = 0}
    }
    
dateFromCalendarTime ct = (ctDay ct, 1+fromEnum (ctMonth ct), ctYear ct)
    
weekdayForDate date = unsafePerformIO $ -- unsafePerformIO is okay, since we don't use the current time/date anyway
 do { ct <- calendarTimeForDate date
    ; ctWithWeekday <- toCalendarTime $ toClockTime ct
    ; return $ (fromEnum (ctWDay ctWithWeekday) -1) `mod` 7 + 1 -- in enum, Sunday is 0 and Monday is 1, we want Monday = 1 and Sunday = 7
    } 

addToDate date days = unsafePerformIO $ -- unsafePerformIO is okay, since we don't use the current time/date anyway
 do { ct <- calendarTimeForDate date
    ; ct' <- toCalendarTime $ addToClockTime (noTimeDiff {tdDay = days}) $ toClockTime ct 
    ; return $ dateFromCalendarTime ct' 
    }
    
showDay :: Int -> String 
showDay d = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]!!(d-1) 

showShortDay :: Int -> String 
showShortDay d = ["Mo","Tu","We","Th","Fr","Sa","Su"]!!(d-1) 

showShortMonth :: Reservations.Database.Month -> String
showShortMonth m = ["Jan.", "Feb.", "Mar.", "Apr.", "May", "June", "July", "Aug.","Sept.", "Oct.", "Nov.", "Dec."]!!(m-1)

 -- HACK
getTextContents :: Widget (TextView Database) -> EditM Database String
getTextContents text =
 do { (sessionId, user, db, rootView, pendingEdit) <- get
    ; return $ getTextByViewIdRef (undefined :: Database{-dummy arg-}) (widgetGetViewRef text) rootView
    } 

-- probably to be deleted, labels do not need to be accessed    
getLabelContents :: Widget LabelView -> EditM Database String
getLabelContents text =
 do { (sessionId, user, db, rootView, pendingEdit) <- get
    ; return $ getLabelContentsByViewIdRef (undefined :: Database{-dummy arg-}) (widgetGetViewRef text) rootView
    } 
    
getLabelContentsByViewIdRef :: forall db v . (Typeable db, Data v) => db -> ViewIdRef -> v -> String
getLabelContentsByViewIdRef _ (ViewIdRef i) view =
  let (LabelView _ str) :: LabelView = getLabelViewByViewId (ViewId i) view
  in  str


getJSVarContents :: Widget JSVar -> EditM Database String
getJSVarContents text =
 do { (sessionId, user, db, rootView, pendingEdit) <- get
    ; return $ getJSVarContentsByViewIdRef (undefined :: Database{-dummy arg-}) (widgetGetViewRef text) rootView
    } 
    
getJSVarContentsByViewIdRef :: forall db v . (Typeable db, Data v) => db -> ViewIdRef -> v -> String
getJSVarContentsByViewIdRef _ (ViewIdRef i) view =
  let (JSVar _ _ value) :: JSVar = getJSVarByViewId (ViewId i) view
  in  value

callServerEditAction ea args = "queueCommand('PerformEditActionC ("++show (getActionViewId ea)++") [\"'+"++
                                      intercalate "+'\",\"'+" args ++"+'\"]')"
