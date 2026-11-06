# Firestore Security Rules – kết quả chạy trên Emulator

Sinh tự động bởi `firebase/tests/rules.test.mjs` lúc 2026-11-06T13:50:48.090Z.
Tổng: 148 ca · Qua: 148 · Lỗi: 0.
Mỗi vai trò (user, staff, admin) có ít nhất 1 ca cho phép và 1 ca từ chối ở mỗi collection.

| ID | Collection | Role | Operation | Expected | Result |
|:---|:---|:---|:---|:---|:---|
| R-01 | users | user | read own profile | Allowed | Pass |
| R-02 | users | user | read another user's profile | Denied | Pass |
| R-03 | users | user | update own settings (role kept) | Allowed | Pass |
| R-04 | users | user | update own role to admin | Denied | Pass |
| R-05 | users | user | old profile without role: add role staff | Denied | Pass |
| R-06 | users | user | first sign-in creates profile with role user | Allowed | Pass |
| R-07 | users | user | first sign-in creates profile with role admin | Denied | Pass |
| R-08 | users | staff | list users (web user list) | Allowed | Pass |
| R-09 | users | staff | change a user's role | Denied | Pass |
| R-10 | users | admin | make bob staff | Allowed | Pass |
| R-11 | users | admin | change own role | Denied | Pass |
| R-12 | users | admin | change role and display name together | Denied | Pass |
| R-13 | users | admin | set an unknown role | Denied | Pass |
| R-14 | users | signed out | read a profile | Denied | Pass |
| R-15 | purchases | user | create own | Allowed | Pass |
| R-16 | wishlistItems | user | create own | Allowed | Pass |
| R-17 | wishlistItems/priceSnapshots | user | create own | Allowed | Pass |
| R-18 | extensionSessions | user | create own | Allowed | Pass |
| R-19 | decisions | user | create own | Allowed | Pass |
| R-20 | budgetGroups | user | create own | Allowed | Pass |
| R-21 | feedback | user | create own | Allowed | Pass |
| R-22 | ownedItems | user | create own | Allowed | Pass |
| R-23 | budgets | user | create own | Allowed | Pass |
| R-24 | reflections | user | create own | Allowed | Pass |
| R-25 | purchases | user | read bob's | Denied | Pass |
| R-26 | wishlistItems | user | read bob's | Denied | Pass |
| R-27 | wishlistItems/priceSnapshots | user | read bob's | Denied | Pass |
| R-28 | extensionSessions | user | read bob's | Denied | Pass |
| R-29 | decisions | user | read bob's | Denied | Pass |
| R-30 | budgetGroups | user | read bob's | Denied | Pass |
| R-31 | feedback | user | read bob's | Denied | Pass |
| R-32 | ownedItems | user | read bob's | Denied | Pass |
| R-33 | budgets | user | read bob's | Denied | Pass |
| R-34 | reflections | user | read bob's | Denied | Pass |
| R-35 | purchases | staff | create own | Allowed | Pass |
| R-36 | wishlistItems | staff | create own | Allowed | Pass |
| R-37 | wishlistItems/priceSnapshots | staff | create own | Allowed | Pass |
| R-38 | extensionSessions | staff | create own | Allowed | Pass |
| R-39 | decisions | staff | create own | Allowed | Pass |
| R-40 | budgetGroups | staff | create own | Allowed | Pass |
| R-41 | feedback | staff | create own | Allowed | Pass |
| R-42 | ownedItems | staff | create own | Allowed | Pass |
| R-43 | budgets | staff | create own | Allowed | Pass |
| R-44 | reflections | staff | create own | Allowed | Pass |
| R-45 | purchases | staff | read bob's | Denied | Pass |
| R-46 | wishlistItems | staff | read bob's | Denied | Pass |
| R-47 | wishlistItems/priceSnapshots | staff | read bob's | Denied | Pass |
| R-48 | extensionSessions | staff | read bob's | Denied | Pass |
| R-49 | decisions | staff | read bob's | Denied | Pass |
| R-50 | budgetGroups | staff | read bob's | Denied | Pass |
| R-51 | feedback | staff | read bob's | Denied | Pass |
| R-52 | ownedItems | staff | read bob's | Denied | Pass |
| R-53 | budgets | staff | read bob's | Denied | Pass |
| R-54 | reflections | staff | read bob's | Denied | Pass |
| R-55 | purchases | admin | create own | Allowed | Pass |
| R-56 | wishlistItems | admin | create own | Allowed | Pass |
| R-57 | wishlistItems/priceSnapshots | admin | create own | Allowed | Pass |
| R-58 | extensionSessions | admin | create own | Allowed | Pass |
| R-59 | decisions | admin | create own | Allowed | Pass |
| R-60 | budgetGroups | admin | create own | Allowed | Pass |
| R-61 | feedback | admin | create own | Allowed | Pass |
| R-62 | ownedItems | admin | create own | Allowed | Pass |
| R-63 | budgets | admin | create own | Allowed | Pass |
| R-64 | reflections | admin | create own | Allowed | Pass |
| R-65 | purchases | admin | read bob's (web user list counts) | Allowed | Pass |
| R-66 | wishlistItems | admin | read bob's (web user list counts) | Allowed | Pass |
| R-67 | wishlistItems/priceSnapshots | admin | read bob's | Denied | Pass |
| R-68 | extensionSessions | admin | read bob's | Denied | Pass |
| R-69 | decisions | admin | read bob's | Denied | Pass |
| R-70 | budgetGroups | admin | read bob's | Denied | Pass |
| R-71 | feedback | admin | read bob's | Denied | Pass |
| R-72 | ownedItems | admin | read bob's | Denied | Pass |
| R-73 | budgets | admin | read bob's | Denied | Pass |
| R-74 | reflections | admin | read bob's | Denied | Pass |
| R-75 | purchases | admin | edit bob's purchase | Denied | Pass |
| R-76 | wishlistItems | admin | delete bob's item | Denied | Pass |
| R-77 | purchases | user | create with amount 0 | Denied | Pass |
| R-78 | wishlistItems | user | status "waiting" (not in the spec) | Denied | Pass |
| R-79 | wishlistItems/priceSnapshots | user | edit a recorded price | Denied | Pass |
| R-80 | decisions | user | unknown choice | Denied | Pass |
| R-81 | feedback | user | edit a sent feedback | Denied | Pass |
| R-82 | reflections | user | rating 6 | Denied | Pass |
| R-83 | extensionSessions | user | status "hacked" | Denied | Pass |
| R-84 | inbox | user | read own messages | Allowed | Pass |
| R-85 | inbox | user | mark a message read | Allowed | Pass |
| R-86 | inbox | user | change the text of a message | Denied | Pass |
| R-87 | inbox | user | write a message to self | Denied | Pass |
| R-88 | inbox | user | read bob's messages | Denied | Pass |
| R-89 | inbox | staff | send a message to alice | Allowed | Pass |
| R-90 | inbox | staff | send a message signed as someone else | Denied | Pass |
| R-91 | inbox | staff | read alice's messages | Denied | Pass |
| R-92 | inbox | admin | send a message to bob | Allowed | Pass |
| R-93 | inbox | admin | send a message with an extra field | Denied | Pass |
| R-94 | announcements | user | list published | Allowed | Pass |
| R-95 | announcements | user | list without the status filter | Denied | Pass |
| R-96 | announcements | user | read an archived one | Denied | Pass |
| R-97 | announcements | user | post an announcement | Denied | Pass |
| R-98 | announcements | staff | post an announcement | Allowed | Pass |
| R-99 | announcements | staff | archive a published one | Allowed | Pass |
| R-100 | announcements | staff | republish an archived one | Denied | Pass |
| R-101 | announcements | staff | delete one | Denied | Pass |
| R-102 | announcements | admin | post an announcement | Allowed | Pass |
| R-103 | announcements | admin | post with a 501-character body | Denied | Pass |
| R-104 | announcements | signed out | list published | Denied | Pass |
| R-105 | saleEvents | user | read a published sale | Allowed | Pass |
| R-106 | saleEvents | user | read a draft | Denied | Pass |
| R-107 | saleEvents | user | create a sale | Denied | Pass |
| R-108 | saleEvents | staff | create a draft | Allowed | Pass |
| R-109 | saleEvents | staff | publish a draft | Allowed | Pass |
| R-110 | saleEvents | staff | republish an archived sale | Denied | Pass |
| R-111 | saleEvents | staff | unknown sale type | Denied | Pass |
| R-112 | saleEvents | admin | archive a published sale | Allowed | Pass |
| R-113 | saleEvents | admin | delete a sale | Denied | Pass |
| R-114 | saleSuggestions | user | propose a sale (pending) | Allowed | Pass |
| R-115 | saleSuggestions | user | propose one already approved | Denied | Pass |
| R-116 | saleSuggestions | user | propose in bob's name | Denied | Pass |
| R-117 | saleSuggestions | user | read own suggestion | Allowed | Pass |
| R-118 | saleSuggestions | user | read bob's suggestion | Denied | Pass |
| R-119 | saleSuggestions | user | approve own suggestion | Denied | Pass |
| R-120 | saleSuggestions | staff | approve (event + suggestion + inbox in one batch) | Allowed | Pass |
| R-121 | saleSuggestions | staff | approve the same suggestion again | Denied | Pass |
| R-122 | saleSuggestions | staff | reject without a reason | Denied | Pass |
| R-123 | saleSuggestions | staff | reject with a reason | Allowed | Pass |
| R-124 | saleSuggestions | admin | list the review queue | Allowed | Pass |
| R-125 | saleSuggestions | admin | propose in alice's name | Denied | Pass |
| R-126 | saleSuggestions | admin | reject signed as someone else | Denied | Pass |
| R-127 | (collection group) wishlistItems | admin | count skipped items of every user | Allowed | Pass |
| R-128 | (collection group) wishlistItems | staff | count skipped items of every user | Denied | Pass |
| R-129 | (collection group) wishlistItems | user | count skipped items of every user | Denied | Pass |
| R-130 | (collection group) purchases | admin | count every purchase | Allowed | Pass |
| R-131 | (collection group) purchases | staff | count every purchase | Denied | Pass |
| R-132 | sharedPrices/reports | user | share own price (hashed id) | Allowed | Pass |
| R-133 | sharedPrices/reports | user | write under bob's id | Denied | Pass |
| R-134 | sharedPrices/reports | staff | share own price (hashed id) | Allowed | Pass |
| R-135 | sharedPrices/reports | staff | write under bob's id | Denied | Pass |
| R-136 | sharedPrices/reports | admin | share own price (hashed id) | Allowed | Pass |
| R-137 | sharedPrices/reports | admin | write under bob's id | Denied | Pass |
| R-138 | sharedPrices/reports | user | add a uid field | Denied | Pass |
| R-139 | sharedPrices/reports | guest | share a price | Denied | Pass |
| R-140 | sharedPrices/reports | guest | read prices | Allowed | Pass |
| R-141 | extensionPairings | user | open a pairing by its id | Allowed | Pass |
| R-142 | extensionPairings | user | list pairings | Denied | Pass |
| R-143 | extensionPairings | staff | open a pairing by its id | Allowed | Pass |
| R-144 | extensionPairings | staff | list pairings | Denied | Pass |
| R-145 | extensionPairings | admin | open a pairing by its id | Allowed | Pass |
| R-146 | extensionPairings | admin | list pairings | Denied | Pass |
| R-147 | extensionPairings | user | approve the pairing for self | Allowed | Pass |
| R-148 | (unmatched path) | admin | write admin_broadcasts (removed, unused) | Denied | Pass |
