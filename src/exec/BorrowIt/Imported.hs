module Imported where

import DatabaseTypes

lenders = [ Lender {_lenderId = LenderId {_lenderIdLogin = "martijn"}, _lenderFirstName = "Martijn", _lenderLastName = "Schrage", _lenderGender = M, _lenderMail = "martijn@oblomov.com", _lenderStreet = "Kerkstraat", _lenderStreetNr = "15", _lenderCity = "Utrecht", _lenderZipCode = "3581 RA", _lenderCoords = (0.0,0.0), _lenderImage = "lender_1.jpg", _lenderRating = 5, _lenderNrOfPoints = 18, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Henny"}, _lenderFirstName = "Henny", _lenderLastName = "Verweij", _lenderGender = M, _lenderMail = "Henny@gmail.com", _lenderStreet = "Franz Schubertstraat", _lenderStreetNr = "39", _lenderCity = "Utrecht", _lenderZipCode = "3533 GT", _lenderCoords = (0.0,0.0), _lenderImage = "lender_2.jpg", _lenderRating = 5, _lenderNrOfPoints = 312, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Jaap"}, _lenderFirstName = "Jaap", _lenderLastName = "Lageman", _lenderGender = M, _lenderMail = "jaap@bpcutrecht.nl", _lenderStreet = "Kerkstraat", _lenderStreetNr = "17", _lenderCity = "Utrecht", _lenderZipCode = "3581 RA", _lenderCoords = (0.0,0.0), _lenderImage = "lender_3.jpg", _lenderRating = 5, _lenderNrOfPoints = 238, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Hans"}, _lenderFirstName = "Hans", _lenderLastName = "Pietersen", _lenderGender = M, _lenderMail = "Hans@Gmail.com", _lenderStreet = "traay", _lenderStreetNr = "18", _lenderCity = "Driebergen", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_4.jpg", _lenderRating = 0, _lenderNrOfPoints = 32, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Frans"}, _lenderFirstName = "Frans", _lenderLastName = "Verbeek", _lenderGender = M, _lenderMail = "Frans@Gmail.com", _lenderStreet = "slotlaan", _lenderStreetNr = "19", _lenderCity = "Zeist", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_5.jpg", _lenderRating = 0, _lenderNrOfPoints = 12, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Frits"}, _lenderFirstName = "Frits", _lenderLastName = "Spits", _lenderGender = M, _lenderMail = "Frits@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Zeist", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_6.jpg", _lenderRating = 0, _lenderNrOfPoints = 10, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Piet"}, _lenderFirstName = "Piet", _lenderLastName = "Paaltjes", _lenderGender = M, _lenderMail = "Piet@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Zeist", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_7.jpg", _lenderRating = 0, _lenderNrOfPoints = 2, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Xander"}, _lenderFirstName = "Xander", _lenderLastName = "de Bouvier", _lenderGender = M, _lenderMail = "Xander@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Zeist", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_8.jpg", _lenderRating = 0, _lenderNrOfPoints = 0, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Truus"}, _lenderFirstName = "Truus", _lenderLastName = "Hanekam", _lenderGender = F, _lenderMail = "Truus@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Amsterdam", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_9.jpg", _lenderRating = 0, _lenderNrOfPoints = 44, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Anita"}, _lenderFirstName = "Anita", _lenderLastName = "Burgemeester", _lenderGender = F, _lenderMail = "Anita@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Amsterdam", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_10.jpg", _lenderRating = 0, _lenderNrOfPoints = 12, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Hanneke"}, _lenderFirstName = "Hanneke", _lenderLastName = "Rock", _lenderGender = F, _lenderMail = "Hanneke@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Amsterdam", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_11.jpg", _lenderRating = 0, _lenderNrOfPoints = 93, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Irene"}, _lenderFirstName = "Irene", _lenderLastName = "Rood", _lenderGender = F, _lenderMail = "Irene@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Amsterdam", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_12.jpg", _lenderRating = 0, _lenderNrOfPoints = 174, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Carla"}, _lenderFirstName = "Carla", _lenderLastName = "Baars", _lenderGender = F, _lenderMail = "Carla@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Hilversum", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_13.jpg", _lenderRating = 0, _lenderNrOfPoints = 23, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Karin"}, _lenderFirstName = "Karin", _lenderLastName = "Snoek", _lenderGender = F, _lenderMail = "Karin@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Hilversum", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_14.jpg", _lenderRating = 0, _lenderNrOfPoints = 8, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Jessie"}, _lenderFirstName = "Jessie", _lenderLastName = "Smid", _lenderGender = F, _lenderMail = "Jessie@gmail.com", _lenderStreet = "", _lenderStreetNr = "", _lenderCity = "Hilversum", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_15.jpg", _lenderRating = 0, _lenderNrOfPoints = 12, _lenderItems = []}
         , Lender {_lenderId = LenderId {_lenderIdLogin = "Matt"}, _lenderFirstName = "Matt", _lenderLastName = "Jansen", _lenderGender = M, _lenderMail = "Matt@gmail.com", _lenderStreet = "kennedylaan", _lenderStreetNr = "17", _lenderCity = "Utrecht", _lenderZipCode = "", _lenderCoords = (0.0,0.0), _lenderImage = "lender_16.jpg", _lenderRating = 0, _lenderNrOfPoints = 15, _lenderItems = []}
         ]
