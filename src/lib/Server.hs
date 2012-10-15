{-# LANGUAGE ScopedTypeVariables #-}
module Server where

import Happstack.Server
import System.IO
import Data.List
import Data.List.Split
import Data.Maybe
import Data.IORef
import Data.ByteString.Char8 (unpack)
import Control.Concurrent
import Control.Monad
import Control.Monad.Trans
import Control.Monad.Reader
import Control.Monad.State
import Data.Generics
import Data.Map (Map)
import qualified Data.Map as Map
import Data.IntMap (IntMap)
import qualified Data.IntMap as IntMap 
import System.Time (getClockTime)
import System.Posix.Time
import System.Posix.Types
import System.Exit
import System.Environment (getArgs)
import BlazeHtml hiding (dir, method)
import Control.Exception
import qualified Data.ByteString.Char8 as Bytestring
import qualified Codec.Binary.Base64.String as Base64

import Types
import Generics
import WebViewPrim
import Incrementality
import HtmlLib
import ObloUtils
import Utils


{-
TODO: why are there so many theDatabase refs? when is this thing initialized and when is it read from disk?
see if passing down mkRootView, dbFilename, theDatabase and users can be improved (maybe in state?)
             

maybe use type class?

check dummy args (witnesses?) in Generics for replace and getTextByViewIdRef

bug: webview fields that are not presented still show up in interface

todo: initials are annoying, figure out TH stuff and write down what they are for

viewEdit is completetely untyped!!

two thestyle's together don't work, so thestyle .. and later colorAttr should be unified in one thestyle 


Check lenses
Check relation to google toolkit. Maybe we can use stuff from it?



Happstack notes
Server error: Prelude.last: empty list
is the error you get when fileServe cannot find a file

check caching in case of problems

ServerPart is basically a Reader monad for requests

The Ok part of the WebT monad contains a function out that is applied to the responses before
sending them to the client. If the result is of type Response, set/addHeader can be fmapped to
the monad, but it will only do something if the header is not set in the out part of Ok.

Header modifications must therefore be applied to out rather than be fmapped to the monad.
-}

{-

Buttons that are not found are ignored
ConfirmDialog is ignored if dialog is not here
TODO: make confirmDialog more robust


-}
type GlobalState db = (db, Sessions db, SessionCounter)

initGlobalState theDatabase = (theDatabase, IntMap.empty, 0)

type GlobalStateRef db = IORef (GlobalState db)

type ServerInstanceId = EpochTime

type SessionCounter = Int

type Sessions db = IntMap (User, WebView db, Maybe (EditCommand db), HashArgs)

server :: (Data db, Typeable db, Show db, Read db, Eq db) =>
          Int -> String -> RootViews db -> [String] -> String -> IO (db) -> Map String (String, String) -> IO ()
server portNr title rootViews scriptFilenames dbFilename mkInitialDatabase users =
 do { hSetBuffering stdout NoBuffering -- necessary to run server in Eclipse
    ; time <- getClockTime
    ; args <- getArgs
    ; let debug = case args of
                    []          -> True
                    ["nodebug"] -> False
                    _           -> error "Incorrect parameters: only 'nodebug' is allowed"
        
    ; putStrLn $ "\n\n### Started WebViews server "++show title++" (port "++show portNr++")\n"++show time ++"\n"++
                 "Debugging: "++(if debug then "ON" else "OFF")++"\n\n"
    ; serverSessionId <- epochTime

    ; mDatabase <-
       do { fh <- openFile dbFilename ReadMode
          ; dbStr <- hGetContents fh
          ; seq (length dbStr) $ return ()
          ; hClose fh
          ; return $ readMaybe dbStr
          } `Control.Exception.catch` \exc ->
       do { putStrLn $ "Problem opening "++dbFilename++":\n"
          ; putStrLn $ "Exception "++ show (exc :: SomeException)
          ; putStrLn $ "\nUsing initial database."
          ; db <- mkInitialDatabase
          ; return $ Just db
          }

    ; theDatabase <- case mDatabase of -- if the database exists but cannot be read, something is wrong and we exit to prevent overwriting it
                       Just db -> return db
                       Nothing -> do { putStrLn $ "Database file "++dbFilename++" cannot be read, exiting server.\n"
                                     ; exitWith $ ExitFailure 1
                                     }

    ; globalStateRef <- newIORef $ initGlobalState theDatabase

    ; simpleHTTP nullConf { port = portNr, logAccess = Nothing {-Just logWebViewAccess-} } $
        msum (handlers debug title rootViews scriptFilenames dbFilename theDatabase users serverSessionId globalStateRef)
    }
{-
handle:
http://<server url>/favicon.ico         response: <executable dir>/favicon.icome>
http://<server url>/handle?commands=Commands ..                    
                                        response: from handleCommands
http://<server url>/                    response: <executable dir>/WebViews.html
-}

-- todo: maybe we can use this for debugging
logWebViewAccess :: String -> String -> t -> String -> Int -> Integer -> String -> String -> IO ()
logWebViewAccess clientIP b _ c d e f g =
 do { putStrLn $ show clientIP ++ " " ++ show b ++ " " ++ show c ++ " " ++ show d ++ " " ++ show e ++ " " ++ show g ++ " " ++ show g
    }


instance FromData Commands where
  fromData = liftM readCommand (look "commands")

readCommand s = case readMaybe s of
                  Just cmds -> cmds
                  Nothing   -> SyntaxError s

instance FromData Int where
  fromData = liftM readInt (look "requestId")

readInt s = fromMaybe (-1) (readMaybe s)

handlers :: (Data db, Show db, Eq db) => Bool -> String -> RootViews db -> [String] -> String -> db -> Map String (String, String) -> ServerInstanceId -> GlobalStateRef db -> [ServerPart Response]
handlers debug title rootViews scriptFilenames dbFilename theDatabase users serverSessionId globalStateRef = 
  (do { neverExpires
      ; msum [ dir "favicon.ico" $  serveDirectory DisableBrowsing [] "favicon.ico"
             , dir "scr" $  serveDirectory DisableBrowsing [] "scr"
             , dir "img" $ serveDirectory DisableBrowsing [] "img"
             ]
      }) :
  [ dir "handle" $ 
      withData (\cmds -> do { clientIp <- getClientIp 
                            ; requestIdData <- getData
                            ; requestId <- case requestIdData of
                                            Right i |  i/=(-1)  -> return i
                                            Right i | otherwise -> do { io $ putStrLn $ "Unreadable requestId from " ++ clientIp;    mzero }
                                            Left err            -> do { io $ putStrLn $ "No requestId in request from " ++ clientIp; mzero }
                                
                            ; io $ putStrLn $ "RequestId " ++ show (requestId :: Int) ++ " (" ++ clientIp ++ ")"
                            ; method GET >> nullDir >> session rootViews dbFilename theDatabase users serverSessionId globalStateRef requestId cmds
                            })
  , serveRootPage -- this generates an init event, which will handle hash arguments
  ] 
 where serveRootPage :: ServerPart Response
       serveRootPage =
        do { clientIp <- getClientIp 
           ; Request{rqHeaders=hdrs} <- askRq
           ; io $ putStrLn $ "Root requested (" ++ clientIp ++ ")"
           ; io $ putStrLn $ "User agent: " ++ maybe "<no user agent header>" unpack (getHeader "user-agent" hdrs) ++ "\n\n"
           ; templateStr <- io $ readUTFFile $ "htmlTemplates/WebViews.html"
           ; let linksAndScripts = concatMap mkScriptLink scriptFilenames
           ; let debugVal = if debug then "true" else "false"
           ; let htmlStr = substitute [("TITLE",title),("LINKSANDSCRIPTS",linksAndScripts),("DEBUG", debugVal)] templateStr
           ; ok $ setHeader "Content-Type" "text/html; charset=utf-8" $ toResponse htmlStr
           } 
           
       getClientIp :: ServerPart String
       getClientIp =
        do { Request{rqHeaders=hdrs,rqPeer = (actualClientIp,_)} <- askRq
           ; return $ case getHeader "x-forwarded-for" hdrs of
                        Nothing                -> actualClientIp
                        Just forwardedClientIp -> unpack forwardedClientIp
           }
       mkScriptLink filename = case reverse . takeWhile (/='.') . reverse $ filename of
                                 "js"  -> "  <script type=\"text/javascript\" src=\"/scr/js/"++filename++"\"></script>\n"
                                 "css" -> "  <link href=\"/scr/css/"++filename++"\" rel=\"stylesheet\" type=\"text/css\" />\n"
                                 ext   -> error $ "Unhandled script extension: "++filename
{-
This stuff may not hold for HappStack 6
 TODO: why does exactdir "/handle" not work?
   TODO: fix syntax error in command

this get command works (there should not be an unescaped space between Commands and [Init]
GET /handle?commands=Commands[Init] HTTP/1.1

Response:
HTTP/1.1 200 OK
Connection: Keep-Alive
Content-Length: 32597
Content-Type: text/html
Date: Sat, 16 May 2009 18:22:28 GMT
Server: Happstack/0.2.1
Set-Cookie: webviews="(1242497513,2)";Max-Age=3600;Path=/;Version="1"

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 FINAL//EN">
...

-}

type SessionCookie = (String, String)

session :: (Data db, Show db, Eq db) => RootViews db -> String -> db -> Map String (String, String) -> ServerInstanceId -> GlobalStateRef db -> Int -> Commands -> ServerPart Response
session rootViews dbFilename theDatabase users serverInstanceId globalStateRef requestId cmds =
 do { mCookieSessionId <- parseCookieSessionId serverInstanceId
      
--        ; lputStrLn $ show rq
        ; sessionId <- case mCookieSessionId of 
            Nothing  -> createNewSessionState theDatabase globalStateRef serverInstanceId
            Just key -> do { --lputStrLn $ "Existing session "++show key
                           ; return key
                           }
             
        ; sessionStateRef <- retrieveSessionState globalStateRef sessionId 
                                  
        ; responseHtml <- sessionHandler rootViews dbFilename theDatabase users sessionStateRef requestId cmds              
        
        ; storeSessionState globalStateRef sessionId sessionStateRef
        
        ; io $ putStrLn "Done\n\n"
        ; ok $ toResponse $ responseHtml
        }
 
parseCookieSessionId :: ServerInstanceId -> ServerPart (Maybe SessionId)
parseCookieSessionId serverInstanceId = 
 do { rq <- askRq
             
    ; let cookieMap = rqCookies rq
    ; let mCookieSessionId = case lookup "webviews" cookieMap of
                      Nothing -> Nothing -- * no webviews cookie on the client
                      Just c  -> case readMaybe (cookieValue c) :: Maybe (EpochTime, Int) of
                                   Nothing               -> Nothing -- * ill formed cookie on client
                                   Just (serverTime, key) -> 
                                     if serverTime /= serverInstanceId
                                     then Nothing  -- * cookie from previous WebViews run
                                     else Just key -- * correct cookie for this run
    ; return mCookieSessionId
    }

mkInitialRootView :: (Data db, Typeable db) => db -> IO (WebView db)
mkInitialRootView theDatabase = runWebView Nothing theDatabase Map.empty [] 0 (-1) [] $ mkWebView (\_ _ -> return ()) 

-- this creates a WebView with stubid 0 and id 1
-- for now, we count on that in the client
-- TODO: change this to something more robust
-- todo: use different id

createNewSessionState :: Data db => db -> GlobalStateRef db -> ServerInstanceId -> ServerPart SessionId
createNewSessionState theDatabase globalStateRef serverInstanceId = 
 do { (database, sessions,sessionCounter) <- io $ readIORef globalStateRef
    ; let sessionId = sessionCounter
    ; io $ putStrLn $ "New session: "++show sessionId
    ; addCookie Session (mkCookie "webviews" $ show (serverInstanceId, sessionId))
    -- cookie lasts for one hour
 
    ; initialRootView <- io $ mkInitialRootView theDatabase
                        
                       -- for debugging, begin with user martijn  
    ; let newSession = (Just ("martijn", "Martijn Schrage") {- Nothing -}, initialRootView, Nothing, [])
    ; let sessions' = IntMap.insert sessionId newSession sessions
   
    ; io $ writeIORef globalStateRef (database, sessions', sessionCounter + 1)
    
    ; return sessionId
    }
 
retrieveSessionState :: GlobalStateRef db -> SessionId -> ServerPart (SessionStateRef db)
retrieveSessionState globalStateRef sessionId =
 do { (database, sessions, sessionCounter) <- io $ readIORef globalStateRef
    --; lputStrLn $ "\n\nNumber of active sessions: " ++ show sessionCounter                                          
    ; sessionState <- case IntMap.lookup sessionId sessions of -- in monad to show errors (which are not caught :-( )
                             Nothing                      -> do { io $ putStrLn "\n\n\n\nInternal error: Session not found\n\n\n\n\n"
                                                                ; error "Internal error: Session not found"
                                                                }
                             Just (user, rootView, pendingEdit, hashArgs) -> 
                               return $ SessionState sessionId user database rootView pendingEdit hashArgs
    ; io $ newIORef sessionState
    }      
 
storeSessionState :: GlobalStateRef db -> SessionId -> SessionStateRef db -> ServerPart ()
storeSessionState globalStateRef sessionId sessionStateRef =
 do { (_, sessions, sessionCounter) <- io $ readIORef globalStateRef
    ; SessionState _ user' database' rootView' pendingEdit' hashArgs <- io $ readIORef sessionStateRef
    ; let sessions' = IntMap.insert sessionId (user', rootView', pendingEdit', hashArgs) sessions                                          
    ; io $ writeIORef globalStateRef (database', sessions', sessionCounter)
    }
 
sessionHandler :: (Data db, Show db, Eq db) => RootViews db -> String -> db -> Map String (String, String) -> SessionStateRef db -> Int -> Commands -> ServerPart Html
sessionHandler rootViews dbFilename theDatabase users sessionStateRef requestId cmds = io $  
 do { --putStrLn $ "Received commands" ++ show cmds
    
    ; SessionState _ _ db oldRootView' _ _ <- readIORef sessionStateRef
    
    ; let isInitCommand (Init _ _) = True
          isInitCommand _          = False
          
    -- TODO: this may cause problems Init is part of multiple commands
    ; oldRootView <- if any isInitCommand $ getCommands cmds 
                     then mkInitialRootView theDatabase 
                     else return oldRootView' 
 
          
    ; response <- handleCommands rootViews users sessionStateRef cmds
    -- handleCommands modifies the state              
                  
    ; responseHtml <- case response of
        ViewUpdate ->
         do { rootViewWithoutIds <- getRootView sessionStateRef
              -- this is the modified rootView                      
                                    
            -- save the database if there was a change
            ; SessionState{getSStateDb=db'} <- readIORef sessionStateRef
            ; if db /= db' then 
               do { fh <- openFile dbFilename WriteMode
                  ; hPutStr fh $ show db'
                  ; hClose fh
                  }
               else return ()
            
            ; let rootView = assignAllUniqueIds oldRootView rootViewWithoutIds 
            
            --; putStrLn "seq'ing rootView"
            ; seq (length (show rootView)) $ return ()
            --; putStrLn "seq'ed rootView"
            
            ; setRootView sessionStateRef rootView
              
              
            ; (responseHtml, rootView') <- mkIncrementalUpdates oldRootView rootView
            -- rootView' has different id's (the ones that were not updated and hence are
            -- restored to their previous values)
                                           
            --; putStrLn $ "View tree:\n" ++ drawWebNodes (WebViewNode rootView') 
            --; putStrLn $ "rootView:\n" ++ show rootView'
            ; setRootView sessionStateRef rootView'
            --; putStrLn $ "database:\n" ++ show db
            --; putStrLn $ "\n\n\nresponse = \n" ++ show responseHtml
            --; putStrLn $ "View tree':\n" ++ drawWebNodes (WebViewNode rootView') 
            --; putStrLn $ "Sending response sent to client: " ++
            --              take 10 responseHTML ++ "..."
            --; putStrLn "seq'ing response"
            ; seq (length (show responseHtml)) $ return ()
            --; putStrLn "end session handler"
            ; return $ responseHtml
            }
        Alert str -> 
          return $ [ div_ ! strAttr "op" "alert"
                          ! strAttr "text" str
                          $ noHtml ] 
        Confirm str  -> 
          return $ [ div_ ! strAttr "op" "confirm"
                          ! strAttr "text" str
                          $ noHtml ] 
    
    ; return $ div_ ! id_ "updates" ! strAttr "responseId" (show requestId) $ toHtml responseHtml
    } `Control.Exception.catch` \exc ->
       do { let exceptionText = 
                  "\n\n\n\n###########################################\n\n\n" ++
                  "Exception: " ++ show (exc :: SomeException) ++ "\n\n\n" ++
                  "###########################################" 
          
          ; putStrLn exceptionText
          ; return $ div_ ! id_ "updates" ! strAttr "responseId" (show requestId) $
                      (div_ ! strAttr "op" "exception"
                            ! strAttr "text" exceptionText
                            $ noHtml)                       
          }
 where evaluateDbAndRootView sessionStateRef =
        do { dbRootView <- io $ readIORef sessionStateRef
           ; seq (length $ show dbRootView) $ return ()
           }

 
data ServerResponse = ViewUpdate | Alert String | Confirm String deriving (Show, Eq)

-- handle each command in commands and send the updates back
handleCommands rootViews users sessionStateRef (SyntaxError cmdStr) =
  error $ "Syntax error in commands from client: "++cmdStr 
handleCommands rootViews users sessionStateRef (Commands [command]) = handleCommand rootViews users sessionStateRef command
handleCommands rootViews users sessionStateRef (Commands commands) = 
 do { responses <- mapM (handleCommand rootViews users sessionStateRef) commands
    ;  case dropWhile (== ViewUpdate) responses of
         []         -> return ViewUpdate
         [response] -> return response
         _          -> error "Non View update commmand followed by other commands"
                    -- probably okay if they are all ViewUpdates
    } -- TODO: think of a way to handle multiple commands and dialogs etc.
      --       make sure that id's are not generated between commands


mkRootView ::Data db => RootViews db -> String -> HashArgs -> User -> db -> SessionId -> ViewMap db -> IO (WebView db)
mkRootView rootViews rootViewName args user db sessionId viewMap =
  runWebView user db viewMap [] 0 sessionId args $ mkMainView
 where mkMainView = case lookup rootViewName rootViews of
                      Nothing -> error $ "Unknown view: "++rootViewName
                      Just mkV -> mkV

handleCommand :: forall db . Data db => RootViews db -> Map String (String, String) -> SessionStateRef db -> Command -> IO ServerResponse
handleCommand rootViews _ sessionStateRef (Init rootViewName hashArgs) =
 do { putStrLn $ "Init " ++ show rootViewName ++ " " ++ show hashArgs
    ; setSessionHashArgs sessionStateRef hashArgs
    ; SessionState sessionId user db oldRootView _ _ <- readIORef sessionStateRef
    ; rootView <- io $ mkRootView rootViews rootViewName hashArgs user db sessionId (mkViewMap oldRootView)
    ; setRootView sessionStateRef rootView
     
    ; return ViewUpdate
    }
handleCommand rootViews _ sessionStateRef (HashUpdate rootViewName hashArgs) = -- fired when hash hash changed in client
 do { putStrLn $ "HashUpdate " ++ show rootViewName ++ " " ++ show hashArgs
    ; setSessionHashArgs sessionStateRef hashArgs
    ; SessionState sessionId user db oldRootView _ _ <- readIORef sessionStateRef
    ; rootView <- io $ mkRootView rootViews rootViewName hashArgs user db sessionId (mkViewMap oldRootView)
    ; setRootView sessionStateRef rootView
     
    ; return ViewUpdate
    }
handleCommand _ _ sessionStateRef Refresh =
 do { -- putStrLn "Refresh"
    ; reloadRootView sessionStateRef
    ; return ViewUpdate
    }
handleCommand _ _ sessionStateRef Test =
 do { sState <- readIORef sessionStateRef
    ; return ViewUpdate
    }
handleCommand _ users sessionStateRef (SetC viewId value) =
 do { SessionState sessionId user db rootView pendingEdit hashArgs <- readIORef sessionStateRef      
    ; putStrLn $ "Performing: "++show (SetC viewId value)
    --; putStrLn $ "RootView:\n" ++ show rootView ++"\n\n\n\n\n"
    ; let rootView' = applyUpdates (Map.fromList [(viewId, value)]) (assignIds rootView)
    ; let db' = save rootView' db
    ; writeIORef sessionStateRef $ SessionState sessionId user db' rootView' pendingEdit hashArgs
    ; reloadRootView sessionStateRef


    --; putStrLn $ "Updated rootView:\n" ++ show rootView'
    ; response <- case  getAnyWidgetById viewId rootView' :: AnyWidget db of
        TextWidget (TextView _ _ _ _ _ (Just fChangeAction) _)         -> performEditCommand users sessionStateRef (fChangeAction value) 
        RadioViewWidget (RadioView _ _ _ _ _ (Just fChangeAction))   -> performEditCommand users sessionStateRef (fChangeAction $ unsafeRead "Server.handle: radio selection" value) 
        SelectViewWidget (SelectView _ _ _ _ _ (Just fChangeAction)) -> performEditCommand users sessionStateRef (fChangeAction $ unsafeRead "Server.handle: select selection" value) 
        _                                                  -> return ViewUpdate -- Not a widget with an change action
      -- TODO: check if mkViewMap has correct arg
    -- TODO: instead of updating all, just update the one that was changed
    ; return response
    }
handleCommand _  users sessionStateRef (ButtonC viewId) =
 do { SessionState _ user db rootView pendingEdit hashArgs <- readIORef sessionStateRef
    ; let (Button _ txt _ _ _ act) = getButtonByViewId viewId rootView
    ; putStrLn $ "Button #" ++ show viewId ++ ":" ++ txt ++ " was clicked"

    ; response <- performEditCommand users  sessionStateRef act
          
    ; return response
    }
handleCommand _ users sessionStateRef (SubmitC viewId) =
 do { SessionState _ user db rootView pendingEdit hashArgs <- readIORef sessionStateRef
    ; let TextView _ _ txt _ _ _ mAct = getTextViewByViewId viewId rootView
    ; putStrLn $ "TextView #" ++ show viewId ++ ":" ++ txt ++ " was submitted"

    ; response <- case mAct of 
        Nothing  -> error "Internal error: text field with submission action has no associated action."
        Just act -> performEditCommand users sessionStateRef act
          
    ; return response
    }
handleCommand _ users sessionStateRef (PerformEditActionC viewId args) =
 do { SessionState _ user db rootView pendingEdit hashArgs <- readIORef sessionStateRef
    ; let EditAction _ act = getEditActionByViewId viewId rootView
    ; putStrLn $ "EditAction with ViewId "++show viewId ++ " was executed"

    ; response <- performEditCommand users sessionStateRef $ act args
          
    ; return response
    }
handleCommand _ users sessionStateRef ConfirmDialogOk =
 do { sState <- readIORef sessionStateRef
    ; writeIORef sessionStateRef sState{getSStatePendingEdit = Nothing} -- clear it, also in case of error
    ; response <- case getSStatePendingEdit sState of
                    Nothing -> return ViewUpdate -- error "ConfirmDialogOk event without active dialog"
                    Just ec -> performEditCommand users sessionStateRef ec
    ; return response
    }
 
reloadRootView :: Data db => SessionStateRef db -> IO ()
reloadRootView sessionStateRef =
 do { SessionState sessionId user db rootView pendingEdit hashArgs <- readIORef sessionStateRef
    ; 
    ; rootView' <- evalStateT (loadView rootView) (WebViewState user db (mkViewMap rootView) [] 0 sessionId hashArgs)
 -- TODO this 0 does not seem right BUG
    ; writeIORef sessionStateRef $ SessionState sessionId user db rootView' pendingEdit hashArgs
    } 
 
performEditCommand users  sessionStateRef command =
 do { SessionState sessionId user db rootView pendingEdit hashArgs <- readIORef sessionStateRef
    ; case command of  
            AlertEdit str -> return $ Alert str
            ConfirmEdit str ec -> 
             do { writeIORef sessionStateRef $ SessionState sessionId user db rootView (Just ec) hashArgs
                ; return $ Confirm str
                }
            AuthenticateEdit userViewId passwordViewId -> authenticate users  sessionStateRef userViewId passwordViewId
            LogoutEdit -> logout sessionStateRef
            Edit edit -> performEdit sessionStateRef edit
    }
 
performEdit :: Data db => SessionStateRef db -> EditM db () -> IO ServerResponse
performEdit sessionStateRef edit  =
 do { state <- readIORef sessionStateRef
    ; state' <- execStateT edit state
    ; writeIORef sessionStateRef state'
    ; reloadRootView sessionStateRef
    ; return $ ViewUpdate
    }

authenticate users sessionStateRef userEStringViewId passwordEStringViewId =
 do { sState@SessionState{ getSStateRootView = rootView } <- readIORef sessionStateRef
    ; let userName = getTextViewStrByViewIdRef userEStringViewId rootView
          enteredPassword = getTextViewStrByViewIdRef passwordEStringViewId rootView
    ; case Map.lookup userName users of
        Just (password, fullName) -> if password == enteredPassword  
                                     then 
                                      do { putStrLn $ "User "++userName++" authenticated"
                                         ; writeIORef sessionStateRef 
                                             sState{ getSStateUser = Just (userName, fullName) }
                                         ; reloadRootView sessionStateRef
                                         ; return ViewUpdate
                                         }
                                     else
                                      do { putStrLn $ "User \""++userName++"\" entered a wrong password"
                                         ; return $ Alert $ "Incorect password for '"++userName++"'"
                                         }
        Nothing -> do { putStrLn $ "User "++userName++" entered a wrong password"
                      ; return $ Alert $ "Unknown username: "++userName
                      }
    }
logout sessionStateRef =
 do { sState <- readIORef sessionStateRef
    ; writeIORef sessionStateRef sState{ getSStateUser = Nothing }
    ; reloadRootView sessionStateRef
    ; return ViewUpdate
    }  