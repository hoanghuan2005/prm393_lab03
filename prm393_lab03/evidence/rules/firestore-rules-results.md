# Firestore Security Rules – kết quả chạy trên Emulator

Sinh tự động bởi `firebase/tests/rules.test.mjs` lúc 2026-11-07T02:18:28.106Z.
Tổng: 267 ca · Qua: 267 · Lỗi: 0.
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
| R-25 | hiddenMatches | user | create own | Allowed | Pass |
| R-26 | purchases | user | read bob's | Denied | Pass |
| R-27 | wishlistItems | user | read bob's | Denied | Pass |
| R-28 | wishlistItems/priceSnapshots | user | read bob's | Denied | Pass |
| R-29 | extensionSessions | user | read bob's | Denied | Pass |
| R-30 | decisions | user | read bob's | Denied | Pass |
| R-31 | budgetGroups | user | read bob's | Denied | Pass |
| R-32 | feedback | user | read bob's | Denied | Pass |
| R-33 | ownedItems | user | read bob's | Denied | Pass |
| R-34 | budgets | user | read bob's | Denied | Pass |
| R-35 | reflections | user | read bob's | Denied | Pass |
| R-36 | hiddenMatches | user | read bob's | Denied | Pass |
| R-37 | purchases | staff | create own | Allowed | Pass |
| R-38 | wishlistItems | staff | create own | Allowed | Pass |
| R-39 | wishlistItems/priceSnapshots | staff | create own | Allowed | Pass |
| R-40 | extensionSessions | staff | create own | Allowed | Pass |
| R-41 | decisions | staff | create own | Allowed | Pass |
| R-42 | budgetGroups | staff | create own | Allowed | Pass |
| R-43 | feedback | staff | create own | Allowed | Pass |
| R-44 | ownedItems | staff | create own | Allowed | Pass |
| R-45 | budgets | staff | create own | Allowed | Pass |
| R-46 | reflections | staff | create own | Allowed | Pass |
| R-47 | hiddenMatches | staff | create own | Allowed | Pass |
| R-48 | purchases | staff | read bob's | Denied | Pass |
| R-49 | wishlistItems | staff | read bob's | Denied | Pass |
| R-50 | wishlistItems/priceSnapshots | staff | read bob's | Denied | Pass |
| R-51 | extensionSessions | staff | read bob's | Denied | Pass |
| R-52 | decisions | staff | read bob's | Denied | Pass |
| R-53 | budgetGroups | staff | read bob's | Denied | Pass |
| R-54 | feedback | staff | read bob's | Denied | Pass |
| R-55 | ownedItems | staff | read bob's | Denied | Pass |
| R-56 | budgets | staff | read bob's | Denied | Pass |
| R-57 | reflections | staff | read bob's | Denied | Pass |
| R-58 | hiddenMatches | staff | read bob's | Denied | Pass |
| R-59 | purchases | admin | create own | Allowed | Pass |
| R-60 | wishlistItems | admin | create own | Allowed | Pass |
| R-61 | wishlistItems/priceSnapshots | admin | create own | Allowed | Pass |
| R-62 | extensionSessions | admin | create own | Allowed | Pass |
| R-63 | decisions | admin | create own | Allowed | Pass |
| R-64 | budgetGroups | admin | create own | Allowed | Pass |
| R-65 | feedback | admin | create own | Allowed | Pass |
| R-66 | ownedItems | admin | create own | Allowed | Pass |
| R-67 | budgets | admin | create own | Allowed | Pass |
| R-68 | reflections | admin | create own | Allowed | Pass |
| R-69 | hiddenMatches | admin | create own | Allowed | Pass |
| R-70 | purchases | admin | read bob's (web user list counts) | Allowed | Pass |
| R-71 | wishlistItems | admin | read bob's (web user list counts) | Allowed | Pass |
| R-72 | wishlistItems/priceSnapshots | admin | read bob's | Denied | Pass |
| R-73 | extensionSessions | admin | read bob's | Denied | Pass |
| R-74 | decisions | admin | read bob's | Denied | Pass |
| R-75 | budgetGroups | admin | read bob's | Denied | Pass |
| R-76 | feedback | admin | read bob's | Denied | Pass |
| R-77 | ownedItems | admin | read bob's | Denied | Pass |
| R-78 | budgets | admin | read bob's | Denied | Pass |
| R-79 | reflections | admin | read bob's | Denied | Pass |
| R-80 | hiddenMatches | admin | read bob's | Denied | Pass |
| R-81 | purchases | admin | edit bob's purchase | Denied | Pass |
| R-82 | wishlistItems | admin | delete bob's item | Denied | Pass |
| R-83 | purchases | user | create with amount 0 | Denied | Pass |
| R-84 | wishlistItems | user | status "waiting" (not in the spec) | Denied | Pass |
| R-85 | wishlistItems/priceSnapshots | user | save a priceType 'sale' snapshot | Allowed | Pass |
| R-86 | wishlistItems/priceSnapshots | user | save an unknown priceType 'coupon' | Denied | Pass |
| R-87 | wishlistItems | user | save an item with Shopee ratings | Allowed | Pass |
| R-88 | wishlistItems | user | save productRating 6 | Denied | Pass |
| R-89 | wishlistItems | user | save shopRating 0 | Denied | Pass |
| R-90 | wishlistItems | user | save productRatingCount as text '1,2k' | Denied | Pass |
| R-91 | wishlistItems | user | save productRatingCount -1 | Denied | Pass |
| R-92 | wishlistItems/priceSnapshots | user | save a price with shop name and ratings | Allowed | Pass |
| R-93 | wishlistItems/priceSnapshots | user | save a price with a 61-character shop name | Denied | Pass |
| R-94 | wishlistItems/priceSnapshots | user | save a price with productRating 5.5 | Denied | Pass |
| R-95 | wishlistItems/priceSnapshots | user | save a price with productRatingCount 1.5 | Denied | Pass |
| R-96 | wishlistItems/priceSnapshots | user | edit a recorded price | Denied | Pass |
| R-97 | decisions | user | unknown choice | Denied | Pass |
| R-98 | feedback | user | edit a sent feedback | Denied | Pass |
| R-99 | reflections | user | rating 6 | Denied | Pass |
| R-100 | extensionSessions | user | status "hacked" | Denied | Pass |
| R-101 | inbox | user | read own messages | Allowed | Pass |
| R-102 | inbox | user | mark a message read | Allowed | Pass |
| R-103 | inbox | user | change the text of a message | Denied | Pass |
| R-104 | inbox | user | write a message to self | Denied | Pass |
| R-105 | inbox | user | read bob's messages | Denied | Pass |
| R-106 | inbox | staff | send a message to alice | Allowed | Pass |
| R-107 | inbox | staff | send a message signed as someone else | Denied | Pass |
| R-108 | inbox | staff | read alice's messages | Denied | Pass |
| R-109 | inbox | admin | send a message to bob | Allowed | Pass |
| R-110 | inbox | admin | send a message with an extra field | Denied | Pass |
| R-111 | announcements | user | list published | Allowed | Pass |
| R-112 | announcements | user | list without the status filter | Denied | Pass |
| R-113 | announcements | user | read an archived one | Denied | Pass |
| R-114 | announcements | user | post an announcement | Denied | Pass |
| R-115 | announcements | staff | post an announcement | Allowed | Pass |
| R-116 | announcements | staff | archive a published one | Allowed | Pass |
| R-117 | announcements | staff | republish an archived one | Denied | Pass |
| R-118 | announcements | staff | delete one | Denied | Pass |
| R-119 | announcements | admin | post an announcement | Allowed | Pass |
| R-120 | announcements | admin | post with a 501-character body | Denied | Pass |
| R-121 | announcements | signed out | list published | Denied | Pass |
| R-122 | saleEvents | user | read a published sale | Allowed | Pass |
| R-123 | saleEvents | user | read a draft | Denied | Pass |
| R-124 | saleEvents | user | create a sale | Denied | Pass |
| R-125 | saleEvents | staff | create a draft | Allowed | Pass |
| R-126 | saleEvents | staff | publish a draft | Allowed | Pass |
| R-127 | saleEvents | staff | republish an archived sale | Denied | Pass |
| R-128 | saleEvents | staff | unknown sale type | Denied | Pass |
| R-129 | saleEvents | admin | archive a published sale | Allowed | Pass |
| R-130 | saleEvents | admin | delete a sale | Denied | Pass |
| R-131 | saleSuggestions | user | propose a sale (pending) | Allowed | Pass |
| R-132 | saleSuggestions | user | propose one already approved | Denied | Pass |
| R-133 | saleSuggestions | user | propose in bob's name | Denied | Pass |
| R-134 | saleSuggestions | user | read own suggestion | Allowed | Pass |
| R-135 | saleSuggestions | user | read bob's suggestion | Denied | Pass |
| R-136 | saleSuggestions | user | approve own suggestion | Denied | Pass |
| R-137 | saleSuggestions | staff | approve (event + suggestion + inbox in one batch) | Allowed | Pass |
| R-138 | saleSuggestions | staff | approve the same suggestion again | Denied | Pass |
| R-139 | saleSuggestions | staff | reject without a reason | Denied | Pass |
| R-140 | saleSuggestions | staff | reject with a reason | Allowed | Pass |
| R-141 | saleSuggestions | admin | list the review queue | Allowed | Pass |
| R-142 | saleSuggestions | admin | propose in alice's name | Denied | Pass |
| R-143 | saleSuggestions | admin | reject signed as someone else | Denied | Pass |
| R-144 | (collection group) wishlistItems | admin | count skipped items of every user | Allowed | Pass |
| R-145 | (collection group) wishlistItems | staff | count skipped items of every user | Denied | Pass |
| R-146 | (collection group) wishlistItems | user | count skipped items of every user | Denied | Pass |
| R-147 | (collection group) purchases | admin | count every purchase | Allowed | Pass |
| R-148 | (collection group) purchases | staff | count every purchase | Denied | Pass |
| R-149 | sharedPrices/reports | user | share own price (hashed id) | Allowed | Pass |
| R-150 | sharedPrices/reports | user | write under bob's id | Denied | Pass |
| R-151 | sharedPrices/reports | staff | share own price (hashed id) | Allowed | Pass |
| R-152 | sharedPrices/reports | staff | write under bob's id | Denied | Pass |
| R-153 | sharedPrices/reports | admin | share own price (hashed id) | Allowed | Pass |
| R-154 | sharedPrices/reports | admin | write under bob's id | Denied | Pass |
| R-155 | sharedPrices/reports | user | add a uid field | Denied | Pass |
| R-156 | sharedPrices/reports | guest | share a price | Denied | Pass |
| R-157 | sharedPrices/reports | guest | read prices | Allowed | Pass |
| R-158 | priceHistory | user | read a product | Allowed | Pass |
| R-159 | priceHistory/reports | user | read reports | Allowed | Pass |
| R-160 | productGroups | user | read a group | Allowed | Pass |
| R-161 | priceHistory | staff | read a product | Allowed | Pass |
| R-162 | priceHistory/reports | staff | read reports | Allowed | Pass |
| R-163 | productGroups | staff | read a group | Allowed | Pass |
| R-164 | priceHistory | admin | read a product | Allowed | Pass |
| R-165 | priceHistory/reports | admin | read reports | Allowed | Pass |
| R-166 | productGroups | admin | read a group | Allowed | Pass |
| R-167 | priceHistory | user | create a demo product | Denied | Pass |
| R-168 | priceHistory/reports | user | create a demo report | Denied | Pass |
| R-169 | priceHistory/reports | user | delete a demo report | Denied | Pass |
| R-170 | productGroups | user | create a demo group | Denied | Pass |
| R-171 | priceHistory | staff | create a demo product | Denied | Pass |
| R-172 | priceHistory/reports | staff | create a demo report | Denied | Pass |
| R-173 | priceHistory/reports | staff | delete a demo report | Denied | Pass |
| R-174 | productGroups | staff | create a demo group | Denied | Pass |
| R-175 | priceHistory | admin | create a demo product | Allowed | Pass |
| R-176 | priceHistory | admin | delete a demo product | Allowed | Pass |
| R-177 | priceHistory | admin | create with a 121-character title | Denied | Pass |
| R-178 | priceHistory | admin | create with a 61-character shop name | Denied | Pass |
| R-179 | priceHistory | admin | create a non-demo product with a device createdAt | Denied | Pass |
| R-180 | priceHistory | admin | shopId/itemId not matching the key | Denied | Pass |
| R-181 | priceHistory/reports | admin | create a demo report | Allowed | Pass |
| R-182 | priceHistory/reports | admin | create priceType 'sale' | Allowed | Pass |
| R-183 | priceHistory/reports | admin | create priceType 'afterVoucher' | Allowed | Pass |
| R-184 | priceHistory/reports | admin | delete a demo report | Allowed | Pass |
| R-185 | priceHistory/reports | admin | productRating 6 | Denied | Pass |
| R-186 | priceHistory/reports | admin | shopRating 0 | Denied | Pass |
| R-187 | priceHistory/reports | admin | productRatingCount -1 | Denied | Pass |
| R-188 | priceHistory/reports | admin | unknown priceType 'coupon' | Denied | Pass |
| R-189 | priceHistory/reports | admin | amountVnd 0 | Denied | Pass |
| R-190 | priceHistory/reports | admin | source 'manual' under a sample id | Denied | Pass |
| R-191 | priceHistory/reports | admin | id not matching modelKey | Denied | Pass |
| R-192 | priceHistory/reports | admin | add a uid field | Denied | Pass |
| R-193 | productGroups | admin | create a demo group | Allowed | Pass |
| R-194 | productGroups | admin | delete a demo group | Allowed | Pass |
| R-195 | productGroups | admin | create a non-demo group | Denied | Pass |
| R-196 | priceHistory/reports | user | report own price (hashed id) | Allowed | Pass |
| R-197 | priceHistory/reports | user | write under bob's id | Denied | Pass |
| R-198 | priceHistory/reports | staff | report own price (hashed id) | Allowed | Pass |
| R-199 | priceHistory/reports | staff | write under bob's id | Denied | Pass |
| R-200 | priceHistory/reports | admin | report own price (hashed id) | Allowed | Pass |
| R-201 | priceHistory/reports | admin | write under bob's id | Denied | Pass |
| R-202 | priceHistory/reports | user | update own report of today | Allowed | Pass |
| R-203 | priceHistory/reports | user | afterVoucher keeps its type | Allowed | Pass |
| R-204 | priceHistory/reports | user | observed 2 days ago (id of that day) | Allowed | Pass |
| R-205 | priceHistory/reports | user | observed 4 days ago | Denied | Pass |
| R-206 | priceHistory/reports | user | id of another day | Denied | Pass |
| R-207 | priceHistory/reports | user | source 'demo' under own id | Denied | Pass |
| R-208 | priceHistory/reports | user | add a uid field | Denied | Pass |
| R-209 | priceHistory/reports | user | delete bob's report | Denied | Pass |
| R-210 | priceHistory/reports | user | real report into a sample product (isDemo) | Denied | Pass |
| R-211 | priceHistory/reports | user | report for a product that does not exist | Denied | Pass |
| R-212 | priceHistory/reports | user | new product + report in one batch | Allowed | Pass |
| R-213 | priceHistory/reports | guest | report own price | Denied | Pass |
| R-214 | priceHistory | user | create a real product | Allowed | Pass |
| R-215 | priceHistory | user | create a real product without a shop name | Allowed | Pass |
| R-216 | priceHistory | user | create a real product with a device createdAt | Denied | Pass |
| R-217 | priceHistory | user | create a product marked as sample | Denied | Pass |
| R-218 | priceHistory | user | change the title of a real product | Denied | Pass |
| R-219 | priceHistory | user | change a shop name already set | Denied | Pass |
| R-220 | priceHistory | user | move a real product to another group | Denied | Pass |
| R-221 | priceHistory | user | change isDemo of a real product | Denied | Pass |
| R-222 | priceHistory | user | fill an empty shop name | Allowed | Pass |
| R-223 | priceHistory | user | fill an empty group | Denied | Pass |
| R-224 | priceHistory | user | create a real product with a group | Denied | Pass |
| R-225 | priceHistory | admin | fill an empty group of a real product | Allowed | Pass |
| R-226 | priceHistory | admin | move a real product to another group | Allowed | Pass |
| R-227 | priceHistory | admin | create a real product with a group | Allowed | Pass |
| R-228 | priceHistory | user | turn a sample product into a real one | Denied | Pass |
| R-229 | priceHistory | user | delete a real product | Denied | Pass |
| R-230 | priceHistory | guest | create a real product | Denied | Pass |
| R-231 | priceHistory | user | set productCode the first time (ai) | Allowed | Pass |
| R-232 | priceHistory | user | set productCode with source 'admin' | Denied | Pass |
| R-233 | priceHistory | user | set productCode without a source | Denied | Pass |
| R-234 | priceHistory | user | change an existing productCode | Denied | Pass |
| R-235 | priceHistory | user | delete an existing productCode | Denied | Pass |
| R-236 | priceHistory | user | add a new variantCodes key | Allowed | Pass |
| R-237 | priceHistory | user | change an existing variantCodes key | Denied | Pass |
| R-238 | priceHistory | user | remove an existing variantCodes key | Denied | Pass |
| R-239 | priceHistory | user | productCode 'K-Sound' (not lowercase) | Denied | Pass |
| R-240 | priceHistory | user | productCode 'ksound--a3' (double dash) | Denied | Pass |
| R-241 | priceHistory | user | productCode of 61 characters | Denied | Pass |
| R-242 | priceHistory | user | variant code 'Đen' | Denied | Pass |
| R-243 | priceHistory | user | variant code of 31 characters | Denied | Pass |
| R-244 | priceHistory | user | variant key 'red' (not a modelKey) | Denied | Pass |
| R-245 | priceHistory | user | create a real product with an ai code | Allowed | Pass |
| R-246 | priceHistory | user | create a real product with an 'admin' code | Denied | Pass |
| R-247 | priceHistory | staff | change an existing productCode | Denied | Pass |
| R-248 | priceHistory | admin | change an existing productCode (source 'admin') | Allowed | Pass |
| R-249 | priceHistory | admin | change a productCode with source 'ai' | Denied | Pass |
| R-250 | priceHistory | admin | change an existing variantCodes key | Allowed | Pass |
| R-251 | priceHistory | admin | change the title of a real product | Denied | Pass |
| R-252 | hiddenMatches | user | hide a match in bob's list | Denied | Pass |
| R-253 | hiddenMatches | user | un-hide own match | Allowed | Pass |
| R-254 | hiddenMatches | user | hide with an extra field | Denied | Pass |
| R-255 | hiddenMatches | user | hide under an id that is not a productKey | Denied | Pass |
| R-256 | hiddenMatches | guest | read alice's hidden matches | Denied | Pass |
| R-257 | priceHistory | signed out | read a product | Denied | Pass |
| R-258 | priceHistory/reports | signed out | read reports | Denied | Pass |
| R-259 | productGroups | signed out | read a group | Denied | Pass |
| R-260 | extensionPairings | user | open a pairing by its id | Allowed | Pass |
| R-261 | extensionPairings | user | list pairings | Denied | Pass |
| R-262 | extensionPairings | staff | open a pairing by its id | Allowed | Pass |
| R-263 | extensionPairings | staff | list pairings | Denied | Pass |
| R-264 | extensionPairings | admin | open a pairing by its id | Allowed | Pass |
| R-265 | extensionPairings | admin | list pairings | Denied | Pass |
| R-266 | extensionPairings | user | approve the pairing for self | Allowed | Pass |
| R-267 | (unmatched path) | admin | write admin_broadcasts (removed, unused) | Denied | Pass |