items = [ Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "martijn"}, _itemPrice = 0, _itemName = "Abbey Road", _itemDescr = "Come Together\nSomething\nMaxwell's Silver Hammer\nOh! Darling\nOctopus's Garden\nI Want You (she's So Heavy)\nHere Comes The Sun\nBecause\nYou Never Give Me Your Money\nSun King\nMean Mr. Mustard\nPolythene Pam\nShe Came In Through The Bathroom Window\nGolden Slumbers\nCarry That Weight\nThe End\nHer Majesty", _itemState = "Prima", _itemImage = "cd_1.jpg", _itemCategory = CD {_cdArtist = "The Beatles", _cdYear = 1969, _cdGenre = "Pop/Rock"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Henny"}, _itemPrice = 0, _itemName = "Mahler Symphonies", _itemDescr = "Disk 1\n1. New York Philharmonic - I. Langsam. Schleppend. Wie Ein Naturlaut. Im Anfang Sehr Gem\65533chlich - \n2. Ii. Kr\65533ftig Bewegt, Doch Nicht Zu Schnell - 2008 Remastered\n3. Iii. Feierlich Und Gemessen, Ohne Zu Schleppen - 2008 Remastered\n4. Iv. St\65533rmisch Bewegt - Energisch - 2008 Remastered\nDisk 2\n1. New York Philharmonic - Symphony No. 2 In C Minor 'resurrection': I. Allegro Maestoso - 2008 R\nDisk 3\n1. New York Philharmonic / Collegiate Chorale - Ii. Andante Moderato - 2008 Remastered\n2. Iii. In Ruhig Fliessender Bewegung - 2008 Remastered\n3. Iv. 'urlicht'. Sehr Feierlich, Aber Schlicht - 2008 Remastered\n4. V. Im Tempo Des Scherzos. Wild Herausfahrend - 2008 Remastered\nDisk 4\n1. New York Philharmonic - Symphony No. 3 In D Minor: I. Kr\65533ftig - 2008 Remastered\nDisk 5\n1. New York Philharmonic / Women's Chorus of the Schola Cantorum / Boys' - Ii. Tempo Di Menuetto - 2002. Iii. Comodo. Scherzando - 2008 Remastered\n3. Iv. Sehr Langsam\n4. V. Lustig Im Tempo Und Keck Im Ausdruck - 2008 Remastered\n5. Vi. Langsam - 2008 Remastered", _itemState = "", _itemImage = "cd_2.jpg", _itemCategory = CD {_cdArtist = "Mahler", _cdYear = 2008, _cdGenre = "Klassiek"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Matt"}, _itemPrice = 0, _itemName = "John Cage", _itemDescr = "", _itemState = "", _itemImage = "cd_3.jpg", _itemCategory = CD {_cdArtist = "John Cage", _cdYear = 0, _cdGenre = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Hans"}, _itemPrice = 0, _itemName = "Guitar Transcriptions", _itemDescr = "1. Bach: Partita for Flute solo in A minor, BWV 1013\n2. Bach: Well-Tempered Clavier, Book 1: Prelude and Fugue no 9 in E major, BWV 854\n3. Bach: Capriccio in B flat major on the departure of his Most Beloved Brother, BWV 992\n4. Bach: Concerto in D minor after Alessandro Marcello, BWV 974 \n5. Bach: Sonata for Violin solo no 1 in G minor, BWV 1001 \n6. 5 Little Preludes, Bwv 939-943: Prelude In C Major, Bwv 939 \n7. Capriccio Sopra La Lontananza De Il Fratro Dilettissimo In B Flat Majo \n8. Keyboard Concerto In D Minor, Bwv 974 (After A. Marcello's Oboe Concert\n9. Keyboard Concerto In D Minor, Bwv 974 (After A. Marcello's Oboe Concert\n10. Keyboard Concerto In D Minor, Bwv 974 (After A. Marcello's Oboe Concert\n11. Violin Sonata No. 1 In G Minor, Bwv 1001 (Arr. E. Voorhorst for Guitar)\n12. Violin Sonata No. 1 In G Minor, Bwv 1001 (Arr. E. Voorhorst for Guitar)\n13. Violin Sonata No. 1 In G Minor, Bwv 1001 (Arr. E. Voorhorst for Guitar)\n14. Violin Sonata No. 1 In G Minor, Bwv 1001 (Arr. E. Voorhorst for Guitar", _itemState = "", _itemImage = "cd_4.jpg", _itemCategory = CD {_cdArtist = "Bach", _cdYear = 2005, _cdGenre = "Klassiek"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frans"}, _itemPrice = 0, _itemName = "Violin Concertos BWV 1041/1042/1043/1060l", _itemDescr = "1. Bach: Concerto for Violin no 1 in A minor, BWV 1041 \n2. Bach: Concerto for Violin no 2 in E major, BWV 1042 \n3. Bach: Concerto for 2 Violins in D minor, BWV 1043 \n4. Bach: Concerto for Oboe and Violin in C minor, BWV 1060", _itemState = "", _itemImage = "cd_5.jpg", _itemCategory = CD {_cdArtist = "Bach", _cdYear = 2004, _cdGenre = "Klassiek"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frits"}, _itemPrice = 0, _itemName = "Slash", _itemDescr = "1. Apocalyptic Love\n2. One Last Thrill\n3. Standing In the Sun\n4. You're A Lie\n5. No More Heroes\n6. Halo\n7. We Will Roam\n8. Anastasia\n9. Not for Me\n10. Bad Rain\n 11. Hard & Fast\n12. Far and Away\n 13. Shots Fired\n14. Carolina (Bonustrack)\n15. Crazy Life (Bonustrack)\nDisk 2  1. Apocalyptic Love Documentary ", _itemState = "", _itemImage = "cd_6.jpg", _itemCategory = CD {_cdArtist = "Slash", _cdYear = 2012, _cdGenre = "Heavy Metal"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Piet"}, _itemPrice = 0, _itemName = "Eye in the sky", _itemDescr = "1. Sirius (1:57)\n2. Eye In The Sky (4:35)\n3. Children Of The Moon (4:49)\n4. Gemini (2:09)\n5. Silence And I (7:17)\n6. You're Gonna Get Your Fingers Burned (4:19)\n7. Psychobabble (4:50)\n8. Mammagamma - Instrumental (3:34)\n9. Step By Step (3:52)\n10. Old And Wise (4:57)\n11. Sirius - Demo (1:53)\n12. Old & Wise - Eric Woolfson Guide Vocal (4:31)\n13. Any Other Day - Studio Demo (1:40\n\n14. Silence & I - Early Version; Eric Woolfson Guide Vocal (7:33)\n15. The Naked Eye (10:47)\n16. Eye Pieces - Classical Naked Eye (7:51) ", _itemState = "", _itemImage = "cd_7.jpg", _itemCategory = CD {_cdArtist = "Alan Parsons Project", _cdYear = 1980, _cdGenre = "Pop/Rock"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Xander"}, _itemPrice = 0, _itemName = "Dark Side of the Moon", _itemDescr = "1. Speak To Me (2011 - Remaster)\n2. Breathe (In the Air) [2011 - Remaster]\n3. On the Run (2011 - Remaster)\n4. Time (2011 - Remaster)\n5. The Great Gig In the Sky (2011 - Remaster)\n6. Money (2011 - Remaster)\n7. Us and Them (2011 - Remaster)\n8. Any Colour You Like (2011 - Remaster)\n9. Brain Damage (2011 - Remaster)\n10. Eclipse (2011 - Remaster)", _itemState = "", _itemImage = "cd_8.jpg", _itemCategory = CD {_cdArtist = "Pink Floyd", _cdYear = 1973, _cdGenre = "Pop/Rock"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Truus"}, _itemPrice = 0, _itemName = "The Koln Concert", _itemDescr = "1. Part I\n2. Part IIa\n3. Part IIb\n4. Part IIc ", _itemState = "", _itemImage = "cd_9.jpg", _itemCategory = CD {_cdArtist = "Keith Jarret", _cdYear = 1994, _cdGenre = "Jazz"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Anita"}, _itemPrice = 0, _itemName = "Khmer", _itemDescr = "1. Khmer\n2. Tlon\n3. Access / Song Of Sand I\n4. On Stream\n5. Platonic Years\n6. Phum\n7. Song Of Sand Ii\n8. Exit", _itemState = "", _itemImage = "cd_10.jpg", _itemCategory = CD {_cdArtist = "Nils Petter Molvaer", _cdYear = 2005, _cdGenre = "Jazz"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "martijn"}, _itemPrice = 0, _itemName = "Oblomov", _itemDescr = "Een boek schrijven van ruim vijfhonderd bladzijden waarin de held bijna tweehonderd bladzijden lang zijn bed niet uit komt, maar dat geen moment verveelt, zoiets is alleen een zeer groot schrijver gegeven. Oblomov, het magnum opus van Ivan Gontsjarov, is een roman die alles mist waar zoveel andere boeken het van moeten hebben; we lezen slechts over de kleine, alledaagse belevenissen van de goedige, maar aartsluie Ilja Oblomov. Zelfs zijn liefde voor de betoverende Olga kan Oblomov niet uit zijn apathie halen en hem aanzetten tot de grootse daden die zij van hem verwacht. De ondergang van een antiheld.", _itemState = "Goed", _itemImage = "book_1.jpg", _itemCategory = Book {_bookAuthor = "Ivan Gonstjarov", _bookYear = 1859, _bookLanguage = "Engels", _bookGenre = "Roman", _bookPages = 552, _bookISBN = "9074113052"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Henny"}, _itemPrice = 0, _itemName = "13 uur", _itemDescr = "", _itemState = "", _itemImage = "book_2.jpg", _itemCategory = Book {_bookAuthor = "Deon Meyer", _bookYear = 0, _bookLanguage = "Nederlands", _bookGenre = "Roman", _bookPages = 0, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Matt"}, _itemPrice = 0, _itemName = "Chantage", _itemDescr = "", _itemState = "", _itemImage = "book_3.jpg", _itemCategory = Book {_bookAuthor = "Peter R\65533mer", _bookYear = 0, _bookLanguage = "Nederlands", _bookGenre = "Roman", _bookPages = 0, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Hans"}, _itemPrice = 0, _itemName = "Genadeloos", _itemDescr = "", _itemState = "", _itemImage = "book_4.jpg", _itemCategory = Book {_bookAuthor = "Karin Slaughter", _bookYear = 0, _bookLanguage = "Nederlands", _bookGenre = "Roman", _bookPages = 0, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frans"}, _itemPrice = 0, _itemName = "Hitchhikers Guide to the Galaxy", _itemDescr = "Seconds before the Earth is demolished to make way for a galactic freeway, Arthur Dent is plucked off the planet by his friend Ford Prefect, a researcher for the revised edition of The Hitchhiker's Guide to the Galaxy who, for the last fifteen years, has been posing as an out-of-work actor.\nTogether this dynamic pair begin a journey through space aided by quotes from The Hitchhiker's Guide (\"A towel is about the most massively useful thing an interstellar hitchhiker can have\") and a galaxy-full of weirdos. ", _itemState = "", _itemImage = "book_5.jpg", _itemCategory = Book {_bookAuthor = "Douglas Adams", _bookYear = 1979, _bookLanguage = "Engels", _bookGenre = "SciFi", _bookPages = 244, _bookISBN = "9780330508117"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frits"}, _itemPrice = 0, _itemName = "The cider house rules", _itemDescr = "", _itemState = "", _itemImage = "book_6.jpg", _itemCategory = Book {_bookAuthor = "John Irving", _bookYear = 0, _bookLanguage = "Engels", _bookGenre = "roman", _bookPages = 0, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Piet"}, _itemPrice = 0, _itemName = "Riverworld: Including To Your Scattered Bodies Go & The Fabulous Riverboat", _itemDescr = "Charts a territory somewhere between \"Gulliver's Travels\" and \"The Lord of the Rings\".\n To Your Scattered Bodies Go\" and \"The Fabulous Riverboat \n Combined for the first time in one volume! \n Imagine that every human who ever lived, from the earliest Neanderthals to the present, is resurrected after death on the banks of an astonishing and seemingly endless river on an unknown world. They are miraculously provided with food, but with not a clue to the possible meaning of this strange afterlife. And so billions of people from history, and before, must start living again. \n Some set sail on the great river questing for the meaning of their resurrection, and to find and confront their mysterious benefactors. On this long journey, we meet Sir Richard Francis Burton, Mark Twain, Odysseus, Cyrano de Bergerac, and many others, most of whom embark upon searches of their own in this huge afterlife.", _itemState = "", _itemImage = "book_7.jpg", _itemCategory = Book {_bookAuthor = "Philip Jose Farmer", _bookYear = 0, _bookLanguage = "Engels", _bookGenre = "Scifi", _bookPages = 443, _bookISBN = "9780765326522"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Xander"}, _itemPrice = 0, _itemName = "The Red House", _itemDescr = "", _itemState = "", _itemImage = "book_8.jpg", _itemCategory = Book {_bookAuthor = "Mark Haddon", _bookYear = 0, _bookLanguage = "Engels", _bookGenre = "roman", _bookPages = 0, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Truus"}, _itemPrice = 0, _itemName = "Waar mensen gaan wordt tijd geschreven", _itemDescr = "", _itemState = "", _itemImage = "book_9.jpg", _itemCategory = Book {_bookAuthor = "Theo Ettema", _bookYear = 0, _bookLanguage = "Nederlands", _bookGenre = "gedichten", _bookPages = 0, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Anita"}, _itemPrice = 0, _itemName = "Da Vinci Code", _itemDescr = "", _itemState = "", _itemImage = "book_10.jpg", _itemCategory = Book {_bookAuthor = "Dan Brown", _bookYear = 0, _bookLanguage = "Nederlands", _bookGenre = "thriller", _bookPages = 0, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Hanneke"}, _itemPrice = 0, _itemName = "De laatste oorlog", _itemDescr = "", _itemState = "", _itemImage = "book_11.jpg", _itemCategory = Book {_bookAuthor = "Jan Marijnissen en Karel Glasstra van Loon", _bookYear = 0, _bookLanguage = "Nederlands", _bookGenre = "filosofie", _bookPages = 0, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Irene"}, _itemPrice = 0, _itemName = "Fred en Wilma", _itemDescr = "", _itemState = "", _itemImage = "book_12.jpg", _itemCategory = Book {_bookAuthor = "Nieke Oosterbaan", _bookYear = 0, _bookLanguage = "Nederlands", _bookGenre = "doe het zelf", _bookPages = 125, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Carla"}, _itemPrice = 0, _itemName = "Oeroeg", _itemDescr = "", _itemState = "", _itemImage = "book_13.jpg", _itemCategory = Book {_bookAuthor = "Hella Haasen", _bookYear = 1948, _bookLanguage = "Nederlands", _bookGenre = "boekenweekgeschenk", _bookPages = 80, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Karin"}, _itemPrice = 0, _itemName = "Hollandse Polders", _itemDescr = "", _itemState = "", _itemImage = "book_14.jpg", _itemCategory = Book {_bookAuthor = "Willem van der Ham", _bookYear = 1995, _bookLanguage = "Nederlands", _bookGenre = "geschiedenis", _bookPages = 230, _bookISBN = ""}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "martijn"}, _itemPrice = 0, _itemName = "Moon", _itemDescr = "Astronaut Sam Bell woont al bijna drie jaar op de maan in opdracht van Lunar Industries. Hij leeft daar een eenzaam bestaan en door een defecte satelliet heeft hij amper contact met zijn vrouw Tess en driejarige dochter Eve. Zijn enige maatje aan boord is Gerty: een robot. Onverwacht krijgt Sam gezondheidsproblemen en gaat hallucineren waardoor hij een bijna-fataal ongeluk krijgt. Als hij terug is op zijn basisstation, ontmoet hij zijn jongere en agressieve \"ik\". ", _itemState = "Goed", _itemImage = "dvd_1.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "Duncan Jones", _dvdLanguage = "Engels", _dvdYear = 2009, _dvdGenre = "Science Fiction", _dvdRunningTime = 97, _dvdIMDb = "http://www.imdb.com/title/tt1182345/", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "martijn"}, _itemPrice = 0, _itemName = "Deadwood season 1", _itemDescr = "Deadwood is een televisieserie die zich aan het einde van de negentiende eeuw afspeelt in Deadwood (South Dakota), een stadje dat toentertijd beheerst werd door de goudkoorts. Na drie seizoenen is de serie gestopt. Wel zijn er plannen om \65533\65533n of meerdere films als vervolg van de serie te maken.", _itemState = "Goed", _itemImage = "dvd_2.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "-", _dvdLanguage = "Engels", _dvdYear = 2004, _dvdGenre = "Western", _dvdRunningTime = 45, _dvdIMDb = "http://www.imdb.com/title/tt0348914/", _dvdSeason = 1, _dvdNrOfEpisodes = 12}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Henny"}, _itemPrice = 0, _itemName = "Nikitia", _itemDescr = "", _itemState = "", _itemImage = "dvd_3.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "", _dvdYear = 2005, _dvdGenre = "", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Matt"}, _itemPrice = 0, _itemName = "Bloedverwanten", _itemDescr = "", _itemState = "", _itemImage = "dvd_4.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "", _dvdYear = 2006, _dvdGenre = "", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Hans"}, _itemPrice = 0, _itemName = "Harry Potter, Steen der Wijzen", _itemDescr = "", _itemState = "", _itemImage = "dvd_5.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "", _dvdYear = 2007, _dvdGenre = "", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frans"}, _itemPrice = 0, _itemName = "Ghost Protocol", _itemDescr = "", _itemState = "", _itemImage = "dvd_6.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "", _dvdYear = 2008, _dvdGenre = "", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frits"}, _itemPrice = 0, _itemName = "Pirates of the Caribbean", _itemDescr = "", _itemState = "", _itemImage = "dvd_7.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "", _dvdYear = 2009, _dvdGenre = "", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Piet"}, _itemPrice = 0, _itemName = "Sherlock Holmes", _itemDescr = "", _itemState = "", _itemImage = "dvd_8.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "", _dvdYear = 2010, _dvdGenre = "", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Xander"}, _itemPrice = 0, _itemName = "The Girl with the Dragon Tattoo", _itemDescr = "", _itemState = "", _itemImage = "dvd_9.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "", _dvdYear = 2011, _dvdGenre = "", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Truus"}, _itemPrice = 0, _itemName = "Deadwood season 2", _itemDescr = "", _itemState = "", _itemImage = "dvd_10.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "-", _dvdLanguage = "Engels", _dvdYear = 2005, _dvdGenre = "Western", _dvdRunningTime = 45, _dvdIMDb = "http://www.imdb.com/title/tt0348914/", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Anita"}, _itemPrice = 0, _itemName = "Elvis", _itemDescr = "", _itemState = "", _itemImage = "dvd_11.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "Engels", _dvdYear = 2006, _dvdGenre = "muziek", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Hanneke"}, _itemPrice = 0, _itemName = "Gossip Girl", _itemDescr = "", _itemState = "", _itemImage = "dvd_12.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "Engels", _dvdYear = 2005, _dvdGenre = "soap", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Irene"}, _itemPrice = 0, _itemName = "The Box", _itemDescr = "", _itemState = "", _itemImage = "dvd_13.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "Engels", _dvdYear = 2004, _dvdGenre = "Thriller", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Carla"}, _itemPrice = 0, _itemName = "Lost", _itemDescr = "", _itemState = "", _itemImage = "dvd_14.jpg", _itemCategory = DVD {_dvdMovieOrSeries = Series, _dvdDirector = "", _dvdLanguage = "Engels", _dvdYear = 2011, _dvdGenre = "Suspense", _dvdRunningTime = 0, _dvdIMDb = "", _dvdSeason = 0, _dvdNrOfEpisodes = 0}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "martijn"}, _itemPrice = 0, _itemName = "Grand Theft Auto V", _itemDescr = "Wat is er tegenwoordig nog over van die legendarische 'American Dream'? Niko Bellic is net aan wal gestapt na een lange bootreis uit Europa en hoopt in Amerika zijn verleden te begraven. Zijn neef Roman droomt ervan het helemaal te maken in Liberty City, in het land van de onbegrensde mogelijkheden.\nZe raken in de schulden en komen in het criminele circuit terecht door toedoen van oplichters, dieven en ander tuig. Langzamerhand komen ze erachter dat ze hun dromen niet kunnen waarmaken in een stad waar alles draait om geld en status. Heb je genoeg geld, dan staan alle deuren voor je open. Zonder een cent beland je in de goot.", _itemState = "Goed", _itemImage = "game_1.jpg", _itemCategory = Game {_gamePlatform = "PlayStation 3", _gameYear = 2011, _gameDeveloper = "Rockstar Games", _gameGenre = "Action adventure, Open world"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Henny"}, _itemPrice = 0, _itemName = "Pokemon Black 2", _itemDescr = "", _itemState = "matig", _itemImage = "game_2.jpg", _itemCategory = Game {_gamePlatform = "Nindento DS", _gameYear = 2011, _gameDeveloper = "Pokemon Games", _gameGenre = "Action adventure"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Matt"}, _itemPrice = 0, _itemName = "MIB", _itemDescr = "", _itemState = "goed", _itemImage = "game_3.jpg", _itemCategory = Game {_gamePlatform = "Wii", _gameYear = 2011, _gameDeveloper = "SIFI Games", _gameGenre = "Action adventure"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Hans"}, _itemPrice = 0, _itemName = "FiFa12", _itemDescr = "", _itemState = "kapotgespeelt", _itemImage = "game_4.jpg", _itemCategory = Game {_gamePlatform = "Wii", _gameYear = 2011, _gameDeveloper = "voetbal Games", _gameGenre = "Sport, voetbal"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frans"}, _itemPrice = 0, _itemName = "Spec Ops The Line", _itemDescr = "", _itemState = "slecht", _itemImage = "game_5.jpg", _itemCategory = Game {_gamePlatform = "PS3", _gameYear = 2011, _gameDeveloper = "vecht en CO", _gameGenre = "Oorlog, geweld, schieten, dood!"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frits"}, _itemPrice = 0, _itemName = "K3 fashion", _itemDescr = "", _itemState = "matig", _itemImage = "game_6.jpg", _itemCategory = Game {_gamePlatform = "Nindento DS", _gameYear = 2011, _gameDeveloper = "Roze en blauw", _gameGenre = "kinderspel, mode"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Piet"}, _itemPrice = 0, _itemName = "FiFa13", _itemDescr = "", _itemState = "kapotgespeelt", _itemImage = "game_7.jpg", _itemCategory = Game {_gamePlatform = "PS3", _gameYear = 2011, _gameDeveloper = "voetbal Games", _gameGenre = "Sport, voetbal"}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "martijn"}, _itemPrice = 0, _itemName = "Boormachine", _itemDescr = "Het krachtige en compacte toestel Krachtig motor van 600 Watt, ideaal om te boren tot 10 mm boordiameter in metaal Bevestiging van boorspil in het lager voor hoge precisie Compact design en gering gewicht voor optimale bediening bij middelzware boortoepassingen Besturings-electronic voor exact aanboren Metalen snelspanboorhouder voor hoge precisie en lange levensduur Rechts- en linksdraaien Bijzonder geschikt voor boorgaten tot 10 mm in staal Functies: Rechts- en linksdraaien Electronic Softgrip Leveromvang: Snelspanboorhouder 1 - 10 mm", _itemState = "Goed", _itemImage = "tool_1.jpg", _itemCategory = Tool {_toolBrand = "Bosch", _toolType = "BDF343SHE", _toolYear = 2005}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Henny"}, _itemPrice = 0, _itemName = "Klopboormachine", _itemDescr = "Veelzijdig - zagen, snijden, slijpen dankzij het oscillatieprincipe en de accessoires", _itemState = "goed", _itemImage = "tool_2.jpg", _itemCategory = Tool {_toolBrand = "Bosch", _toolType = "GSB 20-2 re", _toolYear = 2011}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Matt"}, _itemPrice = 0, _itemName = "bladblazer", _itemDescr = "op benzine", _itemState = "matig", _itemImage = "tool_3.jpg", _itemCategory = Tool {_toolBrand = "ferm", _toolType = "benzine", _toolYear = 2006}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Hans"}, _itemPrice = 0, _itemName = "Kettingzaag", _itemDescr = "op benzine", _itemState = "goed", _itemImage = "tool_4.jpg", _itemCategory = Tool {_toolBrand = "HD", _toolType = "benzine", _toolYear = 2001}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frans"}, _itemPrice = 0, _itemName = "Zware klopboormachine", _itemDescr = "electrisch, tot 25 mm en 350 mm lengte", _itemState = "goed", _itemImage = "tool_5.jpg", _itemCategory = Tool {_toolBrand = "Milwaukee", _toolType = "Q1234", _toolYear = 2003}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Frits"}, _itemPrice = 0, _itemName = "Multitool", _itemDescr = "Veelzijdig - zagen, snijden, slijpen dankzij het oscillatieprincipe en de accessoires", _itemState = "goed", _itemImage = "tool_6.jpg", _itemCategory = Tool {_toolBrand = "Bosch", _toolType = "PMF 10,8 LI", _toolYear = 2011}, _itemBorrowed = Nothing}
        , Item {_itemId = ItemId {_itemIdNr = -1}, _itemOwner = LenderId {_lenderIdLogin = "Piet"}, _itemPrice = 0, _itemName = "Heggenschaar", _itemDescr = "Benzine, 90mm blad", _itemState = "goed", _itemImage = "tool_7.jpg", _itemCategory = Tool {_toolBrand = "Start", _toolType = "Benzine", _toolYear = 2012}, _itemBorrowed = Nothing}
        ]