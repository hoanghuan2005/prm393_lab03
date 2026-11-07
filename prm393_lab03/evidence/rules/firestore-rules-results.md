# Firestore Security Rules – kết quả chạy trên Emulator

Sinh tự động bởi `firebase/tests/rules.test.mjs` lúc 2026-11-06T18:45:33.590Z.
Tổng: 231 ca · Qua: 231 · Lỗi: 0.
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
| R-79 | wishlistItems/priceSnapshots | user | save a priceType 'sale' snapshot | Allowed | Pass |
| R-80 | wishlistItems/priceSnapshots | user | save an unknown priceType 'coupon' | Denied | Pass |
| R-81 | wishlistItems | user | save an item with Shopee ratings | Allowed | Pass |
| R-82 | wishlistItems | user | save productRating 6 | Denied | Pass |
| R-83 | wishlistItems | user | save shopRating 0 | Denied | Pass |
| R-84 | wishlistItems | user | save productRatingCount as text '1,2k' | Denied | Pass |
| R-85 | wishlistItems | user | save productRatingCount -1 | Denied | Pass |
| R-86 | wishlistItems/priceSnapshots | user | save a price with shop name and ratings | Allowed | Pass |
| R-87 | wishlistItems/priceSnapshots | user | save a price with a 61-character shop name | Denied | Pass |
| R-88 | wishlistItems/priceSnapshots | user | save a price with productRating 5.5 | Denied | Pass |
| R-89 | wishlistItems/priceSnapshots | user | save a price with productRatingCount 1.5 | Denied | Pass |
| R-90 | wishlistItems/priceSnapshots | user | edit a recorded price | Denied | Pass |
| R-91 | decisions | user | unknown choice | Denied | Pass |
| R-92 | feedback | user | edit a sent feedback | Denied | Pass |
| R-93 | reflections | user | rating 6 | Denied | Pass |
| R-94 | extensionSessions | user | status "hacked" | Denied | Pass |
| R-95 | inbox | user | read own messages | Allowed | Pass |
| R-96 | inbox | user | mark a message read | Allowed | Pass |
| R-97 | inbox | user | change the text of a message | Denied | Pass |
| R-98 | inbox | user | write a message to self | Denied | Pass |
| R-99 | inbox | user | read bob's messages | Denied | Pass |
| R-100 | inbox | staff | send a message to alice | Allowed | Pass |
| R-101 | inbox | staff | send a message signed as someone else | Denied | Pass |
| R-102 | inbox | staff | read alice's messages | Denied | Pass |
| R-103 | inbox | admin | send a message to bob | Allowed | Pass |
| R-104 | inbox | admin | send a message with an extra field | Denied | Pass |
| R-105 | announcements | user | list published | Allowed | Pass |
| R-106 | announcements | user | list without the status filter | Denied | Pass |
| R-107 | announcements | user | read an archived one | Denied | Pass |
| R-108 | announcements | user | post an announcement | Denied | Pass |
| R-109 | announcements | staff | post an announcement | Allowed | Pass |
| R-110 | announcements | staff | archive a published one | Allowed | Pass |
| R-111 | announcements | staff | republish an archived one | Denied | Pass |
| R-112 | announcements | staff | delete one | Denied | Pass |
| R-113 | announcements | admin | post an announcement | Allowed | Pass |
| R-114 | announcements | admin | post with a 501-character body | Denied | Pass |
| R-115 | announcements | signed out | list published | Denied | Pass |
| R-116 | saleEvents | user | read a published sale | Allowed | Pass |
| R-117 | saleEvents | user | read a draft | Denied | Pass |
| R-118 | saleEvents | user | create a sale | Denied | Pass |
| R-119 | saleEvents | staff | create a draft | Allowed | Pass |
| R-120 | saleEvents | staff | publish a draft | Allowed | Pass |
| R-121 | saleEvents | staff | republish an archived sale | Denied | Pass |
| R-122 | saleEvents | staff | unknown sale type | Denied | Pass |
| R-123 | saleEvents | admin | archive a published sale | Allowed | Pass |
| R-124 | saleEvents | admin | delete a sale | Denied | Pass |
| R-125 | saleSuggestions | user | propose a sale (pending) | Allowed | Pass |
| R-126 | saleSuggestions | user | propose one already approved | Denied | Pass |
| R-127 | saleSuggestions | user | propose in bob's name | Denied | Pass |
| R-128 | saleSuggestions | user | read own suggestion | Allowed | Pass |
| R-129 | saleSuggestions | user | read bob's suggestion | Denied | Pass |
| R-130 | saleSuggestions | user | approve own suggestion | Denied | Pass |
| R-131 | saleSuggestions | staff | approve (event + suggestion + inbox in one batch) | Allowed | Pass |
| R-132 | saleSuggestions | staff | approve the same suggestion again | Denied | Pass |
| R-133 | saleSuggestions | staff | reject without a reason | Denied | Pass |
| R-134 | saleSuggestions | staff | reject with a reason | Allowed | Pass |
| R-135 | saleSuggestions | admin | list the review queue | Allowed | Pass |
| R-136 | saleSuggestions | admin | propose in alice's name | Denied | Pass |
| R-137 | saleSuggestions | admin | reject signed as someone else | Denied | Pass |
| R-138 | (collection group) wishlistItems | admin | count skipped items of every user | Allowed | Pass |
| R-139 | (collection group) wishlistItems | staff | count skipped items of every user | Denied | Pass |
| R-140 | (collection group) wishlistItems | user | count skipped items of every user | Denied | Pass |
| R-141 | (collection group) purchases | admin | count every purchase | Allowed | Pass |
| R-142 | (collection group) purchases | staff | count every purchase | Denied | Pass |
| R-143 | sharedPrices/reports | user | share own price (hashed id) | Allowed | Pass |
| R-144 | sharedPrices/reports | user | write under bob's id | Denied | Pass |
| R-145 | sharedPrices/reports | staff | share own price (hashed id) | Allowed | Pass |
| R-146 | sharedPrices/reports | staff | write under bob's id | Denied | Pass |
| R-147 | sharedPrices/reports | admin | share own price (hashed id) | Allowed | Pass |
| R-148 | sharedPrices/reports | admin | write under bob's id | Denied | Pass |
| R-149 | sharedPrices/reports | user | add a uid field | Denied | Pass |
| R-150 | sharedPrices/reports | guest | share a price | Denied | Pass |
| R-151 | sharedPrices/reports | guest | read prices | Allowed | Pass |
| R-152 | priceHistory | user | read a product | Allowed | Pass |
| R-153 | priceHistory/reports | user | read reports | Allowed | Pass |
| R-154 | productGroups | user | read a group | Allowed | Pass |
| R-155 | priceHistory | staff | read a product | Allowed | Pass |
| R-156 | priceHistory/reports | staff | read reports | Allowed | Pass |
| R-157 | productGroups | staff | read a group | Allowed | Pass |
| R-158 | priceHistory | admin | read a product | Allowed | Pass |
| R-159 | priceHistory/reports | admin | read reports | Allowed | Pass |
| R-160 | productGroups | admin | read a group | Allowed | Pass |
| R-161 | priceHistory | user | create a demo product | Denied | Pass |
| R-162 | priceHistory/reports | user | create a demo report | Denied | Pass |
| R-163 | priceHistory/reports | user | delete a demo report | Denied | Pass |
| R-164 | productGroups | user | create a demo group | Denied | Pass |
| R-165 | priceHistory | staff | create a demo product | Denied | Pass |
| R-166 | priceHistory/reports | staff | create a demo report | Denied | Pass |
| R-167 | priceHistory/reports | staff | delete a demo report | Denied | Pass |
| R-168 | productGroups | staff | create a demo group | Denied | Pass |
| R-169 | priceHistory | admin | create a demo product | Allowed | Pass |
| R-170 | priceHistory | admin | delete a demo product | Allowed | Pass |
| R-171 | priceHistory | admin | create with a 121-character title | Denied | Pass |
| R-172 | priceHistory | admin | create with a 61-character shop name | Denied | Pass |
| R-173 | priceHistory | admin | create a non-demo product with a device createdAt | Denied | Pass |
| R-174 | priceHistory | admin | shopId/itemId not matching the key | Denied | Pass |
| R-175 | priceHistory/reports | admin | create a demo report | Allowed | Pass |
| R-176 | priceHistory/reports | admin | create priceType 'sale' | Allowed | Pass |
| R-177 | priceHistory/reports | admin | create priceType 'afterVoucher' | Allowed | Pass |
| R-178 | priceHistory/reports | admin | delete a demo report | Allowed | Pass |
| R-179 | priceHistory/reports | admin | productRating 6 | Denied | Pass |
| R-180 | priceHistory/reports | admin | shopRating 0 | Denied | Pass |
| R-181 | priceHistory/reports | admin | productRatingCount -1 | Denied | Pass |
| R-182 | priceHistory/reports | admin | unknown priceType 'coupon' | Denied | Pass |
| R-183 | priceHistory/reports | admin | amountVnd 0 | Denied | Pass |
| R-184 | priceHistory/reports | admin | source 'manual' under a sample id | Denied | Pass |
| R-185 | priceHistory/reports | admin | id not matching modelKey | Denied | Pass |
| R-186 | priceHistory/reports | admin | add a uid field | Denied | Pass |
| R-187 | productGroups | admin | create a demo group | Allowed | Pass |
| R-188 | productGroups | admin | delete a demo group | Allowed | Pass |
| R-189 | productGroups | admin | create a non-demo group | Denied | Pass |
| R-190 | priceHistory/reports | user | report own price (hashed id) | Allowed | Pass |
| R-191 | priceHistory/reports | user | write under bob's id | Denied | Pass |
| R-192 | priceHistory/reports | staff | report own price (hashed id) | Allowed | Pass |
| R-193 | priceHistory/reports | staff | write under bob's id | Denied | Pass |
| R-194 | priceHistory/reports | admin | report own price (hashed id) | Allowed | Pass |
| R-195 | priceHistory/reports | admin | write under bob's id | Denied | Pass |
| R-196 | priceHistory/reports | user | update own report of today | Allowed | Pass |
| R-197 | priceHistory/reports | user | afterVoucher keeps its type | Allowed | Pass |
| R-198 | priceHistory/reports | user | observed 2 days ago (id of that day) | Allowed | Pass |
| R-199 | priceHistory/reports | user | observed 4 days ago | Denied | Pass |
| R-200 | priceHistory/reports | user | id of another day | Denied | Pass |
| R-201 | priceHistory/reports | user | source 'demo' under own id | Denied | Pass |
| R-202 | priceHistory/reports | user | add a uid field | Denied | Pass |
| R-203 | priceHistory/reports | user | delete bob's report | Denied | Pass |
| R-204 | priceHistory/reports | user | real report into a sample product (isDemo) | Denied | Pass |
| R-205 | priceHistory/reports | user | report for a product that does not exist | Denied | Pass |
| R-206 | priceHistory/reports | user | new product + report in one batch | Allowed | Pass |
| R-207 | priceHistory/reports | guest | report own price | Denied | Pass |
| R-208 | priceHistory | user | create a real product | Allowed | Pass |
| R-209 | priceHistory | user | create a real product without a shop name | Allowed | Pass |
| R-210 | priceHistory | user | create a real product with a device createdAt | Denied | Pass |
| R-211 | priceHistory | user | create a product marked as sample | Denied | Pass |
| R-212 | priceHistory | user | change the title of a real product | Denied | Pass |
| R-213 | priceHistory | user | change a shop name already set | Denied | Pass |
| R-214 | priceHistory | user | move a real product to another group | Denied | Pass |
| R-215 | priceHistory | user | change isDemo of a real product | Denied | Pass |
| R-216 | priceHistory | user | fill an empty shop name | Allowed | Pass |
| R-217 | priceHistory | user | fill an empty group | Allowed | Pass |
| R-218 | priceHistory | user | turn a sample product into a real one | Denied | Pass |
| R-219 | priceHistory | user | delete a real product | Denied | Pass |
| R-220 | priceHistory | guest | create a real product | Denied | Pass |
| R-221 | priceHistory | signed out | read a product | Denied | Pass |
| R-222 | priceHistory/reports | signed out | read reports | Denied | Pass |
| R-223 | productGroups | signed out | read a group | Denied | Pass |
| R-224 | extensionPairings | user | open a pairing by its id | Allowed | Pass |
| R-225 | extensionPairings | user | list pairings | Denied | Pass |
| R-226 | extensionPairings | staff | open a pairing by its id | Allowed | Pass |
| R-227 | extensionPairings | staff | list pairings | Denied | Pass |
| R-228 | extensionPairings | admin | open a pairing by its id | Allowed | Pass |
| R-229 | extensionPairings | admin | list pairings | Denied | Pass |
| R-230 | extensionPairings | user | approve the pairing for self | Allowed | Pass |
| R-231 | (unmatched path) | admin | write admin_broadcasts (removed, unused) | Denied | Pass |
