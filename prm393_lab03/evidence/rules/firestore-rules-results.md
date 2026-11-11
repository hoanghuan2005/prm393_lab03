# Firestore Security Rules – kết quả chạy trên Emulator

Sinh tự động bởi `firebase/tests/rules.test.mjs` lúc 2026-11-11T00:36:46.274Z.
Tổng: 298 ca · Qua: 298 · Lỗi: 0.
Mỗi vai trò (user, staff, admin) có ít nhất 1 ca cho phép và 1 ca từ chối ở mỗi collection.
Ngoại lệ có chủ đích: `shopeeVouchers|user` chỉ có ca từ chối (vouchers captured by staff; users never read or write them).

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
| R-25 | reports | user | create own | Allowed | Pass |
| R-26 | hiddenMatches | user | create own | Allowed | Pass |
| R-27 | purchases | user | read bob's | Denied | Pass |
| R-28 | wishlistItems | user | read bob's | Denied | Pass |
| R-29 | wishlistItems/priceSnapshots | user | read bob's | Denied | Pass |
| R-30 | extensionSessions | user | read bob's | Denied | Pass |
| R-31 | decisions | user | read bob's | Denied | Pass |
| R-32 | budgetGroups | user | read bob's | Denied | Pass |
| R-33 | feedback | user | read bob's | Denied | Pass |
| R-34 | ownedItems | user | read bob's | Denied | Pass |
| R-35 | budgets | user | read bob's | Denied | Pass |
| R-36 | reflections | user | read bob's | Denied | Pass |
| R-37 | reports | user | read bob's | Denied | Pass |
| R-38 | hiddenMatches | user | read bob's | Denied | Pass |
| R-39 | purchases | staff | create own | Allowed | Pass |
| R-40 | wishlistItems | staff | create own | Allowed | Pass |
| R-41 | wishlistItems/priceSnapshots | staff | create own | Allowed | Pass |
| R-42 | extensionSessions | staff | create own | Allowed | Pass |
| R-43 | decisions | staff | create own | Allowed | Pass |
| R-44 | budgetGroups | staff | create own | Allowed | Pass |
| R-45 | feedback | staff | create own | Allowed | Pass |
| R-46 | ownedItems | staff | create own | Allowed | Pass |
| R-47 | budgets | staff | create own | Allowed | Pass |
| R-48 | reflections | staff | create own | Allowed | Pass |
| R-49 | reports | staff | create own | Allowed | Pass |
| R-50 | hiddenMatches | staff | create own | Allowed | Pass |
| R-51 | purchases | staff | read bob's | Denied | Pass |
| R-52 | wishlistItems | staff | read bob's | Denied | Pass |
| R-53 | wishlistItems/priceSnapshots | staff | read bob's | Denied | Pass |
| R-54 | extensionSessions | staff | read bob's | Denied | Pass |
| R-55 | decisions | staff | read bob's | Denied | Pass |
| R-56 | budgetGroups | staff | read bob's | Denied | Pass |
| R-57 | feedback | staff | read bob's | Denied | Pass |
| R-58 | ownedItems | staff | read bob's | Denied | Pass |
| R-59 | budgets | staff | read bob's | Denied | Pass |
| R-60 | reflections | staff | read bob's | Denied | Pass |
| R-61 | reports | staff | read bob's | Denied | Pass |
| R-62 | hiddenMatches | staff | read bob's | Denied | Pass |
| R-63 | purchases | admin | create own | Allowed | Pass |
| R-64 | wishlistItems | admin | create own | Allowed | Pass |
| R-65 | wishlistItems/priceSnapshots | admin | create own | Allowed | Pass |
| R-66 | extensionSessions | admin | create own | Allowed | Pass |
| R-67 | decisions | admin | create own | Allowed | Pass |
| R-68 | budgetGroups | admin | create own | Allowed | Pass |
| R-69 | feedback | admin | create own | Allowed | Pass |
| R-70 | ownedItems | admin | create own | Allowed | Pass |
| R-71 | budgets | admin | create own | Allowed | Pass |
| R-72 | reflections | admin | create own | Allowed | Pass |
| R-73 | reports | admin | create own | Allowed | Pass |
| R-74 | hiddenMatches | admin | create own | Allowed | Pass |
| R-75 | purchases | admin | read bob's (web user list counts) | Allowed | Pass |
| R-76 | wishlistItems | admin | read bob's (web user list counts) | Allowed | Pass |
| R-77 | wishlistItems/priceSnapshots | admin | read bob's | Denied | Pass |
| R-78 | extensionSessions | admin | read bob's | Denied | Pass |
| R-79 | decisions | admin | read bob's | Denied | Pass |
| R-80 | budgetGroups | admin | read bob's | Denied | Pass |
| R-81 | feedback | admin | read bob's | Denied | Pass |
| R-82 | ownedItems | admin | read bob's | Denied | Pass |
| R-83 | budgets | admin | read bob's | Denied | Pass |
| R-84 | reflections | admin | read bob's | Denied | Pass |
| R-85 | reports | admin | read bob's | Denied | Pass |
| R-86 | hiddenMatches | admin | read bob's | Denied | Pass |
| R-87 | purchases | admin | edit bob's purchase | Denied | Pass |
| R-88 | wishlistItems | admin | delete bob's item | Denied | Pass |
| R-89 | purchases | user | create with amount 0 | Denied | Pass |
| R-90 | wishlistItems | user | status "waiting" (not in the spec) | Denied | Pass |
| R-91 | wishlistItems/priceSnapshots | user | save a priceType 'sale' snapshot | Allowed | Pass |
| R-92 | wishlistItems/priceSnapshots | user | save an unknown priceType 'coupon' | Denied | Pass |
| R-93 | wishlistItems | user | save an item with Shopee ratings | Allowed | Pass |
| R-94 | wishlistItems | user | save productRating 6 | Denied | Pass |
| R-95 | wishlistItems | user | save shopRating 0 | Denied | Pass |
| R-96 | wishlistItems | user | save productRatingCount as text '1,2k' | Denied | Pass |
| R-97 | wishlistItems | user | save productRatingCount -1 | Denied | Pass |
| R-98 | wishlistItems/priceSnapshots | user | save a price with shop name and ratings | Allowed | Pass |
| R-99 | wishlistItems/priceSnapshots | user | save a price with a 61-character shop name | Denied | Pass |
| R-100 | wishlistItems/priceSnapshots | user | save a price with productRating 5.5 | Denied | Pass |
| R-101 | wishlistItems/priceSnapshots | user | save a price with productRatingCount 1.5 | Denied | Pass |
| R-102 | wishlistItems/priceSnapshots | user | edit a recorded price | Denied | Pass |
| R-103 | decisions | user | unknown choice | Denied | Pass |
| R-104 | feedback | user | edit a sent feedback | Denied | Pass |
| R-105 | reflections | user | rating 6 | Denied | Pass |
| R-106 | extensionSessions | user | status "hacked" | Denied | Pass |
| R-107 | inbox | user | read own messages | Allowed | Pass |
| R-108 | inbox | user | mark a message read | Allowed | Pass |
| R-109 | inbox | user | change the text of a message | Denied | Pass |
| R-110 | inbox | user | write a message to self | Denied | Pass |
| R-111 | inbox | user | read bob's messages | Denied | Pass |
| R-112 | inbox | staff | send a message to alice | Allowed | Pass |
| R-113 | inbox | staff | send a message signed as someone else | Denied | Pass |
| R-114 | inbox | staff | read alice's messages | Denied | Pass |
| R-115 | inbox | admin | send a message to bob | Allowed | Pass |
| R-116 | inbox | admin | send a message with an extra field | Denied | Pass |
| R-117 | announcements | user | list published | Allowed | Pass |
| R-118 | announcements | user | list without the status filter | Denied | Pass |
| R-119 | announcements | user | read an archived one | Denied | Pass |
| R-120 | announcements | user | post an announcement | Denied | Pass |
| R-121 | announcements | staff | post an announcement | Allowed | Pass |
| R-122 | announcements | staff | archive a published one | Allowed | Pass |
| R-123 | announcements | staff | republish an archived one | Denied | Pass |
| R-124 | announcements | staff | delete one | Denied | Pass |
| R-125 | announcements | admin | post an announcement | Allowed | Pass |
| R-126 | announcements | admin | post with a 501-character body | Denied | Pass |
| R-127 | announcements | signed out | list published | Denied | Pass |
| R-128 | saleEvents | user | read a published sale | Allowed | Pass |
| R-129 | saleEvents | user | read a draft | Denied | Pass |
| R-130 | saleEvents | user | create a sale | Denied | Pass |
| R-131 | saleEvents | staff | create a draft | Allowed | Pass |
| R-132 | saleEvents | staff | publish a draft | Allowed | Pass |
| R-133 | saleEvents | staff | republish an archived sale | Denied | Pass |
| R-134 | saleEvents | staff | unknown sale type | Denied | Pass |
| R-135 | saleEvents | admin | archive a published sale | Allowed | Pass |
| R-136 | saleEvents | admin | delete a sale | Denied | Pass |
| R-137 | saleSuggestions | user | propose a sale (pending) | Allowed | Pass |
| R-138 | saleSuggestions | user | propose one already approved | Denied | Pass |
| R-139 | saleSuggestions | user | propose in bob's name | Denied | Pass |
| R-140 | saleSuggestions | user | read own suggestion | Allowed | Pass |
| R-141 | saleSuggestions | user | read bob's suggestion | Denied | Pass |
| R-142 | saleSuggestions | user | approve own suggestion | Denied | Pass |
| R-143 | saleSuggestions | staff | approve (event + suggestion + inbox in one batch) | Allowed | Pass |
| R-144 | saleSuggestions | staff | approve the same suggestion again | Denied | Pass |
| R-145 | saleSuggestions | staff | reject without a reason | Denied | Pass |
| R-146 | saleSuggestions | staff | reject with a reason | Allowed | Pass |
| R-147 | saleSuggestions | admin | list the review queue | Allowed | Pass |
| R-148 | saleSuggestions | admin | propose in alice's name | Denied | Pass |
| R-149 | saleSuggestions | admin | reject signed as someone else | Denied | Pass |
| R-150 | (collection group) wishlistItems | admin | count skipped items of every user | Allowed | Pass |
| R-151 | (collection group) wishlistItems | staff | count skipped items of every user | Denied | Pass |
| R-152 | (collection group) wishlistItems | user | count skipped items of every user | Denied | Pass |
| R-153 | (collection group) purchases | admin | count every purchase | Allowed | Pass |
| R-154 | (collection group) purchases | staff | count every purchase | Denied | Pass |
| R-155 | sharedPrices/reports | user | share own price (hashed id) | Allowed | Pass |
| R-156 | sharedPrices/reports | user | write under bob's id | Denied | Pass |
| R-157 | sharedPrices/reports | staff | share own price (hashed id) | Allowed | Pass |
| R-158 | sharedPrices/reports | staff | write under bob's id | Denied | Pass |
| R-159 | sharedPrices/reports | admin | share own price (hashed id) | Allowed | Pass |
| R-160 | sharedPrices/reports | admin | write under bob's id | Denied | Pass |
| R-161 | sharedPrices/reports | user | add a uid field | Denied | Pass |
| R-162 | sharedPrices/reports | guest | share a price | Denied | Pass |
| R-163 | sharedPrices/reports | guest | read prices | Allowed | Pass |
| R-164 | priceHistory | user | read a product | Allowed | Pass |
| R-165 | priceHistory/reports | user | read reports | Allowed | Pass |
| R-166 | productGroups | user | read a group | Allowed | Pass |
| R-167 | priceHistory | staff | read a product | Allowed | Pass |
| R-168 | priceHistory/reports | staff | read reports | Allowed | Pass |
| R-169 | productGroups | staff | read a group | Allowed | Pass |
| R-170 | priceHistory | admin | read a product | Allowed | Pass |
| R-171 | priceHistory/reports | admin | read reports | Allowed | Pass |
| R-172 | productGroups | admin | read a group | Allowed | Pass |
| R-173 | priceHistory | user | create a demo product | Denied | Pass |
| R-174 | priceHistory/reports | user | create a demo report | Denied | Pass |
| R-175 | priceHistory/reports | user | delete a demo report | Denied | Pass |
| R-176 | productGroups | user | create a demo group | Denied | Pass |
| R-177 | priceHistory | staff | create a demo product | Denied | Pass |
| R-178 | priceHistory/reports | staff | create a demo report | Denied | Pass |
| R-179 | priceHistory/reports | staff | delete a demo report | Denied | Pass |
| R-180 | productGroups | staff | create a demo group | Denied | Pass |
| R-181 | priceHistory | admin | create a demo product | Allowed | Pass |
| R-182 | priceHistory | admin | create a demo product with codes | Allowed | Pass |
| R-183 | priceHistory | admin | delete a demo product | Allowed | Pass |
| R-184 | priceHistory | admin | create with a 121-character title | Denied | Pass |
| R-185 | priceHistory | admin | create with a 61-character shop name | Denied | Pass |
| R-186 | priceHistory | admin | create a non-demo product with a device createdAt | Denied | Pass |
| R-187 | priceHistory | admin | shopId/itemId not matching the key | Denied | Pass |
| R-188 | priceHistory/reports | admin | create a demo report | Allowed | Pass |
| R-189 | priceHistory/reports | admin | create priceType 'sale' | Allowed | Pass |
| R-190 | priceHistory/reports | admin | create priceType 'afterVoucher' | Allowed | Pass |
| R-191 | priceHistory/reports | admin | delete a demo report | Allowed | Pass |
| R-192 | priceHistory/reports | admin | productRating 6 | Denied | Pass |
| R-193 | priceHistory/reports | admin | shopRating 0 | Denied | Pass |
| R-194 | priceHistory/reports | admin | productRatingCount -1 | Denied | Pass |
| R-195 | priceHistory/reports | admin | unknown priceType 'coupon' | Denied | Pass |
| R-196 | priceHistory/reports | admin | amountVnd 0 | Denied | Pass |
| R-197 | priceHistory/reports | admin | source 'manual' under a sample id | Denied | Pass |
| R-198 | priceHistory/reports | admin | id not matching modelKey | Denied | Pass |
| R-199 | priceHistory/reports | admin | add a uid field | Denied | Pass |
| R-200 | productGroups | admin | create a demo group | Allowed | Pass |
| R-201 | productGroups | admin | delete a demo group | Allowed | Pass |
| R-202 | productGroups | admin | create a non-demo group | Denied | Pass |
| R-203 | priceHistory/reports | user | report own price (hashed id) | Allowed | Pass |
| R-204 | priceHistory/reports | user | write under bob's id | Denied | Pass |
| R-205 | priceHistory/reports | staff | report own price (hashed id) | Allowed | Pass |
| R-206 | priceHistory/reports | staff | write under bob's id | Denied | Pass |
| R-207 | priceHistory/reports | admin | report own price (hashed id) | Allowed | Pass |
| R-208 | priceHistory/reports | admin | write under bob's id | Denied | Pass |
| R-209 | priceHistory/reports | user | update own report of today | Allowed | Pass |
| R-210 | priceHistory/reports | user | afterVoucher keeps its type | Allowed | Pass |
| R-211 | priceHistory/reports | user | observed 2 days ago (id of that day) | Allowed | Pass |
| R-212 | priceHistory/reports | user | observed 4 days ago | Denied | Pass |
| R-213 | priceHistory/reports | user | id of another day | Denied | Pass |
| R-214 | priceHistory/reports | user | source 'demo' under own id | Denied | Pass |
| R-215 | priceHistory/reports | user | add a uid field | Denied | Pass |
| R-216 | priceHistory/reports | user | delete bob's report | Denied | Pass |
| R-217 | priceHistory/reports | user | real report into a sample product (isDemo) | Denied | Pass |
| R-218 | priceHistory/reports | user | report for a product that does not exist | Denied | Pass |
| R-219 | priceHistory/reports | user | new product + report in one batch | Allowed | Pass |
| R-220 | priceHistory/reports | guest | report own price | Denied | Pass |
| R-221 | priceHistory | user | create a real product | Allowed | Pass |
| R-222 | priceHistory | user | create a real product without a shop name | Allowed | Pass |
| R-223 | priceHistory | user | create a real product with a device createdAt | Denied | Pass |
| R-224 | priceHistory | user | create a product marked as sample | Denied | Pass |
| R-225 | priceHistory | user | change the title of a real product | Denied | Pass |
| R-226 | priceHistory | user | change a shop name already set | Denied | Pass |
| R-227 | priceHistory | user | move a real product to another group | Denied | Pass |
| R-228 | priceHistory | user | change isDemo of a real product | Denied | Pass |
| R-229 | priceHistory | user | fill an empty shop name | Allowed | Pass |
| R-230 | priceHistory | user | fill an empty group | Denied | Pass |
| R-231 | priceHistory | user | create a real product with a group | Denied | Pass |
| R-232 | priceHistory | admin | fill an empty group of a real product | Allowed | Pass |
| R-233 | priceHistory | admin | move a real product to another group | Allowed | Pass |
| R-234 | priceHistory | admin | create a real product with a group | Allowed | Pass |
| R-235 | priceHistory | user | turn a sample product into a real one | Denied | Pass |
| R-236 | priceHistory | user | delete a real product | Denied | Pass |
| R-237 | priceHistory | guest | create a real product | Denied | Pass |
| R-238 | priceHistory | user | set productCode the first time (ai) | Allowed | Pass |
| R-239 | priceHistory | user | set productCode with source 'admin' | Denied | Pass |
| R-240 | priceHistory | user | set productCode without a source | Denied | Pass |
| R-241 | priceHistory | user | change an existing productCode | Denied | Pass |
| R-242 | priceHistory | user | delete an existing productCode | Denied | Pass |
| R-243 | priceHistory | user | add a new variantCodes key | Allowed | Pass |
| R-244 | priceHistory | user | change an existing variantCodes key | Denied | Pass |
| R-245 | priceHistory | user | remove an existing variantCodes key | Denied | Pass |
| R-246 | priceHistory | user | productCode 'K-Sound' (not lowercase) | Denied | Pass |
| R-247 | priceHistory | user | productCode 'ksound--a3' (double dash) | Denied | Pass |
| R-248 | priceHistory | user | productCode of 61 characters | Denied | Pass |
| R-249 | priceHistory | user | variant code 'Đen' | Denied | Pass |
| R-250 | priceHistory | user | variant code of 31 characters | Denied | Pass |
| R-251 | priceHistory | user | variant key 'red' (not a modelKey) | Denied | Pass |
| R-252 | priceHistory | user | create a real product with an ai code | Allowed | Pass |
| R-253 | priceHistory | user | create a real product with an 'admin' code | Denied | Pass |
| R-254 | priceHistory | staff | change an existing productCode | Denied | Pass |
| R-255 | priceHistory | admin | change an existing productCode (source 'admin') | Allowed | Pass |
| R-256 | priceHistory | admin | change a productCode with source 'ai' | Denied | Pass |
| R-257 | priceHistory | admin | change an existing variantCodes key | Allowed | Pass |
| R-258 | priceHistory | admin | change the title of a real product | Denied | Pass |
| R-259 | hiddenMatches | user | hide a match in bob's list | Denied | Pass |
| R-260 | hiddenMatches | user | un-hide own match | Allowed | Pass |
| R-261 | hiddenMatches | user | hide with an extra field | Denied | Pass |
| R-262 | hiddenMatches | user | hide under an id that is not a productKey | Denied | Pass |
| R-263 | hiddenMatches | guest | read alice's hidden matches | Denied | Pass |
| R-264 | priceHistory | signed out | read a product | Denied | Pass |
| R-265 | priceHistory/reports | signed out | read reports | Denied | Pass |
| R-266 | productGroups | signed out | read a group | Denied | Pass |
| R-267 | extensionPairings | user | open a pairing by its id | Allowed | Pass |
| R-268 | extensionPairings | user | list pairings | Denied | Pass |
| R-269 | extensionPairings | staff | open a pairing by its id | Allowed | Pass |
| R-270 | extensionPairings | staff | list pairings | Denied | Pass |
| R-271 | extensionPairings | admin | open a pairing by its id | Allowed | Pass |
| R-272 | extensionPairings | admin | list pairings | Denied | Pass |
| R-273 | extensionPairings | user | approve the pairing for self | Allowed | Pass |
| R-274 | (unmatched path) | admin | write admin_broadcasts (removed, unused) | Denied | Pass |
| R-275 | reports | user | extra field (file name) | Denied | Pass |
| R-276 | reports | user | size 0 kB | Denied | Pass |
| R-277 | reports | user | month "11/2026" | Denied | Pass |
| R-278 | reports | user | createdAt from the client clock | Denied | Pass |
| R-279 | reports | user | edit a saved report | Denied | Pass |
| R-280 | reports | user | delete own (Xoá toàn bộ dữ liệu) | Allowed | Pass |
| R-281 | reports | staff | write into alice's reports | Denied | Pass |
| R-282 | vouchers | user | read | Allowed | Pass |
| R-283 | vouchers | user | write a voucher | Denied | Pass |
| R-284 | vouchers | staff | read | Allowed | Pass |
| R-285 | vouchers | staff | write a voucher | Denied | Pass |
| R-286 | vouchers | admin | read | Allowed | Pass |
| R-287 | vouchers | admin | write a voucher | Denied | Pass |
| R-288 | vouchers | signed out | read | Denied | Pass |
| R-289 | shopeeVouchers | user | read | Denied | Pass |
| R-290 | shopeeVouchers | user | capture a voucher | Denied | Pass |
| R-291 | shopeeVouchers | staff | read | Allowed | Pass |
| R-292 | shopeeVouchers | staff | capture a voucher as self | Allowed | Pass |
| R-293 | shopeeVouchers | staff | capture in the name of another account | Denied | Pass |
| R-294 | shopeeVouchers | admin | read | Allowed | Pass |
| R-295 | shopeeVouchers | admin | source outside shopee.vn | Denied | Pass |
| R-296 | shopeeVouchers | guest | capture without a linked staff account | Denied | Pass |
| R-297 | (collection group) purchases | user | count every purchase | Denied | Pass |
| R-298 | (collection group) purchases | admin | list the documents (not only count) | Allowed | Pass |
